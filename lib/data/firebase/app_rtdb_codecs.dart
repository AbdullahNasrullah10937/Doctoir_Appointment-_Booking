import 'dart:convert';

import '../../core/security/encryption_service.dart';
import '../../domain/entities/app_entities.dart';

class HealthRecordRtdbCodec {
  HealthRecordRtdbCodec._();

  // All clinical fields are encrypted before upload. Only the Unix-epoch date
  // stays plain so records can be ordered chronologically without decryption.

  static Map<String, dynamic> encode(HealthRecord record) {
    final sensitiveJson = jsonEncode(<String, dynamic>{
      'id': record.id,
      'doctorName': record.doctorName,
      'issue': record.issue,
      'diagnosisNotes': record.diagnosisNotes,
      'prescriptionSummary': record.prescriptionSummary,
    });

    return <String, dynamic>{
      'encryptedPayload': EncryptionService.encrypt(sensitiveJson),
      // Plain — used for server-side ordering only.
      'dateUtcMillis': record.date.toUtc().millisecondsSinceEpoch,
      'updatedAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static HealthRecord decode(Map<dynamic, dynamic> raw) {
    final encryptedPayload = '${raw['encryptedPayload'] ?? ''}';
    late Map<String, dynamic> sensitive;
    try {
      sensitive =
          jsonDecode(EncryptionService.decrypt(encryptedPayload))
              as Map<String, dynamic>;
    } catch (_) {
      // Fallback: return a placeholder record rather than crashing the list.
      sensitive = <String, dynamic>{
        'id': '${raw['id'] ?? 'record_missing'}',
        'doctorName': '[Encrypted]',
        'issue': '[Encrypted]',
        'diagnosisNotes': '[Encrypted]',
        'prescriptionSummary': '[Encrypted]',
      };
    }

    return HealthRecord(
      id: '${sensitive['id'] ?? 'record_missing'}',
      date: DateTime.fromMillisecondsSinceEpoch(
        _asInt(raw['dateUtcMillis'], fallback: 0),
        isUtc: true,
      ).toLocal(),
      doctorName: '${sensitive['doctorName'] ?? 'Doctor'}',
      issue: '${sensitive['issue'] ?? ''}',
      diagnosisNotes: '${sensitive['diagnosisNotes'] ?? ''}',
      prescriptionSummary: '${sensitive['prescriptionSummary'] ?? ''}',
    );
  }
}

class MedicationReminderRtdbCodec {
  MedicationReminderRtdbCodec._();

  // medicineName is considered PHI — encrypt it.
  static Map<String, dynamic> encode(MedicationReminder reminder) {
    return <String, dynamic>{
      'id': reminder.id,
      'medicineName': EncryptionService.encrypt(reminder.medicineName),
      'times': reminder.times,
      'remainingDays': reminder.remainingDays,
      'isEnabled': reminder.isEnabled,
      'updatedAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static MedicationReminder decode(Map<dynamic, dynamic> raw) {
    final id = '${raw['id'] ?? ''}';
    String medicineName;
    try {
      medicineName = EncryptionService.decrypt('${raw['medicineName'] ?? ''}');
    } catch (_) {
      medicineName = '${raw['medicineName'] ?? ''}';
    }
    return MedicationReminder(
      id: id.isEmpty ? 'reminder_missing' : id,
      medicineName: medicineName,
      times: _asStringList(raw['times']),
      remainingDays: _asInt(raw['remainingDays'], fallback: 1).clamp(0, 365),
      isEnabled: raw['isEnabled'] == true,
    );
  }
}

class AppNotificationRtdbCodec {
  AppNotificationRtdbCodec._();

  // Title and message are stored as plaintext for cross-device compatibility.
  // The AES key is device-local, so encrypting these fields causes garbled
  // text whenever the user reinstalls or logs in from a new device.
  // A createdAtMillis timestamp is stored so the UI can show relative times.

  static Map<String, dynamic> encode(AppNotification notification) {
    return <String, dynamic>{
      'id': notification.id,
      'title': notification.title,
      'message': notification.message,
      'type': notification.type.name,
      'isUnread': notification.isUnread,
      'createdAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static AppNotification decode(Map<dynamic, dynamic> raw) {
    final id = '${raw['id'] ?? ''}';
    final typeRaw = '${raw['type'] ?? NotificationType.system.name}';
    final resolvedType = NotificationType.values.firstWhere(
      (item) => item.name == typeRaw,
      orElse: () => NotificationType.system,
    );

    // Handle title/message: new records are plaintext; old records may be
    // AES ciphertexts (format "<ivBase64>:<cipherBase64>").
    String title = '${raw['title'] ?? ''}';
    String message = '${raw['message'] ?? ''}';
    if (title.contains(':') && title.length > 24) {
      // Looks like a legacy AES ciphertext — attempt decryption.
      try {
        title = EncryptionService.decrypt(title);
        message = EncryptionService.decrypt(message);
      } catch (_) {
        // Encrypted with a different device key — show a safe placeholder.
        title = 'Previous Notification';
        message = 'Open the app to see your latest updates.';
      }
    }

    // Compute a human-readable relative time from the stored timestamp.
    final millis = raw['createdAtMillis'] ?? raw['updatedAtMillis'];
    final timeLabel = millis is int
        ? _timeAgo(millis)
        : '${raw['timeLabel'] ?? 'Earlier'}';

    return AppNotification(
      id: id.isEmpty ? 'notification_missing' : id,
      title: title,
      message: message,
      type: resolvedType,
      timeLabel: timeLabel,
      isUnread: raw['isUnread'] != false,
    );
  }

  /// Converts a UTC-millisecond timestamp to a short relative label.
  static String _timeAgo(int utcMillis) {
    final diff = DateTime.now().toUtc().millisecondsSinceEpoch - utcMillis;
    if (diff < 60000) return 'Just now';
    if (diff < 3600000) return '${(diff / 60000).floor()} min ago';
    if (diff < 86400000) return '${(diff / 3600000).floor()} hr ago';
    if (diff < 604800000) return '${(diff / 86400000).floor()} d ago';
    return '${(diff / 604800000).floor()} wk ago';
  }
}

class QueueSnapshotRtdbCodec {
  QueueSnapshotRtdbCodec._();

  static Map<String, dynamic> encode(QueueSnapshot snapshot) {
    return <String, dynamic>{
      'doctorName': snapshot.doctorName,
      'doctorId': snapshot.doctorId ?? '',
      'clinicLocation': snapshot.clinicLocation,
      'yourToken': snapshot.yourToken,
      'currentToken': snapshot.currentToken,
      'patientsAhead': snapshot.patientsAhead,
      'estimatedWaitMinutes': snapshot.estimatedWaitMinutes,
      'updatedAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static QueueSnapshot decode(Map<dynamic, dynamic> raw) {
    return QueueSnapshot(
      doctorName: '${raw['doctorName'] ?? 'Doctor'}',
      doctorId:
          raw['doctorId'] is String && '${raw['doctorId']}'.isNotEmpty
              ? '${raw['doctorId']}'
              : null,
      clinicLocation: '${raw['clinicLocation'] ?? ''}',
      yourToken: _asInt(raw['yourToken'], fallback: 1).clamp(1, 99999),
      currentToken: _asInt(raw['currentToken'], fallback: 1).clamp(1, 99999),
      patientsAhead: _asInt(raw['patientsAhead'], fallback: 0).clamp(0, 99999),
      estimatedWaitMinutes: _asInt(
        raw['estimatedWaitMinutes'],
        fallback: 0,
      ).clamp(0, 99999),
    );
  }
}

class DoctorScheduleRtdbCodec {
  DoctorScheduleRtdbCodec._();

  static Map<String, dynamic> encode(DoctorSchedule schedule) {
    return <String, dynamic>{
      'workingDays': schedule.workingDays,
      'morningStart': schedule.morningStart,
      'morningEnd': schedule.morningEnd,
      'eveningStart': schedule.eveningStart,
      'eveningEnd': schedule.eveningEnd,
      'blockedDates': schedule.blockedDates,
      'updatedAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static DoctorSchedule decode(Map<dynamic, dynamic> raw) {
    return DoctorSchedule(
      workingDays: _asStringList(raw['workingDays']),
      morningStart: '${raw['morningStart'] ?? ''}',
      morningEnd: '${raw['morningEnd'] ?? ''}',
      eveningStart: '${raw['eveningStart'] ?? ''}',
      eveningEnd: '${raw['eveningEnd'] ?? ''}',
      blockedDates: _asStringList(raw['blockedDates']),
    );
  }
}

class PatientCaseRtdbCodec {
  PatientCaseRtdbCodec._();

  // patientName, symptoms, and conditions are the most sensitive PHI in the
  // doctor-side queue. They are bundled into an encrypted blob.
  // token, age, gender stay plain for queue ordering in the doctor's UI.

  static Map<String, dynamic> encode(PatientCase patientCase) {
    final sensitiveJson = jsonEncode(<String, dynamic>{
      'id': patientCase.id,
      'patientName': patientCase.patientName,
      'symptoms': patientCase.symptoms,
      'conditions': patientCase.conditions,
    });

    return <String, dynamic>{
      'encryptedPayload': EncryptionService.encrypt(sensitiveJson),
      // Plain — used for queue display/ordering without decryption.
      'age': patientCase.age,
      'gender': patientCase.gender,
      'token': patientCase.token,
      // Plain — required by database rule: newData.child('patientUid').val() === auth.uid
      // Must NOT be encrypted so Firebase can evaluate it server-side.
      'patientUid': patientCase.patientUid ?? '',
      'patientImageAsset': patientCase.patientImageAsset,
      'updatedAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static PatientCase decode(Map<dynamic, dynamic> raw) {
    final encryptedPayload = '${raw['encryptedPayload'] ?? ''}';
    late Map<String, dynamic> sensitive;
    try {
      sensitive =
          jsonDecode(EncryptionService.decrypt(encryptedPayload))
              as Map<String, dynamic>;
    } catch (_) {
      sensitive = <String, dynamic>{
        'id': '${raw['id'] ?? 'case_missing'}',
        'patientName': '[Encrypted]',
        'symptoms': '[Encrypted]',
        'conditions': <String>[],
      };
    }

    final id = '${sensitive['id'] ?? ''}';
    return PatientCase(
      id: id.isEmpty ? 'case_missing' : id,
      patientName: '${sensitive['patientName'] ?? ''}',
      age: _asInt(raw['age'], fallback: 18).clamp(0, 140),
      gender: '${raw['gender'] ?? ''}',
      token: _asInt(raw['token'], fallback: 1).clamp(1, 99999),
      symptoms: '${sensitive['symptoms'] ?? ''}',
      conditions: sensitive['conditions'] is Iterable
          ? (sensitive['conditions'] as Iterable)
              .map((item) => '$item')
              .where((item) => item.isNotEmpty)
              .toList()
          : <String>[],
      patientUid:
          raw['patientUid'] is String && '${raw['patientUid']}'.isNotEmpty
              ? '${raw['patientUid']}'
              : null,
      patientImageAsset:
          raw['patientImageAsset'] is String &&
              '${raw['patientImageAsset']}'.isNotEmpty
          ? '${raw['patientImageAsset']}'
          : null,
    );
  }
}

class DoctorRtdbCodec {
  DoctorRtdbCodec._();

  static Map<String, dynamic> encode(Doctor doctor) {
    return <String, dynamic>{
      'id': doctor.id,
      'name': doctor.name,
      'specialty': doctor.specialty,
      'hospital': doctor.hospital,
      'location': doctor.location,
      'experienceYears': doctor.experienceYears,
      'qualifications': doctor.qualifications,
      'rating': doctor.rating,
      'consultationFee': doctor.consultationFee,
      'nextAvailableSlot': doctor.nextAvailableSlot,
      'gender': doctor.gender,
      'distanceKm': doctor.distanceKm,
      'isAvailableToday': doctor.isAvailableToday,
      'imageUrl': doctor.imageUrl,
      'reviews': doctor.reviews
          .map(
            (review) => <String, dynamic>{
              'userName': review.userName,
              'comment': review.comment,
              'rating': review.rating,
            },
          )
          .toList(),
      'updatedAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static Doctor decode(Map<dynamic, dynamic> raw) {
    final id = '${raw['id'] ?? ''}';
    return Doctor(
      id: id.isEmpty ? 'doctor_missing' : id,
      name: '${raw['name'] ?? 'Doctor'}',
      specialty: '${raw['specialty'] ?? 'Specialist'}',
      hospital: '${raw['hospital'] ?? ''}',
      location: '${raw['location'] ?? ''}',
      experienceYears: _asInt(raw['experienceYears'], fallback: 1).clamp(0, 60),
      qualifications: '${raw['qualifications'] ?? 'MBBS'}',
      rating: _asDouble(raw['rating'], fallback: 5).clamp(0, 5),
      consultationFee: _asInt(
        raw['consultationFee'],
        fallback: 1000,
      ).clamp(0, 1000000),
      nextAvailableSlot: '${raw['nextAvailableSlot'] ?? ''}',
      gender: '${raw['gender'] ?? ''}',
      distanceKm: _asDouble(raw['distanceKm'], fallback: 1).clamp(0, 9999),
      isAvailableToday: raw['isAvailableToday'] == true,
      imageUrl: (raw['imageUrl'] ?? raw['imageAsset']) is String &&
              '${raw['imageUrl'] ?? raw['imageAsset']}'.isNotEmpty
          ? '${raw['imageUrl'] ?? raw['imageAsset']}'
          : null,
      reviews: _decodeReviews(raw['reviews']),
    );
  }

  static List<DoctorReview> _decodeReviews(dynamic value) {
    if (value is! Iterable) {
      return const <DoctorReview>[];
    }

    final parsed = <DoctorReview>[];
    for (final item in value) {
      if (item is Map) {
        parsed.add(
          DoctorReview(
            userName: '${item['userName'] ?? ''}',
            comment: '${item['comment'] ?? ''}',
            rating: _asDouble(item['rating'], fallback: 5).clamp(0, 5),
          ),
        );
      }
    }
    return parsed;
  }
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse('$value') ?? fallback;
}

double _asDouble(dynamic value, {required double fallback}) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value') ?? fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is Iterable) {
    return value
        .map((item) => '$item')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const <String>[];
}

// ─── Prescription (full, doctor-authored) ─────────────────────────────────────

class PrescriptionRtdbCodec {
  PrescriptionRtdbCodec._();

  // The full prescription (including medicine list) is stored encrypted so no
  // PHI is readable in the Firebase console. Only the dateUtcMillis stays plain
  // for chronological ordering.
  static Map<String, dynamic> encode(Prescription rx) {
    final sensitiveJson = jsonEncode(<String, dynamic>{
      'id': rx.id,
      'doctorName': rx.doctorName,
      'patientName': rx.patientName,
      'diagnosis': rx.diagnosis,
      'notes': rx.notes,
      'medicines': rx.medicines
          .map((m) => <String, dynamic>{
                'name': m.name,
                'dose': m.dose,
                'frequency': m.frequency,
                'duration': m.duration,
                'scheduledTimes': m.scheduledTimes,
                'durationDays': m.durationDays,
              })
          .toList(),
    });

    return <String, dynamic>{
      'encryptedPayload': EncryptionService.encrypt(sensitiveJson),
      // Plain — used for ordering only.
      'dateUtcMillis': rx.date.toUtc().millisecondsSinceEpoch,
      'updatedAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static Prescription? decode(Map<dynamic, dynamic> raw, {String? fallbackId}) {
    final encryptedPayload = '${raw['encryptedPayload'] ?? ''}';
    if (encryptedPayload.isEmpty) return null;

    late Map<String, dynamic> sensitive;
    try {
      sensitive =
          jsonDecode(EncryptionService.decrypt(encryptedPayload))
              as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final id = '${sensitive['id'] ?? fallbackId ?? 'rx_missing'}';
    final dateMillis = _asInt(raw['dateUtcMillis'], fallback: 0);
    final date = dateMillis > 0
        ? DateTime.fromMillisecondsSinceEpoch(dateMillis, isUtc: true).toLocal()
        : DateTime.now();

    final rawMedicines = sensitive['medicines'];
    final medicines = <PrescriptionMedicine>[];
    if (rawMedicines is List) {
      for (final item in rawMedicines) {
        if (item is Map) {
          final rawScheduledTimes = item['scheduledTimes'];
          final List<String> scheduledTimes = rawScheduledTimes is List
              ? rawScheduledTimes.map((dynamic e) => '$e').toList()
              : const <String>[];

          medicines.add(PrescriptionMedicine(
            name: '${item['name'] ?? ''}',
            dose: '${item['dose'] ?? ''}',
            frequency: '${item['frequency'] ?? ''}',
            duration: '${item['duration'] ?? ''}',
            scheduledTimes: scheduledTimes,
            durationDays: item['durationDays'] != null
                ? _asInt(item['durationDays'], fallback: 5)
                : null,
          ));
        }
      }
    }

    return Prescription(
      id: id,
      date: date,
      doctorName: '${sensitive['doctorName'] ?? 'Doctor'}',
      patientName: '${sensitive['patientName'] ?? 'Patient'}',
      diagnosis: '${sensitive['diagnosis'] ?? ''}',
      notes: '${sensitive['notes'] ?? ''}',
      medicines: medicines,
    );
  }
}
