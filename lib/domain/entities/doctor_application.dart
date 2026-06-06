enum DoctorVerificationStatus { pending, approved, rejected }

class DoctorApplication {
  const DoctorApplication({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.pmdcNumber,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.consultationFee,
    required this.bio,
    required this.clinicName,
    required this.clinicAddress,
    required this.city,
    required this.status,
    required this.createdAt,
    this.profileImageUrl,
    this.pmdcCertificateUrl,
    this.qualificationCertUrl,
    this.rejectionReason,
    this.verifiedBy,
    this.verifiedAt,
    this.availability = const <String, bool>{},
    this.availabilityStart = '09:00 AM',
    this.availabilityEnd = '05:00 PM',
    this.onlineConsultation = false,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String gender;
  final String pmdcNumber;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final int consultationFee;
  final String bio;
  final String clinicName;
  final String clinicAddress;
  final String city;
  final DoctorVerificationStatus status;
  final DateTime createdAt;
  final String? profileImageUrl;
  final String? pmdcCertificateUrl;
  final String? qualificationCertUrl;
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final Map<String, bool> availability;
  final String availabilityStart;
  final String availabilityEnd;
  final bool onlineConsultation;

  DoctorApplication copyWith({
    DoctorVerificationStatus? status,
    String? rejectionReason,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? profileImageUrl,
    String? pmdcCertificateUrl,
    String? qualificationCertUrl,
  }) {
    return DoctorApplication(
      uid: uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      gender: gender,
      pmdcNumber: pmdcNumber,
      specialization: specialization,
      qualification: qualification,
      experienceYears: experienceYears,
      consultationFee: consultationFee,
      bio: bio,
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      city: city,
      status: status ?? this.status,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      pmdcCertificateUrl: pmdcCertificateUrl ?? this.pmdcCertificateUrl,
      qualificationCertUrl: qualificationCertUrl ?? this.qualificationCertUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      availability: availability,
      availabilityStart: availabilityStart,
      availabilityEnd: availabilityEnd,
      onlineConsultation: onlineConsultation,
    );
  }
}
