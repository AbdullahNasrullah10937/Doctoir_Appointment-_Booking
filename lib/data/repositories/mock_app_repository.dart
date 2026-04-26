import '../../domain/entities/app_entities.dart';
import '../../domain/repositories/app_repository.dart';
import '../mock/mock_data.dart';

class MockAppRepository implements AppRepository {
  @override
  Future<List<Doctor>> getDoctors() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return MockData.doctors();
  }

  @override
  Future<List<Appointment>> getAppointments() async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    return MockData.appointments(MockData.doctors());
  }

  @override
  Future<List<HealthRecord>> getHealthRecords() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockData.records();
  }

  @override
  Future<List<MedicationReminder>> getMedicationReminders() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return MockData.reminders();
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return MockData.notifications();
  }

  @override
  Future<List<PatientCase>> getDoctorQueue() async {
    await Future<void>.delayed(const Duration(milliseconds: 190));
    return MockData.doctorQueue();
  }

  @override
  Future<DoctorSchedule> getDoctorSchedule() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return MockData.doctorSchedule();
  }

  @override
  Future<QueueSnapshot> getQueueSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    return MockData.queue();
  }

  @override
  List<String> suggestSpecialists(String symptoms) {
    return MockData.aiSuggestions(symptoms);
  }

  @override
  Future<Prescription> getPrescriptionForRecord(HealthRecord record) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return MockData.prescriptionFromRecord(record);
  }
}
