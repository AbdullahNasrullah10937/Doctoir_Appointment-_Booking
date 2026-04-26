import '../../core/constants/app_assets.dart';
import '../../domain/entities/app_entities.dart';

class MockData {
  const MockData._();

  static List<Doctor> doctors() {
    return const [
      Doctor(
        id: 'd1',
        name: 'Dr. Sara Ali',
        specialty: 'General Physician',
        hospital: 'City Hospital Lahore',
        location: 'Johar Town, Lahore',
        experienceYears: 8,
        qualifications: 'MBBS, FCPS',
        rating: 4.8,
        consultationFee: 1000,
        nextAvailableSlot: 'Today 3:00 PM',
        gender: 'Female',
        distanceKm: 1.2,
        isAvailableToday: true,
        imageAsset: AppAssets.doctorSara,
        reviews: [
          DoctorReview(
            userName: 'Ahmed',
            comment: 'Doctor explained everything clearly.',
            rating: 5,
          ),
          DoctorReview(
            userName: 'Fatima',
            comment: 'Very patient and caring.',
            rating: 4.5,
          ),
        ],
      ),
      Doctor(
        id: 'd2',
        name: 'Dr. Khalid Mehmood',
        specialty: 'Cardiologist',
        hospital: 'National Heart Center',
        location: 'Model Town, Lahore',
        experienceYears: 12,
        qualifications: 'MBBS, FCPS Cardiology',
        rating: 4.6,
        consultationFee: 2500,
        nextAvailableSlot: 'Tomorrow 10:30 AM',
        gender: 'Male',
        distanceKm: 2.8,
        isAvailableToday: false,
        imageAsset: AppAssets.doctorKhalid,
      ),
      Doctor(
        id: 'd3',
        name: 'Dr. Ahmed Khan',
        specialty: 'ENT Specialist',
        hospital: 'Care Medical Complex',
        location: 'Gulberg, Lahore',
        experienceYears: 10,
        qualifications: 'MBBS, DLO',
        rating: 4.7,
        consultationFee: 1800,
        nextAvailableSlot: 'Today 6:15 PM',
        gender: 'Male',
        distanceKm: 3.1,
        isAvailableToday: true,
        imageAsset: AppAssets.doctorAhmed,
      ),
      Doctor(
        id: 'd4',
        name: 'Dr. Mariam Fatima',
        specialty: 'Dentist',
        hospital: 'Smile Dental Studio',
        location: 'DHA Phase 5, Lahore',
        experienceYears: 7,
        qualifications: 'BDS, RDS',
        rating: 4.9,
        consultationFee: 2200,
        nextAvailableSlot: 'Tomorrow 12:00 PM',
        gender: 'Female',
        distanceKm: 4.4,
        isAvailableToday: true,
        imageAsset: AppAssets.doctorMariam,
      ),
    ];
  }

  static List<Appointment> appointments(List<Doctor> doctors) {
    final now = DateTime.now();
    final sarah = doctors.firstWhere((doctor) => doctor.id == 'd1');
    final khalid = doctors.firstWhere((doctor) => doctor.id == 'd2');

    return [
      Appointment(
        id: 'a1',
        doctor: sarah,
        dateTime: DateTime(now.year, now.month, now.day, 15, 0),
        tokenNumber: 18,
        status: AppointmentStatus.upcoming,
        visitReason: 'Headache and fever for 2 days',
      ),
      Appointment(
        id: 'a2',
        doctor: khalid,
        dateTime: now.subtract(const Duration(days: 15)),
        tokenNumber: 6,
        status: AppointmentStatus.completed,
        visitReason: 'Chest pain follow-up',
      ),
    ];
  }

  static List<HealthRecord> records() {
    return [
      HealthRecord(
        id: 'r1',
        date: DateTime(2026, 2, 12),
        doctorName: 'Dr. Ahmed Khan',
        issue: 'Fever',
        diagnosisNotes: 'Viral infection',
        prescriptionSummary: 'Paracetamol 500mg, 3x daily for 5 days',
      ),
      HealthRecord(
        id: 'r2',
        date: DateTime(2026, 1, 3),
        doctorName: 'Dr. Sara Ali',
        issue: 'Headache',
        diagnosisNotes: 'Migraine trigger from dehydration',
        prescriptionSummary: 'Ibuprofen 400mg, 2x daily',
      ),
    ];
  }

  static List<MedicationReminder> reminders() {
    return const [
      MedicationReminder(
        id: 'm1',
        medicineName: 'Paracetamol 500mg',
        times: ['9:00 AM', '3:00 PM', '9:00 PM'],
        remainingDays: 5,
        isEnabled: true,
      ),
      MedicationReminder(
        id: 'm2',
        medicineName: 'Vitamin C 1000mg',
        times: ['8:00 AM'],
        remainingDays: 7,
        isEnabled: true,
      ),
    ];
  }

  static List<AppNotification> notifications() {
    return const [
      AppNotification(
        id: 'n1',
        title: 'Queue Update',
        message: '2 patients ahead of you for Dr. Sara Ali',
        type: NotificationType.queue,
        timeLabel: '2 min ago',
      ),
      AppNotification(
        id: 'n2',
        title: 'Medicine Reminder',
        message: 'Time to take Paracetamol 500mg',
        type: NotificationType.medication,
        timeLabel: '1 hour ago',
      ),
      AppNotification(
        id: 'n3',
        title: 'Booking Confirmed',
        message: 'Appointment with Dr. Khalid is confirmed',
        type: NotificationType.appointment,
        timeLabel: 'Yesterday',
      ),
    ];
  }

  static List<PatientCase> doctorQueue() {
    return const [
      PatientCase(
        id: 'p1',
        patientName: 'Ahmed Raza',
        age: 28,
        gender: 'Male',
        token: 14,
        symptoms: 'Fever, sore throat, headache for 2 days',
        conditions: ['Diabetes Type 2', 'Hypertension'],
        patientImageAsset: AppAssets.patientAhmed,
      ),
      PatientCase(
        id: 'p2',
        patientName: 'Fatima Khan',
        age: 35,
        gender: 'Female',
        token: 15,
        symptoms: 'Follow-up after blood pressure medication',
        conditions: ['Hypertension'],
        patientImageAsset: AppAssets.patientFatima,
      ),
    ];
  }

  static DoctorSchedule doctorSchedule() {
    return const DoctorSchedule(
      workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      morningStart: '9:00 AM',
      morningEnd: '1:00 PM',
      eveningStart: '5:00 PM',
      eveningEnd: '8:00 PM',
    );
  }

  static QueueSnapshot queue() {
    return const QueueSnapshot(
      doctorName: 'Dr. Sara Ali',
      clinicLocation: 'City Hospital, Room 3A, Lahore',
      yourToken: 18,
      currentToken: 14,
      patientsAhead: 4,
      estimatedWaitMinutes: 25,
    );
  }

  static List<String> aiSuggestions(String symptomText) {
    final lower = symptomText.toLowerCase();

    if (lower.contains('sore throat') || lower.contains('ear')) {
      return ['General Physician', 'ENT Specialist'];
    }

    if (lower.contains('chest') || lower.contains('heart')) {
      return ['Cardiologist', 'General Physician'];
    }

    if (lower.contains('tooth') || lower.contains('gum')) {
      return ['Dentist', 'General Physician'];
    }

    return ['General Physician', 'Internal Medicine'];
  }

  static Prescription prescriptionFromRecord(HealthRecord record) {
    return Prescription(
      id: 'rx_${record.id}',
      date: record.date,
      doctorName: record.doctorName,
      patientName: 'Ahmed Raza',
      diagnosis: record.diagnosisNotes,
      medicines: const [
        PrescriptionMedicine(
          name: 'Paracetamol',
          dose: '500mg',
          frequency: '3 times daily',
          duration: '5 days',
        ),
        PrescriptionMedicine(
          name: 'Vitamin C',
          dose: '1000mg',
          frequency: '1 time daily',
          duration: '7 days',
        ),
      ],
      notes: 'Drink fluids and rest. Follow-up if no improvement in 5 days.',
    );
  }
}
