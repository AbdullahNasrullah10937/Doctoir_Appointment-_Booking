
import '../../core/security/encryption_service.dart';
import '../../domain/entities/app_entities.dart';

/// Encodes/decodes appointments with flat doctor fields (denormalised snapshot).
/// visitReason is the only patient-PHI field — it is AES-256 encrypted.
/// All scheduling/doctor fields stay plain for server-side ordering.
class AppointmentRtdbCodec {
  AppointmentRtdbCodec._();

  static Map<String, dynamic> encode(Appointment appointment) {
    return <String, dynamic>{
      'id': appointment.id,
      'dateTimeUtcMillis': appointment.dateTime.toUtc().millisecondsSinceEpoch,
      'tokenNumber': appointment.tokenNumber,
      'status': appointment.status.name,
      // visitReason is patient PHI — encrypt it.
      'visitReason': EncryptionService.encrypt(appointment.visitReason),
      'isVideoConsultation': appointment.isVideoConsultation,
      'doctorId': appointment.doctor.id,
      'doctorName': appointment.doctor.name,
      'doctorSpecialty': appointment.doctor.specialty,
      'doctorHospital': appointment.doctor.hospital,
      'doctorLocation': appointment.doctor.location,
      'doctorExperienceYears': appointment.doctor.experienceYears,
      'doctorQualifications': appointment.doctor.qualifications,
      'doctorRating': appointment.doctor.rating,
      'doctorConsultationFee': appointment.doctor.consultationFee,
      'doctorNextAvailableSlot': appointment.doctor.nextAvailableSlot,
      'doctorGender': appointment.doctor.gender,
      'doctorDistanceKm': appointment.doctor.distanceKm,
      'doctorIsAvailableToday': appointment.doctor.isAvailableToday,
      'doctorImageUrl': appointment.doctor.imageUrl,
      'doctorReviews': appointment.doctor.reviews
          .map(
            (DoctorReview review) => <String, dynamic>{
              'userName': review.userName,
              'comment': review.comment,
              'rating': review.rating,
            },
          )
          .toList(),
      'updatedAtMillis': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static Appointment decode(
    Map<dynamic, dynamic> raw,
    List<Doctor> doctorCatalog,
  ) {
    final id = '${raw['id'] ?? ''}';
    final doctorId = '${raw['doctorId'] ?? id}';

    Doctor doctor;
    Doctor? enriched;
    for (final item in doctorCatalog) {
      if (item.id == doctorId) {
        enriched = item;
        break;
      }
    }

    final reviewsEncoded = raw['doctorReviews'];
    var reviews = enriched?.reviews ?? const <DoctorReview>[];
    if (reviewsEncoded is Iterable) {
      final parsed = reviewsEncoded
          .map(_decodeReview)
          .whereType<DoctorReview>()
          .toList();
      if (parsed.isNotEmpty) {
        reviews = parsed;
      }
    }

    if (enriched != null) {
      doctor = enriched;
    } else {
      doctor = Doctor(
        id: doctorId,
        name: '${raw['doctorName'] ?? 'Doctor'}',
        specialty: '${raw['doctorSpecialty'] ?? 'Specialist'}',
        hospital: '${raw['doctorHospital'] ?? 'Hospital'}',
        location: '${raw['doctorLocation'] ?? 'Location'}',
        experienceYears:
            _asInt(raw['doctorExperienceYears'], fallback: 1).clamp(0, 60),
        qualifications:
            '${raw['doctorQualifications'] ?? qualificationsFallback}',
        rating: _asDouble(raw['doctorRating'], fallback: 5),
        consultationFee:
            _asInt(raw['doctorConsultationFee'], fallback: 1000).clamp(0, 1000000),
        nextAvailableSlot:
            '${raw['doctorNextAvailableSlot'] ?? upcomingSlotFallback}',
        gender: '${raw['doctorGender'] ?? 'Female'}',
        distanceKm:
            _asDouble(raw['doctorDistanceKm'], fallback: 1).clamp(0, 9999),
        isAvailableToday: raw['doctorIsAvailableToday'] == true,
        imageUrl: (raw['doctorImageUrl'] ?? raw['doctorImageAsset']) is String &&
                '${raw['doctorImageUrl'] ?? raw['doctorImageAsset']}'.isNotEmpty
            ? '${raw['doctorImageUrl'] ?? raw['doctorImageAsset']}'
            : null,
        reviews: reviews,
      );
    }

    final statusRaw = '${raw['status'] ?? AppointmentStatus.upcoming.name}';
    AppointmentStatus resolvedStatus = AppointmentStatus.values.firstWhere(
      (item) => item.name == statusRaw,
      orElse: () => AppointmentStatus.upcoming,
    );

    return Appointment(
      id: id.isEmpty ? 'missing_id' : id,
      doctor: doctor,
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        _asInt(raw['dateTimeUtcMillis'], fallback: 0),
        isUtc: true,
      ).toLocal(),
      tokenNumber: _asInt(raw['tokenNumber'], fallback: 1).clamp(1, 99999),
      status: resolvedStatus,
      visitReason: _decryptField(raw['visitReason']),
      isVideoConsultation: raw['isVideoConsultation'] == true,
    );
  }

  static DoctorReview? _decodeReview(dynamic value) {
    if (value is! Map) {
      return null;
    }
    final map = value;
    return DoctorReview(
      userName: '${map['userName'] ?? 'Patient'}',
      comment: '${map['comment'] ?? ''}',
      rating: _asDouble(map['rating'], fallback: 5).clamp(0, 5),
    );
  }

  /// Decrypts a field encrypted by [EncryptionService].
  /// Falls back to the raw string value for pre-migration plain-text records.
  static String _decryptField(dynamic raw) {
    final s = '$raw';
    if (s.isEmpty || s == 'null') return '';
    try {
      return EncryptionService.decrypt(s);
    } catch (_) {
      return s; // pre-migration plain-text fallback
    }
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return int.tryParse('$value') ?? fallback;
  }

  static double _asDouble(dynamic value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? fallback;
  }

  static const String qualificationsFallback = 'MBBS';
  static const String upcomingSlotFallback = 'Flexible';
}
