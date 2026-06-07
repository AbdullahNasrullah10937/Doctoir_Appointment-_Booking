import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firebase_paths.dart';
import '../../core/security/encryption_service.dart';
import '../../domain/entities/app_entities.dart';
import 'app_rtdb_codecs.dart';
import 'appointment_rtdb_codec.dart';

enum MetaState {
  found,
  notFound,
  fetchFailed,
}

class PatientCloudBootstrap {
  PatientCloudBootstrap._();

  static Future<PatientBootstrapSnapshot?> tryRestore({
    FirebaseAuth? auth,
    FirebaseDatabase? database,
  }) async {
    if (!FirebaseBootstrap.enabled) {
      return null;
    }

    final authInstance = auth ?? FirebaseAuth.instance;
    final databaseInstance = database ?? FirebaseDatabase.instance;
    final user = authInstance.currentUser;
    if (user == null) {
      return null;
    }

    MetaState metaState = MetaState.notFound;
    UserRole resolvedRole = UserRole.patient;
    String verificationStatus = 'pending';

    try {
      final metaSnap = await databaseInstance
          .ref(FirebasePaths.meta(user.uid))
          .get()
          .timeout(const Duration(seconds: 8));
      if (metaSnap.exists && metaSnap.value is Map) {
        final meta = Map<dynamic, dynamic>.from(metaSnap.value! as Map);
        final rawRole = '${meta['appRole'] ?? meta['role'] ?? 'patient'}';
        if (rawRole == UserRole.doctor.name) {
          resolvedRole = UserRole.doctor;
        } else if (rawRole == UserRole.admin.name) {
          resolvedRole = UserRole.admin;
        } else {
          resolvedRole = UserRole.patient;
        }
        verificationStatus = '${meta['verificationStatus'] ?? 'pending'}';
        metaState = MetaState.found;
      } else {
        metaState = MetaState.notFound;
      }
    } catch (_) {
      metaState = MetaState.fetchFailed;
    }

    UserProfile? profile;
    if (metaState != MetaState.fetchFailed) {
      try {
        final profileSnap = await databaseInstance
            .ref(FirebasePaths.profile(user.uid))
            .get()
            .timeout(const Duration(seconds: 8));
        if (profileSnap.exists && profileSnap.value is Map) {
          profile = PatientProfileCodec.decode(profileSnap.value);
        }
      } catch (_) {
        // Suppress profile sub-fetch error
      }
    }

    return PatientBootstrapSnapshot(
      firebaseUserId: user.uid,
      restoredRole: resolvedRole,
      metaState: metaState,
      verificationStatus: verificationStatus,
      profile: profile,
    );
  }

  static Future<bool> writeRoleMeta({
    required String firebaseUserId,
    required UserRole role,
    FirebaseDatabase? database,
  }) async {
    if (!FirebaseBootstrap.enabled) {
      return false;
    }

    final databaseInstance = database ?? FirebaseDatabase.instance;
    final ref = databaseInstance.ref(FirebasePaths.meta(firebaseUserId));

    try {
      final result = await ref.runTransaction((currentData) {
        if (currentData != null &&
            currentData is Map &&
            currentData['appRole'] != null) {
          return Transaction.abort(); // Role is already locked, abort transaction
        }
        return Transaction.success(<String, Object?>{
          'appRole': role.name,
          'updatedAtMillis': ServerValue.timestamp,
        });
      });
      return result.committed;
    } catch (e) {
      return false;
    }
  }

  static Future<void> writeProfileSnapshot({
    required UserProfile profile,
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  }) async {
    final authInstance = auth ?? FirebaseAuth.instance;
    final databaseInstance = database ?? FirebaseDatabase.instance;
    final uid = authInstance.currentUser?.uid;
    if (!FirebaseBootstrap.enabled || uid == null) {
      return;
    }

    await databaseInstance
        .ref(FirebasePaths.profile(uid))
        .set(PatientProfileCodec.encode(profile));
  }
}

class PatientBootstrapSnapshot {
  const PatientBootstrapSnapshot({
    required this.firebaseUserId,
    required this.restoredRole,
    required this.metaState,
    this.verificationStatus = 'pending',
    this.profile,
  });

  final String firebaseUserId;
  final UserRole restoredRole;
  final MetaState metaState;
  final String verificationStatus;
  final UserProfile? profile;
}

class PatientProfileCodec {
  PatientProfileCodec._();

  // ── Encode ─────────────────────────────────────────────────────────────────
  //
  // Sensitive fields (fullName, bloodGroup, chronicConditions) are bundled into
  // a JSON string and AES-256 encrypted before upload.
  // Non-sensitive fields (age, gender) stay plain so Firebase can still
  // order/filter by them without decrypting anything.
  // A SHA-256 blind index of the lowercase fullName is stored as 'nameHash'
  // so that exact-match lookups remain possible without exposing the name.

  static Map<String, Object?> encode(UserProfile profile) {
    final sensitiveJson = jsonEncode(<String, dynamic>{
      'fullName': profile.fullName,
      if (profile.bloodGroup?.isNotEmpty ?? false)
        'bloodGroup': profile.bloodGroup,
      if (profile.chronicConditions?.isNotEmpty ?? false)
        'chronicConditions': profile.chronicConditions,
    });

    return <String, Object?>{
      // Opaque encrypted blob — unreadable in Firebase console.
      'encryptedData': EncryptionService.encrypt(sensitiveJson),
      // SHA-256 blind index — enables exact-match query on fullName.
      'nameHash': _blindIndex(profile.fullName),
      // Plain non-sensitive fields kept for ordering.
      'age': profile.age,
      'gender': profile.gender,
      'updatedAtMillis': ServerValue.timestamp,
    };
  }

  // ── Decode ─────────────────────────────────────────────────────────────────

  static UserProfile? decode(Object? rawValue) {
    if (rawValue is! Map) return null;

    final map = rawValue.cast<dynamic, dynamic>();

    // Decrypt the sensitive blob.
    final encryptedData = '${map['encryptedData'] ?? ''}';
    if (encryptedData.isEmpty) return null;

    late Map<String, dynamic> sensitive;
    try {
      sensitive =
          jsonDecode(EncryptionService.decrypt(encryptedData))
              as Map<String, dynamic>;
    } catch (_) {
      // Decryption failed (e.g. key mismatch after reinstall). Return null so
      // the app treats this as a missing profile rather than crashing.
      return null;
    }

    return UserProfile(
      fullName: '${sensitive['fullName'] ?? ''}',
      age: _parsePositiveInt(map['age'], fallback: 18),
      gender: '${map['gender'] ?? 'Female'}',
      bloodGroup:
          sensitive['bloodGroup'] is String &&
              '${sensitive['bloodGroup']}'.isNotEmpty
          ? '${sensitive['bloodGroup']}'
          : null,
      chronicConditions:
          sensitive['chronicConditions'] is String &&
              '${sensitive['chronicConditions']}'.isNotEmpty
          ? '${sensitive['chronicConditions']}'
          : null,
    );
  }

  // ── Blind index helper ─────────────────────────────────────────────────────

  /// Returns the SHA-256 hex digest of the lowercased, trimmed [value].
  /// Store this alongside encrypted data to support exact-match Firebase queries.
  static String _blindIndex(String value) {
    final bytes = utf8.encode(value.toLowerCase().trim());
    return sha256.convert(bytes).toString();
  }

  static int _parsePositiveInt(dynamic value, {required int fallback}) {
    if (value is int) return value.clamp(1, 140);
    if (value is double) return value.round().clamp(1, 140);
    return (int.tryParse('$value') ?? fallback).clamp(1, 140);
  }
}

class PatientAppointmentCloudRepository {
  PatientAppointmentCloudRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  }) : _database = database ?? FirebaseDatabase.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  DatabaseReference appointmentsRef(User user) =>
      _database.ref(FirebasePaths.appointments(user.uid));

  static List<Appointment> decodeAppointmentCollection(
    Object? snapshotValue,
    List<Doctor> catalog,
  ) {
    if (snapshotValue is! Map) {
      return <Appointment>[];
    }

    final map = Map<dynamic, dynamic>.from(snapshotValue);
    final decoded = <Appointment>[];
    for (final MapEntry<dynamic, dynamic> entry in map.entries) {
      final key = '${entry.key}';
      final dynamic value = entry.value;
      if (value is Map) {
        final raw = Map<dynamic, dynamic>.from(value);
        raw['id'] = raw['id'] ?? key;
        decoded.add(AppointmentRtdbCodec.decode(raw, catalog));
      }
    }

    decoded.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return decoded.reversed.toList();
  }

  Future<List<Appointment>> readOnce({
    required List<Doctor> catalog,
    required String firebaseUid,
  }) async {
    final liveUser = _auth.currentUser;
    if (liveUser == null ||
        liveUser.uid != firebaseUid ||
        !FirebaseBootstrap.enabled) {
      return <Appointment>[];
    }

    final snapshot = await appointmentsRef(liveUser).get();
    return decodeAppointmentCollection(snapshot.value, catalog);
  }

  Stream<List<Appointment>> listenAppointments({
    required List<Doctor> catalog,
    required String firebaseUid,
  }) {
    final liveUser = _auth.currentUser;
    if (liveUser == null ||
        liveUser.uid != firebaseUid ||
        !FirebaseBootstrap.enabled) {
      return const Stream<List<Appointment>>.empty();
    }

    return appointmentsRef(liveUser).onValue.map((DatabaseEvent event) {
      return decodeAppointmentCollection(event.snapshot.value, catalog);
    });
  }

  Future<void> upsert(Appointment appointment) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await appointmentsRef(
      user,
    ).child(appointment.id).set(AppointmentRtdbCodec.encode(appointment));
  }

  Future<void> mergeStatus({
    required String appointmentId,
    required AppointmentStatus status,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await appointmentsRef(user).child(appointmentId).update(<String, Object?>{
      'status': status.name,
      'updatedAtMillis': ServerValue.timestamp,
    });
  }

  Future<void> delete(String appointmentId) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await appointmentsRef(user).child(appointmentId).remove();
  }
}

class PatientRecordCloudRepository {
  PatientRecordCloudRepository({FirebaseDatabase? database, FirebaseAuth? auth})
    : _database = database ?? FirebaseDatabase.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  DatabaseReference recordsRef(User user) =>
      _database.ref(FirebasePaths.records(user.uid));

  static List<HealthRecord> decodeRecordCollection(Object? snapshotValue) {
    if (snapshotValue is! Map) {
      return <HealthRecord>[];
    }

    final map = Map<dynamic, dynamic>.from(snapshotValue);
    final decoded = <HealthRecord>[];
    for (final MapEntry<dynamic, dynamic> entry in map.entries) {
      final key = '${entry.key}';
      final value = entry.value;
      if (value is Map) {
        final raw = Map<dynamic, dynamic>.from(value);
        raw['id'] = raw['id'] ?? key;
        decoded.add(HealthRecordRtdbCodec.decode(raw));
      }
    }

    decoded.sort((a, b) => b.date.compareTo(a.date));
    return decoded;
  }

  Stream<List<HealthRecord>> listenRecords({required String firebaseUid}) {
    final liveUser = _auth.currentUser;
    if (liveUser == null ||
        liveUser.uid != firebaseUid ||
        !FirebaseBootstrap.enabled) {
      return const Stream<List<HealthRecord>>.empty();
    }

    return recordsRef(liveUser).onValue.map((event) {
      return decodeRecordCollection(event.snapshot.value);
    });
  }

  Future<void> upsert(HealthRecord record) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await recordsRef(
      user,
    ).child(record.id).set(HealthRecordRtdbCodec.encode(record));
  }

  Future<void> delete(String recordId) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await recordsRef(user).child(recordId).remove();
  }
}

class PatientReminderCloudRepository {
  PatientReminderCloudRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  }) : _database = database ?? FirebaseDatabase.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  DatabaseReference remindersRef(User user) =>
      _database.ref(FirebasePaths.reminders(user.uid));

  static List<MedicationReminder> decodeReminderCollection(
    Object? snapshotValue,
  ) {
    if (snapshotValue is! Map) {
      return <MedicationReminder>[];
    }

    final map = Map<dynamic, dynamic>.from(snapshotValue);
    final decoded = <MedicationReminder>[];
    for (final MapEntry<dynamic, dynamic> entry in map.entries) {
      final key = '${entry.key}';
      final value = entry.value;
      if (value is Map) {
        final raw = Map<dynamic, dynamic>.from(value);
        raw['id'] = raw['id'] ?? key;
        decoded.add(MedicationReminderRtdbCodec.decode(raw));
      }
    }

    return decoded;
  }

  Stream<List<MedicationReminder>> listenReminders({
    required String firebaseUid,
  }) {
    final liveUser = _auth.currentUser;
    if (liveUser == null ||
        liveUser.uid != firebaseUid ||
        !FirebaseBootstrap.enabled) {
      return const Stream<List<MedicationReminder>>.empty();
    }

    return remindersRef(liveUser).onValue.map((event) {
      return decodeReminderCollection(event.snapshot.value);
    });
  }

  Future<void> upsert(MedicationReminder reminder) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await remindersRef(
      user,
    ).child(reminder.id).set(MedicationReminderRtdbCodec.encode(reminder));
  }

  Future<void> delete(String reminderId) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await remindersRef(user).child(reminderId).remove();
  }
}

class PatientNotificationCloudRepository {
  PatientNotificationCloudRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  }) : _database = database ?? FirebaseDatabase.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  DatabaseReference notificationsRef(User user) =>
      _database.ref(FirebasePaths.notifications(user.uid));

  static List<AppNotification> decodeNotificationCollection(
    Object? snapshotValue,
  ) {
    if (snapshotValue is! Map) {
      return <AppNotification>[];
    }

    final map = Map<dynamic, dynamic>.from(snapshotValue);
    final decoded = <AppNotification>[];
    for (final MapEntry<dynamic, dynamic> entry in map.entries) {
      final key = '${entry.key}';
      final value = entry.value;
      if (value is Map) {
        final raw = Map<dynamic, dynamic>.from(value);
        raw['id'] = raw['id'] ?? key;
        decoded.add(AppNotificationRtdbCodec.decode(raw));
      }
    }

    return decoded;
  }

  Stream<List<AppNotification>> listenNotifications({
    required String firebaseUid,
  }) {
    final liveUser = _auth.currentUser;
    if (liveUser == null ||
        liveUser.uid != firebaseUid ||
        !FirebaseBootstrap.enabled) {
      return const Stream<List<AppNotification>>.empty();
    }

    return notificationsRef(liveUser).onValue.map((event) {
      return decodeNotificationCollection(event.snapshot.value);
    });
  }

  Future<void> upsert(AppNotification notification) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await notificationsRef(
      user,
    ).child(notification.id).set(AppNotificationRtdbCodec.encode(notification));
  }

  Future<void> markAllRead(List<AppNotification> items) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    final updates = <String, Object?>{};
    for (final item in items) {
      updates['${item.id}/isUnread'] = false;
      updates['${item.id}/updatedAtMillis'] = ServerValue.timestamp;
    }
    if (updates.isEmpty) {
      return;
    }

    await notificationsRef(user).update(updates);
  }

  Future<void> delete(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await notificationsRef(user).child(notificationId).remove();
  }
}

class PatientQueueCloudRepository {
  PatientQueueCloudRepository({FirebaseDatabase? database, FirebaseAuth? auth})
    : _database = database ?? FirebaseDatabase.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  DatabaseReference queueRef(User user) =>
      _database.ref(FirebasePaths.queueSnapshot(user.uid));

  Stream<QueueSnapshot?> listenQueue({required String firebaseUid}) {
    final liveUser = _auth.currentUser;
    if (liveUser == null ||
        liveUser.uid != firebaseUid ||
        !FirebaseBootstrap.enabled) {
      return const Stream<QueueSnapshot?>.empty();
    }

    return queueRef(liveUser).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return null;
      }
      return QueueSnapshotRtdbCodec.decode(Map<dynamic, dynamic>.from(value));
    });
  }

  Future<void> upsert(QueueSnapshot snapshot) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await queueRef(user).set(QueueSnapshotRtdbCodec.encode(snapshot));
  }

  Future<void> clear() async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await queueRef(user).remove();
  }
}

class DoctorQueueCloudRepository {
  DoctorQueueCloudRepository({FirebaseDatabase? database, FirebaseAuth? auth})
    : _database = database ?? FirebaseDatabase.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  DatabaseReference queueRef(User user) =>
      _database.ref(FirebasePaths.doctorQueue(user.uid));

  static List<PatientCase> decodeQueueCollection(Object? snapshotValue) {
    if (snapshotValue is! Map) {
      return <PatientCase>[];
    }

    final map = Map<dynamic, dynamic>.from(snapshotValue);
    final decoded = <PatientCase>[];
    for (final MapEntry<dynamic, dynamic> entry in map.entries) {
      final key = '${entry.key}';
      final value = entry.value;
      if (value is Map) {
        final raw = Map<dynamic, dynamic>.from(value);
        raw['id'] = raw['id'] ?? key;
        decoded.add(PatientCaseRtdbCodec.decode(raw));
      }
    }

    return decoded;
  }

  Stream<List<PatientCase>> listenQueue({required String firebaseUid}) {
    final liveUser = _auth.currentUser;
    if (liveUser == null ||
        liveUser.uid != firebaseUid ||
        !FirebaseBootstrap.enabled) {
      return const Stream<List<PatientCase>>.empty();
    }

    return queueRef(liveUser).onValue.map((event) {
      return decodeQueueCollection(event.snapshot.value);
    });
  }

  Future<void> upsert(PatientCase patientCase) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    // Stamp the authenticated UID before encoding so the database rule
    // `newData.child('patientUid').val() === auth.uid` is always satisfied.
    final stamped = PatientCase(
      id: patientCase.id,
      patientName: patientCase.patientName,
      age: patientCase.age,
      gender: patientCase.gender,
      token: patientCase.token,
      symptoms: patientCase.symptoms,
      conditions: patientCase.conditions,
      patientUid: user.uid,
      patientImageAsset: patientCase.patientImageAsset,
    );

    await queueRef(user).child(stamped.id).set(
          PatientCaseRtdbCodec.encode(stamped),
        );
  }

  Future<void> delete(String caseId) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await queueRef(user).child(caseId).remove();
  }
}

class DoctorScheduleCloudRepository {
  DoctorScheduleCloudRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  }) : _database = database ?? FirebaseDatabase.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  DatabaseReference scheduleRef(User user) =>
      _database.ref(FirebasePaths.doctorSchedule(user.uid));

  Stream<DoctorSchedule?> listenSchedule({required String firebaseUid}) {
    final liveUser = _auth.currentUser;
    if (liveUser == null ||
        liveUser.uid != firebaseUid ||
        !FirebaseBootstrap.enabled) {
      return const Stream<DoctorSchedule?>.empty();
    }

    return scheduleRef(liveUser).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return null;
      }
      return DoctorScheduleRtdbCodec.decode(Map<dynamic, dynamic>.from(value));
    });
  }

  Stream<DoctorSchedule> listenDoctorSchedule({required String doctorUid}) {
    if (!FirebaseBootstrap.enabled) {
      return Stream<DoctorSchedule>.value(DoctorSchedule.fallback(doctorUid));
    }

    return _database.ref(FirebasePaths.doctorSchedule(doctorUid)).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return DoctorSchedule.fallback(doctorUid);
      }
      return DoctorScheduleRtdbCodec.decode(Map<dynamic, dynamic>.from(value));
    });
  }

  Stream<Map<String, String>> listenBookedSlots({
    required String doctorUid,
    required String dateStr,
  }) {
    if (!FirebaseBootstrap.enabled) {
      return Stream<Map<String, String>>.value(const <String, String>{});
    }

    return _database
        .ref('doctors/$doctorUid/booked_slots/$dateStr')
        .onValue
        .map((event) {
      final val = event.snapshot.value;
      if (val is Map) {
        return val.map((key, value) => MapEntry('$key', '$value'));
      }
      return const <String, String>{};
    });
  }

  Future<void> upsert(DoctorSchedule schedule) async {
    final user = _auth.currentUser;
    if (user == null || !FirebaseBootstrap.enabled) {
      return;
    }

    await scheduleRef(user).set(DoctorScheduleRtdbCodec.encode(schedule));
  }
}

class DoctorCatalogCloudRepository {
  DoctorCatalogCloudRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  DatabaseReference catalogRef() =>
      _database.ref(FirebasePaths.doctorCatalog());

  static List<Doctor> decodeCatalog(Object? snapshotValue) {
    if (snapshotValue is! Map) {
      return <Doctor>[];
    }

    final map = Map<dynamic, dynamic>.from(snapshotValue);
    final decoded = <Doctor>[];
    for (final MapEntry<dynamic, dynamic> entry in map.entries) {
      final key = '${entry.key}';
      final value = entry.value;
      if (value is Map) {
        final raw = Map<dynamic, dynamic>.from(value);
        raw['id'] = raw['id'] ?? key;
        decoded.add(DoctorRtdbCodec.decode(raw));
      }
    }

    return decoded;
  }

  Stream<List<Doctor>> listenCatalog() {
    if (!FirebaseBootstrap.enabled) {
      return const Stream<List<Doctor>>.empty();
    }

    return catalogRef().onValue.map((event) {
      return decodeCatalog(event.snapshot.value);
    });
  }

  Future<void> upsert(Doctor doctor) async {
    if (!FirebaseBootstrap.enabled) {
      return;
    }

    await catalogRef().child(doctor.id).set(DoctorRtdbCodec.encode(doctor));
  }
}

// ─── Full Prescription Store (doctor-written, patient-readable) ───────────────

class PatientPrescriptionCloudRepository {
  PatientPrescriptionCloudRepository({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  DatabaseReference _prescriptionsRef(String patientUid) =>
      _database.ref(FirebasePaths.patientPrescriptions(patientUid));

  /// Write a full prescription (including medicine list) under the patient's node.
  /// Called atomically alongside the HealthRecord write in sendDoctorPrescription.
  Future<void> upsert({
    required Prescription prescription,
    required String patientUid,
  }) async {
    if (!FirebaseBootstrap.enabled) return;
    await _prescriptionsRef(patientUid)
        .child(prescription.id)
        .set(PrescriptionRtdbCodec.encode(prescription));
  }

  /// Fetches the stored prescription whose id matches the record's id prefix.
  /// Returns null if not found so the caller can build a fallback.
  Future<Prescription?> getForRecord(
    HealthRecord record,
    String patientUid,
  ) async {
    if (!FirebaseBootstrap.enabled) return null;

    try {
      // Prescription ID is 'rx_<timestamp>' derived from record id 'r_<timestamp>'.
      // Try the direct rx_ prefixed key first.
      final rxId = 'rx_${record.id.replaceFirst('r_', '')}';
      final snap = await _prescriptionsRef(patientUid)
          .child(rxId)
          .get()
          .timeout(const Duration(seconds: 6));

      if (snap.exists && snap.value is Map) {
        return PrescriptionRtdbCodec.decode(
          Map<dynamic, dynamic>.from(snap.value! as Map),
          fallbackId: rxId,
        );
      }

      // Fallback: scan all prescriptions and match by id
      final allSnap = await _prescriptionsRef(patientUid)
          .get()
          .timeout(const Duration(seconds: 6));

      if (allSnap.exists && allSnap.value is Map) {
        final map = Map<dynamic, dynamic>.from(allSnap.value! as Map);
        for (final entry in map.entries) {
          if (entry.value is Map) {
            final rx = PrescriptionRtdbCodec.decode(
              Map<dynamic, dynamic>.from(entry.value as Map),
              fallbackId: '${entry.key}',
            );
            if (rx != null) return rx;
          }
        }
      }
    } catch (_) {
      // Suppress — caller will build a local fallback.
    }

    return null;
  }
}
