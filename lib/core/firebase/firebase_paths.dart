/// Canonical Realtime Database layout (avoid deep nesting; index by UID).
abstract final class FirebasePaths {
  // ── User private data (patient only, never written by other roles) ───────────

  // `users/{uid}`
  static String userRoot(String uid) => 'users/$uid';

  // `users/{uid}/profile`
  static String profile(String uid) => '${userRoot(uid)}/profile';

  // `users/{uid}/appointments`
  static String appointments(String uid) => '${userRoot(uid)}/appointments';

  // `users/{uid}/notifications`
  static String notifications(String uid) => '${userRoot(uid)}/notifications';

  // ── Role node (separate root — prevents patients from tampering with role) ──

  // `roles/{uid}` — replaces /users/{uid}/meta.
  // Written only during registration (transaction) or by admin approval flow.
  static String meta(String uid) => 'roles/$uid';

  // ── Doctor-written clinical data (only approved doctors may write) ───────────

  // `patient_records/{patientUid}/{recordId}`
  static String records(String uid) => 'patient_records/$uid';

  // `patient_reminders/{patientUid}/{reminderId}`
  static String reminders(String uid) => 'patient_reminders/$uid';

  // ── Queue snapshot (written by patient on book, cleared on prescription) ─────

  // `patient_queue_snapshots/{patientUid}`
  static String queueSnapshot(String uid) => 'patient_queue_snapshots/$uid';

  // `users/{uid}/ai_chat_history`
  static String aiChatHistory(String uid) => '${userRoot(uid)}/ai_chat_history';

  // ── Doctor data ───────────────────────────────────────────────────────────────

  // `doctors/{uid}`
  static String doctorRoot(String uid) => 'doctors/$uid';

  // `doctors/{uid}/queue`
  static String doctorQueue(String uid) => '${doctorRoot(uid)}/queue';

  // `doctors/{uid}/schedule`
  static String doctorSchedule(String uid) => '${doctorRoot(uid)}/schedule';

  // ── Shared catalog ────────────────────────────────────────────────────────────

  // `catalog/doctors`
  static String doctorCatalog() => 'catalog/doctors';

  // `doctor_applications`
  static String doctorApplications() => 'doctor_applications';

  // `doctor_applications/{uid}`
  static String doctorApplication(String uid) => 'doctor_applications/$uid';

  // ── Full prescription store (written by doctor, read by patient) ──────────────

  // `patient_prescriptions/{patientUid}`
  static String patientPrescriptions(String uid) => 'patient_prescriptions/$uid';

  // `patient_prescriptions/{patientUid}/{prescriptionId}`
  static String patientPrescription(String uid, String prescriptionId) =>
      'patient_prescriptions/$uid/$prescriptionId';
}
