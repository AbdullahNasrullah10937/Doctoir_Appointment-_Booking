import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firebase_paths.dart';
import '../../domain/entities/doctor_application.dart';

// ─── Codec ────────────────────────────────────────────────────────────────────

class DoctorApplicationCodec {
  DoctorApplicationCodec._();

  static Map<String, dynamic> encode(DoctorApplication app) {
    return <String, dynamic>{
      'uid': app.uid,
      'fullName': app.fullName,
      'email': app.email,
      'phoneNumber': app.phoneNumber,
      'gender': app.gender,
      'pmdcNumber': app.pmdcNumber,
      'specialization': app.specialization,
      'qualification': app.qualification,
      'experienceYears': app.experienceYears,
      'consultationFee': app.consultationFee,
      'bio': app.bio,
      'clinicName': app.clinicName,
      'clinicAddress': app.clinicAddress,
      'city': app.city,
      'status': app.status.name,
      'profileImageUrl': app.profileImageUrl,
      'pmdcCertificateUrl': app.pmdcCertificateUrl,
      'qualificationCertUrl': app.qualificationCertUrl,
      'rejectionReason': app.rejectionReason,
      'verifiedBy': app.verifiedBy,
      'verifiedAt': app.verifiedAt?.toUtc().millisecondsSinceEpoch,
      'createdAt': app.createdAt.toUtc().millisecondsSinceEpoch,
      'availabilityStart': app.availabilityStart,
      'availabilityEnd': app.availabilityEnd,
      'onlineConsultation': app.onlineConsultation,
      'availability': app.availability,
    };
  }

  static DoctorApplication? decode(Map<dynamic, dynamic> raw) {
    final uid = '${raw['uid'] ?? ''}';
    if (uid.isEmpty) return null;

    final statusRaw = '${raw['status'] ?? 'pending'}';
    final status = DoctorVerificationStatus.values.firstWhere(
      (s) => s.name == statusRaw,
      orElse: () => DoctorVerificationStatus.pending,
    );

    final createdMillis = raw['createdAt'];
    final createdAt = createdMillis is int
        ? DateTime.fromMillisecondsSinceEpoch(createdMillis, isUtc: true)
        : DateTime.now().toUtc();

    final verifiedMillis = raw['verifiedAt'];
    final verifiedAt = verifiedMillis is int
        ? DateTime.fromMillisecondsSinceEpoch(verifiedMillis, isUtc: true)
        : null;

    // Decode availability map
    final Map<String, bool> availability = <String, bool>{};
    final rawAvailability = raw['availability'];
    if (rawAvailability is Map) {
      for (final entry in rawAvailability.entries) {
        availability['${entry.key}'] = entry.value == true;
      }
    }

    return DoctorApplication(
      uid: uid,
      fullName: '${raw['fullName'] ?? ''}',
      email: '${raw['email'] ?? ''}',
      phoneNumber: '${raw['phoneNumber'] ?? ''}',
      gender: '${raw['gender'] ?? ''}',
      pmdcNumber: '${raw['pmdcNumber'] ?? ''}',
      specialization: '${raw['specialization'] ?? ''}',
      qualification: '${raw['qualification'] ?? ''}',
      experienceYears: raw['experienceYears'] is int
          ? raw['experienceYears'] as int
          : int.tryParse('${raw['experienceYears'] ?? '0'}') ?? 0,
      consultationFee: raw['consultationFee'] is int
          ? raw['consultationFee'] as int
          : int.tryParse('${raw['consultationFee'] ?? '0'}') ?? 0,
      bio: '${raw['bio'] ?? ''}',
      clinicName: '${raw['clinicName'] ?? ''}',
      clinicAddress: '${raw['clinicAddress'] ?? ''}',
      city: '${raw['city'] ?? ''}',
      status: status,
      createdAt: createdAt,
      profileImageUrl: raw['profileImageUrl'] is String &&
              '${raw['profileImageUrl']}'.isNotEmpty
          ? '${raw['profileImageUrl']}'
          : null,
      pmdcCertificateUrl: raw['pmdcCertificateUrl'] is String &&
              '${raw['pmdcCertificateUrl']}'.isNotEmpty
          ? '${raw['pmdcCertificateUrl']}'
          : null,
      qualificationCertUrl: raw['qualificationCertUrl'] is String &&
              '${raw['qualificationCertUrl']}'.isNotEmpty
          ? '${raw['qualificationCertUrl']}'
          : null,
      rejectionReason: raw['rejectionReason'] is String &&
              '${raw['rejectionReason']}'.isNotEmpty
          ? '${raw['rejectionReason']}'
          : null,
      verifiedBy: raw['verifiedBy'] is String && '${raw['verifiedBy']}'.isNotEmpty
          ? '${raw['verifiedBy']}'
          : null,
      verifiedAt: verifiedAt,
      availability: availability,
      availabilityStart: '${raw['availabilityStart'] ?? '09:00 AM'}',
      availabilityEnd: '${raw['availabilityEnd'] ?? '05:00 PM'}',
      onlineConsultation: raw['onlineConsultation'] == true,
    );
  }
}

// ─── Repository ───────────────────────────────────────────────────────────────

class DoctorApplicationRepository {
  DoctorApplicationRepository({FirebaseDatabase? database, FirebaseAuth? auth})
      : _db = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  DatabaseReference _appRef(String uid) =>
      _db.ref(FirebasePaths.doctorApplication(uid));

  DatabaseReference _allAppsRef() =>
      _db.ref(FirebasePaths.doctorApplications());

  DatabaseReference _catalogRef(String uid) =>
      _db.ref('${FirebasePaths.doctorCatalog()}/$uid');

  // ── Write application ──────────────────────────────────────────────────────

  Future<void> submitApplication(DoctorApplication app) async {
    if (!FirebaseBootstrap.enabled) return;
    await _appRef(app.uid).set(DoctorApplicationCodec.encode(app));
  }

  Future<void> resubmitApplication(DoctorApplication updated) async {
    if (!FirebaseBootstrap.enabled) return;
    final data = DoctorApplicationCodec.encode(updated);
    data['status'] = DoctorVerificationStatus.pending.name;
    data['rejectionReason'] = null;
    data['verifiedBy'] = null;
    data['verifiedAt'] = null;
    await _appRef(updated.uid).update(data);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<DoctorApplication?> getApplicationForUser(String uid) async {
    if (!FirebaseBootstrap.enabled) return null;
    final snap = await _appRef(uid)
        .get()
        .timeout(const Duration(seconds: 10));
    if (!snap.exists || snap.value is! Map) return null;
    return DoctorApplicationCodec.decode(
        Map<dynamic, dynamic>.from(snap.value! as Map));
  }

  // ── Admin streams ──────────────────────────────────────────────────────────

  Stream<List<DoctorApplication>> listenAllApplications() {
    if (!FirebaseBootstrap.enabled) {
      return const Stream<List<DoctorApplication>>.empty();
    }
    return _allAppsRef().onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <DoctorApplication>[];
      final result = <DoctorApplication>[];
      for (final entry in Map<dynamic, dynamic>.from(value).entries) {
        if (entry.value is Map) {
          final app = DoctorApplicationCodec.decode(
              Map<dynamic, dynamic>.from(entry.value as Map));
          if (app != null) result.add(app);
        }
      }
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    });
  }

  // ── Admin actions ──────────────────────────────────────────────────────────

  Future<void> approveDoctor(String uid) async {
    if (!FirebaseBootstrap.enabled) return;
    final adminUid = _auth.currentUser?.uid ?? '';
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Update application status
    await _appRef(uid).update(<String, dynamic>{
      'status': DoctorVerificationStatus.approved.name,
      'verifiedBy': adminUid,
      'verifiedAt': now,
      'rejectionReason': null,
    });

    // Update user meta verification status
    await _db.ref(FirebasePaths.meta(uid)).update(<String, dynamic>{
      'verificationStatus': DoctorVerificationStatus.approved.name,
    });

    // Fetch full application to build catalog entry
    final app = await getApplicationForUser(uid);
    if (app == null) return;

    // Write to /catalog/doctors/<uid>
    await _catalogRef(uid).set(<String, dynamic>{
      'id': uid,
      'name': app.fullName,
      'specialty': app.specialization,
      'hospital': app.clinicName,
      'location': '${app.clinicAddress}, ${app.city}',
      'experienceYears': app.experienceYears,
      'qualifications': app.qualification,
      'rating': 5.0,
      'consultationFee': app.consultationFee,
      'nextAvailableSlot': 'Today',
      'gender': app.gender,
      'distanceKm': 0.0,
      'isAvailableToday': true,
      'imageAsset': app.profileImageUrl,
      'reviews': <dynamic>[],
      'updatedAtMillis': now,
    });
  }

  Future<void> rejectDoctor(String uid, {required String reason}) async {
    if (!FirebaseBootstrap.enabled) return;
    final adminUid = _auth.currentUser?.uid ?? '';
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    await _appRef(uid).update(<String, dynamic>{
      'status': DoctorVerificationStatus.rejected.name,
      'rejectionReason': reason,
      'verifiedBy': adminUid,
      'verifiedAt': now,
    });

    // Update user meta
    await _db.ref(FirebasePaths.meta(uid)).update(<String, dynamic>{
      'verificationStatus': DoctorVerificationStatus.rejected.name,
    });

    // Remove from catalog if previously approved
    await _catalogRef(uid).remove();
  }

  // ── Write verification status on user meta ─────────────────────────────────

  Future<void> writePendingMeta(String uid) async {
    if (!FirebaseBootstrap.enabled) return;
    await _db.ref(FirebasePaths.meta(uid)).update(<String, dynamic>{
      'verificationStatus': DoctorVerificationStatus.pending.name,
    });
  }
}
