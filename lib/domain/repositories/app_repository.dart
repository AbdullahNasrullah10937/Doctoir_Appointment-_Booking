import '../entities/app_entities.dart';

abstract class AppRepository {
  Future<List<Doctor>> getDoctors();

  Future<List<Appointment>> getAppointments();

  Future<List<HealthRecord>> getHealthRecords();

  Future<List<MedicationReminder>> getMedicationReminders();

  Future<List<AppNotification>> getNotifications();

  Future<List<PatientCase>> getDoctorQueue();

  Future<DoctorSchedule> getDoctorSchedule();

  Future<QueueSnapshot> getQueueSnapshot();

  List<String> suggestSpecialists(String symptoms);

  Future<Prescription> getPrescriptionForRecord(HealthRecord record);
}
