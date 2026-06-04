/// Secure, strongly-typed FCM notification payload schema.
///
/// Security Rules:
///   - Payload NEVER contains patient PHI, medical data, auth tokens,
///     prescriptions, or diagnosis details.
///   - Only opaque reference IDs (ref_id) are passed. The app fetches
///     full data from Firebase after the notification tap.
///   - display_name may contain a doctor's name — safe non-clinical string.
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.route,
    this.refId,
    this.displayName,
  });

  /// The notification category — used for routing and icon selection.
  final NotificationType type;

  /// Named route to navigate to on notification tap (matches AppRouter constants).
  final String route;

  /// Opaque reference ID — never raw Firebase path, always an entity ID.
  final String? refId;

  /// Safe display string (e.g., doctor name). Never medical/clinical data.
  final String? displayName;

  // ─── Parsing ──────────────────────────────────────────────────────────────

  /// Parses a raw FCM data map into a [NotificationPayload].
  /// Returns null if the data map is missing or has an unrecognised type.
  static NotificationPayload? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;

    final typeStr = data['type'] as String?;
    final type = NotificationType.fromString(typeStr);
    if (type == null) return null;

    final route = data['route'] as String?;
    if (route == null || route.isEmpty) return null;

    return NotificationPayload(
      type: type,
      route: route,
      refId: data['ref_id'] as String?,
      displayName: data['display_name'] as String?,
    );
  }

  @override
  String toString() =>
      'NotificationPayload(type: ${type.name}, route: $route, refId: $refId)';
}

// ─── Notification Type ────────────────────────────────────────────────────────

enum NotificationType {
  appointmentConfirmed,
  appointmentReminder,
  queueUpdate,
  prescriptionReady,
  messageFromDoctor,
  generalAlert;

  /// Maps a raw string from the FCM payload to the enum value.
  /// Returns null for unrecognised or null strings.
  static NotificationType? fromString(String? value) {
    switch (value) {
      case 'appointment_confirmed':  return NotificationType.appointmentConfirmed;
      case 'appointment_reminder':   return NotificationType.appointmentReminder;
      case 'queue_update':           return NotificationType.queueUpdate;
      case 'prescription_ready':     return NotificationType.prescriptionReady;
      case 'message_from_doctor':    return NotificationType.messageFromDoctor;
      case 'general_alert':          return NotificationType.generalAlert;
      default:                       return null;
    }
  }

  String get displayTitle {
    switch (this) {
      case NotificationType.appointmentConfirmed: return 'Appointment Confirmed';
      case NotificationType.appointmentReminder:  return 'Appointment Reminder';
      case NotificationType.queueUpdate:          return 'Queue Update';
      case NotificationType.prescriptionReady:    return 'Prescription Ready';
      case NotificationType.messageFromDoctor:    return 'Message from Doctor';
      case NotificationType.generalAlert:         return 'Qurexa';
    }
  }
}
