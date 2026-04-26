import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/repositories/mock_app_repository.dart';
import '../../domain/entities/app_entities.dart';
import '../../domain/repositories/app_repository.dart';

class AppState extends ChangeNotifier {
  AppState({AppRepository? repository})
    : _repository = repository ?? MockAppRepository();

  final AppRepository _repository;

  bool initialized = false;
  bool isBootstrapping = false;

  bool seenOnboarding = false;
  bool isLoggedIn = false;
  bool profileCompleted = false;

  UserRole role = UserRole.patient;
  UserProfile? profile;

  int patientTabIndex = 0;
  int doctorTabIndex = 0;

  bool doctorNotificationsEnabled = true;
  String doctorLanguage = 'English';
  bool doctorPrivacyModeEnabled = true;

  List<Doctor> doctors = <Doctor>[];
  List<Appointment> appointments = <Appointment>[];
  List<HealthRecord> records = <HealthRecord>[];
  List<MedicationReminder> reminders = <MedicationReminder>[];
  List<AppNotification> notifications = <AppNotification>[];
  List<PatientCase> doctorQueue = <PatientCase>[];
  DoctorSchedule doctorSchedule = const DoctorSchedule(
    workingDays: <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    morningStart: '9:00 AM',
    morningEnd: '1:00 PM',
    eveningStart: '5:00 PM',
    eveningEnd: '8:00 PM',
  );
  QueueSnapshot? queueSnapshot;

  List<String> latestAiSuggestions = <String>[];

  Appointment? get nextUpcomingAppointment {
    final upcoming =
        appointments
            .where(
              (appointment) => appointment.status == AppointmentStatus.upcoming,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (upcoming.isEmpty) {
      return null;
    }

    return upcoming.first;
  }

  List<Appointment> get upcomingAppointments {
    final list =
        appointments
            .where(
              (appointment) => appointment.status == AppointmentStatus.upcoming,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  List<Appointment> get pastAppointments {
    final list =
        appointments
            .where(
              (appointment) =>
                  appointment.status == AppointmentStatus.completed,
            )
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  int get unreadNotificationCount {
    return notifications.where((item) => item.isUnread).length;
  }

  Future<void> initialize() async {
    if (initialized || isBootstrapping) {
      return;
    }

    isBootstrapping = true;
    notifyListeners();

    doctors = await _repository.getDoctors();
    appointments = await _repository.getAppointments();
    records = await _repository.getHealthRecords();
    reminders = await _repository.getMedicationReminders();
    notifications = await _repository.getNotifications();
    doctorQueue = await _repository.getDoctorQueue();
    doctorSchedule = await _repository.getDoctorSchedule();
    queueSnapshot = await _repository.getQueueSnapshot();

    initialized = true;
    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> login({required UserRole selectedRole}) async {
    role = selectedRole;
    isLoggedIn = true;

    if (selectedRole == UserRole.doctor) {
      profileCompleted = true;
    } else {
      profileCompleted = profile != null;
    }

    notifyListeners();
  }

  void completeOnboarding() {
    seenOnboarding = true;
    notifyListeners();
  }

  void completeProfile(UserProfile value) {
    profile = value;
    profileCompleted = true;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    role = UserRole.patient;
    patientTabIndex = 0;
    doctorTabIndex = 0;
    latestAiSuggestions = <String>[];
    notifyListeners();
  }

  void setPatientTab(int index) {
    patientTabIndex = index;
    notifyListeners();
  }

  void setDoctorTab(int index) {
    doctorTabIndex = index;
    notifyListeners();
  }

  void setDoctorNotificationsEnabled(bool value) {
    doctorNotificationsEnabled = value;
    notifyListeners();
  }

  void setDoctorLanguage(String value) {
    doctorLanguage = value;
    notifyListeners();
  }

  void setDoctorPrivacyModeEnabled(bool value) {
    doctorPrivacyModeEnabled = value;
    notifyListeners();
  }

  List<Doctor> filterDoctors({
    String query = '',
    String specialty = 'All',
    String gender = 'All',
    bool availableTodayOnly = false,
  }) {
    return doctors.where((doctor) {
      final queryMatch =
          query.trim().isEmpty ||
          doctor.name.toLowerCase().contains(query.toLowerCase()) ||
          doctor.specialty.toLowerCase().contains(query.toLowerCase());

      final specialtyMatch =
          specialty == 'All' || doctor.specialty == specialty;

      final genderMatch = gender == 'All' || doctor.gender == gender;

      final availabilityMatch =
          !availableTodayOnly || doctor.isAvailableToday == true;

      return queryMatch && specialtyMatch && genderMatch && availabilityMatch;
    }).toList();
  }

  Appointment bookAppointment({required AppointmentDraft draft}) {
    final token = 12 + Random().nextInt(10);

    final appointment = Appointment(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      doctor: draft.doctor,
      dateTime: draft.slotDateTime,
      tokenNumber: token,
      status: AppointmentStatus.upcoming,
      visitReason: draft.visitReason,
      isVideoConsultation: draft.isVideoConsultation,
    );

    appointments = <Appointment>[appointment, ...appointments];

    queueSnapshot = QueueSnapshot(
      doctorName: draft.doctor.name,
      clinicLocation: draft.doctor.hospital,
      yourToken: token,
      currentToken: token - 4,
      patientsAhead: 4,
      estimatedWaitMinutes: 25,
    );

    _addNotification(
      AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Booking Confirmed',
        message: 'Token #$token for ${draft.doctor.name} is confirmed.',
        type: NotificationType.appointment,
        timeLabel: 'Just now',
      ),
    );

    notifyListeners();
    return appointment;
  }

  void cancelAppointment(String appointmentId) {
    appointments = appointments.map((appointment) {
      if (appointment.id != appointmentId) {
        return appointment;
      }

      return appointment.copyWith(status: AppointmentStatus.cancelled);
    }).toList();

    notifyListeners();
  }

  void completeAppointment(String appointmentId) {
    appointments = appointments.map((appointment) {
      if (appointment.id != appointmentId) {
        return appointment;
      }

      return appointment.copyWith(status: AppointmentStatus.completed);
    }).toList();

    _addNotification(
      AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Rate Your Visit',
        message: 'Your appointment is completed. Share your feedback.',
        type: NotificationType.appointment,
        timeLabel: 'Just now',
      ),
    );

    notifyListeners();
  }

  void tickQueue() {
    final snapshot = queueSnapshot;
    if (snapshot == null || snapshot.patientsAhead <= 0) {
      return;
    }

    final updatedPatientsAhead = snapshot.patientsAhead - 1;
    final updatedWait = max(3, snapshot.estimatedWaitMinutes - 6);

    queueSnapshot = snapshot.copyWith(
      currentToken: snapshot.currentToken + 1,
      patientsAhead: updatedPatientsAhead,
      estimatedWaitMinutes: updatedWait,
    );

    if (updatedPatientsAhead == 2) {
      _addNotification(
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Queue Update',
          message: 'Only 2 patients are ahead of you now.',
          type: NotificationType.queue,
          timeLabel: 'Now',
        ),
      );
    }

    if (updatedPatientsAhead == 0) {
      _addNotification(
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Please Arrive At Clinic',
          message: 'Your token is next. Please reach the clinic now.',
          type: NotificationType.queue,
          timeLabel: 'Now',
        ),
      );
    }

    notifyListeners();
  }

  void toggleReminder(String reminderId) {
    reminders = reminders.map((item) {
      if (item.id != reminderId) {
        return item;
      }

      return item.copyWith(isEnabled: !item.isEnabled);
    }).toList();

    notifyListeners();
  }

  void runSymptomChecker(String symptomText) {
    latestAiSuggestions = _repository.suggestSpecialists(symptomText);
    notifyListeners();
  }

  Future<Prescription> getPrescriptionForRecord(HealthRecord record) {
    return _repository.getPrescriptionForRecord(record);
  }

  void sendDoctorPrescription({
    required PatientCase patientCase,
    required List<PrescriptionMedicine> medicines,
    required String notes,
  }) {
    final summary = medicines
        .map((medicine) => '${medicine.name} ${medicine.dose}')
        .join(', ');

    final newRecord = HealthRecord(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      doctorName: 'Dr. Sara Ali',
      issue: patientCase.symptoms,
      diagnosisNotes: notes,
      prescriptionSummary: summary,
    );

    records = <HealthRecord>[newRecord, ...records];

    reminders = <MedicationReminder>[
      ...medicines.map(
        (medicine) => MedicationReminder(
          id: 'm_${DateTime.now().millisecondsSinceEpoch}_${medicine.name}',
          medicineName: '${medicine.name} ${medicine.dose}',
          times: const <String>['9:00 AM', '3:00 PM', '9:00 PM'],
          remainingDays: 5,
          isEnabled: true,
        ),
      ),
      ...reminders,
    ];

    _addNotification(
      AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Prescription Ready',
        message: 'New digital prescription was shared with patient.',
        type: NotificationType.system,
        timeLabel: 'Now',
      ),
    );

    notifyListeners();
  }

  void updateDoctorSchedule(DoctorSchedule value) {
    doctorSchedule = value;
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    notifications = notifications
        .map((item) => item.copyWith(isUnread: false))
        .toList();
    notifyListeners();
  }

  void _addNotification(AppNotification item) {
    notifications = <AppNotification>[item, ...notifications];
  }
}
