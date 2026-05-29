/// Canonical Realtime Database layout (avoid deep nesting; index by UID).
abstract final class FirebasePaths {
  /// `/users/<uid>`
  static String userRoot(String uid) => 'users/$uid';

  static String meta(String uid) => '${userRoot(uid)}/meta';

  /// `/users/<uid>/profile`
  static String profile(String uid) => '${userRoot(uid)}/profile';

  /// `/users/<uid>/appointments`
  static String appointments(String uid) => '${userRoot(uid)}/appointments';

  /// `/users/<uid>/records`
  static String records(String uid) => '${userRoot(uid)}/records';

  /// `/users/<uid>/reminders`
  static String reminders(String uid) => '${userRoot(uid)}/reminders';

  /// `/users/<uid>/notifications`
  static String notifications(String uid) => '${userRoot(uid)}/notifications';

  /// `/users/<uid>/queueSnapshot`
  static String queueSnapshot(String uid) => '${userRoot(uid)}/queueSnapshot';

  /// `/doctors/<uid>`
  static String doctorRoot(String uid) => 'doctors/$uid';

  /// `/doctors/<uid>/queue`
  static String doctorQueue(String uid) => '${doctorRoot(uid)}/queue';

  /// `/doctors/<uid>/schedule`
  static String doctorSchedule(String uid) => '${doctorRoot(uid)}/schedule';

  /// `/catalog/doctors`
  static String doctorCatalog() => 'catalog/doctors';
}
