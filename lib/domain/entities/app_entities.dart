enum UserRole { patient, doctor }

enum AppointmentStatus { upcoming, pending, completed, cancelled }

enum NotificationType { appointment, queue, medication, ai, system }

class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.age,
    required this.gender,
    this.bloodGroup,
    this.chronicConditions,
  });

  final String fullName;
  final int age;
  final String gender;
  final String? bloodGroup;
  final String? chronicConditions;

  UserProfile copyWith({
    String? fullName,
    int? age,
    String? gender,
    String? bloodGroup,
    String? chronicConditions,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      chronicConditions: chronicConditions ?? this.chronicConditions,
    );
  }
}

class DoctorReview {
  const DoctorReview({
    required this.userName,
    required this.comment,
    required this.rating,
  });

  final String userName;
  final String comment;
  final double rating;
}

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.location,
    required this.experienceYears,
    required this.qualifications,
    required this.rating,
    required this.consultationFee,
    required this.nextAvailableSlot,
    required this.gender,
    required this.distanceKm,
    required this.isAvailableToday,
    this.imageAsset,
    this.reviews = const [],
  });

  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final String location;
  final int experienceYears;
  final String qualifications;
  final double rating;
  final int consultationFee;
  final String nextAvailableSlot;
  final String gender;
  final double distanceKm;
  final bool isAvailableToday;
  final String? imageAsset;
  final List<DoctorReview> reviews;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.doctor,
    required this.dateTime,
    required this.tokenNumber,
    required this.status,
    required this.visitReason,
    this.isVideoConsultation = false,
  });

  final String id;
  final Doctor doctor;
  final DateTime dateTime;
  final int tokenNumber;
  final AppointmentStatus status;
  final String visitReason;
  final bool isVideoConsultation;

  Appointment copyWith({
    AppointmentStatus? status,
    String? visitReason,
    int? tokenNumber,
    DateTime? dateTime,
  }) {
    return Appointment(
      id: id,
      doctor: doctor,
      dateTime: dateTime ?? this.dateTime,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      status: status ?? this.status,
      visitReason: visitReason ?? this.visitReason,
      isVideoConsultation: isVideoConsultation,
    );
  }
}

class AppointmentDraft {
  const AppointmentDraft({
    required this.doctor,
    required this.slotDateTime,
    required this.visitReason,
    this.isVideoConsultation = false,
  });

  final Doctor doctor;
  final DateTime slotDateTime;
  final String visitReason;
  final bool isVideoConsultation;
}

class QueueSnapshot {
  const QueueSnapshot({
    required this.doctorName,
    required this.clinicLocation,
    required this.yourToken,
    required this.currentToken,
    required this.patientsAhead,
    required this.estimatedWaitMinutes,
  });

  final String doctorName;
  final String clinicLocation;
  final int yourToken;
  final int currentToken;
  final int patientsAhead;
  final int estimatedWaitMinutes;

  QueueSnapshot copyWith({
    int? currentToken,
    int? patientsAhead,
    int? estimatedWaitMinutes,
  }) {
    return QueueSnapshot(
      doctorName: doctorName,
      clinicLocation: clinicLocation,
      yourToken: yourToken,
      currentToken: currentToken ?? this.currentToken,
      patientsAhead: patientsAhead ?? this.patientsAhead,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
    );
  }
}

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.issue,
    required this.diagnosisNotes,
    required this.prescriptionSummary,
  });

  final String id;
  final DateTime date;
  final String doctorName;
  final String issue;
  final String diagnosisNotes;
  final String prescriptionSummary;
}

class PrescriptionMedicine {
  const PrescriptionMedicine({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
  });

  final String name;
  final String dose;
  final String frequency;
  final String duration;
}

class Prescription {
  const Prescription({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.patientName,
    required this.diagnosis,
    required this.medicines,
    required this.notes,
  });

  final String id;
  final DateTime date;
  final String doctorName;
  final String patientName;
  final String diagnosis;
  final List<PrescriptionMedicine> medicines;
  final String notes;
}

class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.times,
    required this.remainingDays,
    required this.isEnabled,
  });

  final String id;
  final String medicineName;
  final List<String> times;
  final int remainingDays;
  final bool isEnabled;

  MedicationReminder copyWith({
    List<String>? times,
    int? remainingDays,
    bool? isEnabled,
  }) {
    return MedicationReminder(
      id: id,
      medicineName: medicineName,
      times: times ?? this.times,
      remainingDays: remainingDays ?? this.remainingDays,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timeLabel,
    this.isUnread = true,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String timeLabel;
  final bool isUnread;

  AppNotification copyWith({bool? isUnread}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      timeLabel: timeLabel,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}

class PatientCase {
  const PatientCase({
    required this.id,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.token,
    required this.symptoms,
    required this.conditions,
    this.patientUid,
    this.patientImageAsset,
  });

  final String id;
  final String patientName;
  final int age;
  final String gender;
  final int token;
  final String symptoms;
  final List<String> conditions;
  /// Firebase UID of the patient who booked this queue slot.
  /// Required by the database rule: `patientUid === auth.uid`.
  final String? patientUid;
  final String? patientImageAsset;
}

class DoctorSchedule {
  const DoctorSchedule({
    required this.workingDays,
    required this.morningStart,
    required this.morningEnd,
    required this.eveningStart,
    required this.eveningEnd,
  });

  final List<String> workingDays;
  final String morningStart;
  final String morningEnd;
  final String eveningStart;
  final String eveningEnd;

  DoctorSchedule copyWith({
    List<String>? workingDays,
    String? morningStart,
    String? morningEnd,
    String? eveningStart,
    String? eveningEnd,
  }) {
    return DoctorSchedule(
      workingDays: workingDays ?? this.workingDays,
      morningStart: morningStart ?? this.morningStart,
      morningEnd: morningEnd ?? this.morningEnd,
      eveningStart: eveningStart ?? this.eveningStart,
      eveningEnd: eveningEnd ?? this.eveningEnd,
    );
  }
}
