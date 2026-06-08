import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../presentation/routes/app_router.dart';
import '../../../domain/entities/app_entities.dart' hide NotificationType;
import '../logging/logging_service.dart';
import 'notification_payload.dart';

// ─── Background handler ───────────────────────────────────────────────────────
// MUST be a top-level function — called by the FCM plugin in a separate isolate.
// Firebase must be re-initialized since this runs in an isolated context.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await LoggingService.initialize();
  LoggingService.info('[FCM] Background message: ${message.messageId}');
  await NotificationService._showLocalNotification(message);
}

// ─── Android notification channel ─────────────────────────────────────────────
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'qurexa_high_importance_v2',       // ID referenced in AndroidManifest.xml
  'Qurexa Notifications',          // Display name
  description: 'Appointment updates, reminders, and doctor messages.',
  importance: Importance.max,
);

// ─── Medication reminder channel ──────────────────────────────────────────────
const AndroidNotificationChannel _reminderChannel = AndroidNotificationChannel(
  'qurexa_medication_reminders',
  'Medication Reminders',
  description: 'Daily medication dose reminders.',
  importance: Importance.max,
  playSound: true,
);

/// Full-lifecycle FCM + Local Notification service for Qurexa.
///
/// Handles three delivery states:
///   - Foreground: FCM callback → shows a local notification overlay
///   - Background: System tray (handled by FCM plugin automatically)
///   - Terminated: App launched from notification → extracts initial message
///
/// Security: Payloads never contain PHI. Only opaque ref_id + route are used.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;

  // ─── Initialization ────────────────────────────────────────────────────────

  /// Initialize FCM + local notifications. Call once from app root initState.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    // ── Initialize timezone database for scheduled alarms ──────────────────
    tz_data.initializeTimeZones();

    // ── Local notifications setup ──────────────────────────────────────────
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,  // We request manually below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // ── Create Android notification channels ───────────────────────────────
    final androidPlugin = _localPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_reminderChannel);

    // ── Request FCM permission (iOS + Android 13+) ─────────────────────────
    await _requestPermission();

    // ── Foreground message listener ────────────────────────────────────────
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── Notification tap from background state ─────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // ── App launched from terminated state via notification ────────────────
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Defer navigation until the widget tree is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(initialMessage);
      });
    }

    LoggingService.info('[FCM] Token: ${await FirebaseMessaging.instance.getToken()}');
  }

  // ─── Permission ────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    LoggingService.info('[FCM] Permission: ${settings.authorizationStatus}');

    // Request permission on Android 13+ (API 33+)
    try {
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      LoggingService.error('[NotificationService] Android notification permission request failed', error: e);
    }

    // Request exact alarm permission on Android 12+ (API 31+)
    try {
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (e) {
      LoggingService.error('[NotificationService] Exact alarm permission request failed', error: e);
    }
  }

  // ─── Foreground handler ────────────────────────────────────────────────────

  static void _handleForegroundMessage(RemoteMessage message) {
    LoggingService.info('[FCM] Foreground message: ${message.messageId}');
    // Show a local heads-up notification for foreground delivery
    _showLocalNotification(message);
  }

  // ─── Notification tap handler ──────────────────────────────────────────────

  static void _handleNotificationTap(RemoteMessage message) {
    LoggingService.info('[FCM] Notification tapped: ${message.data}');
    final payload = NotificationPayload.fromMap(message.data);
    if (payload == null) return;
    _navigateFromPayload(payload);
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    // payload is stored as the route string for simplicity
    final route = response.payload;
    if (route != null && route.isNotEmpty) {
      _navigatorKey?.currentState?.pushNamed(route);
    }
  }

  // ─── Local notification display ────────────────────────────────────────────

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final payload = NotificationPayload.fromMap(message.data);

    final String title;
    final String body;

    if (notification != null) {
      title = notification.title ?? payload?.type.displayTitle ?? 'Qurexa';
      body = notification.body ?? '';
    } else if (payload != null) {
      title = message.data['title'] ?? payload.type.displayTitle;
      body = message.data['body'] ?? '';
    } else {
      title = message.data['title'] ?? 'Qurexa';
      body = message.data['body'] ?? '';
    }

    if (title.isEmpty && body.isEmpty) return;

    await _localPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload?.route,
    );
  }

  // ─── Deep link navigation ──────────────────────────────────────────────────

  static void _navigateFromPayload(NotificationPayload payload) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    switch (payload.type) {
      case NotificationType.appointmentConfirmed:
      case NotificationType.appointmentReminder:
      case NotificationType.queueUpdate:
        // Navigate to queue tracker — full appointment object loaded from state
        navigator.pushNamed(AppRouter.queueTracker);
      case NotificationType.prescriptionReady:
        navigator.pushNamed(AppRouter.digitalPrescription);
      case NotificationType.messageFromDoctor:
        navigator.pushNamed(AppRouter.aiAssistant);
      case NotificationType.generalAlert:
        navigator.pushNamed(AppRouter.notifications);
    }
  }

  /// Displays a heads-up notification immediately.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ─── Medication reminder scheduling ───────────────────────────────────────

  /// Schedules a daily device alarm for each time in [reminder.times].
  ///
  /// Time strings are expected in "h:mm AM/PM" format, e.g. "9:00 AM".
  /// Each alarm gets a stable unique ID derived from the reminder id + index
  /// so it can be cancelled individually.
  Future<void> scheduleReminder(MedicationReminder reminder) async {
    // Cancel any existing alarms for this reminder before re-scheduling.
    await cancelReminder(reminder.id);

    if (!reminder.isEnabled) return;

    for (int i = 0; i < reminder.times.length; i++) {
      final scheduledTime = _nextOccurrence(reminder.times[i]);
      if (scheduledTime == null) continue;

      final notifId = _reminderNotifId(reminder.id, i);

      try {
        await _localPlugin.zonedSchedule(
          notifId,
          '💊 Medication Reminder',
          'Time to take ${reminder.medicineName}',
          scheduledTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _reminderChannel.id,
              _reminderChannel.name,
              channelDescription: _reminderChannel.description,
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // repeat daily
          payload: AppRouter.medicationReminders,
        );
      } catch (e) {
        LoggingService.error('[NotificationService] Failed to schedule reminder', error: e);
      }
    }
  }

  /// Cancels all scheduled alarms for [reminderId].
  Future<void> cancelReminder(String reminderId) async {
    // We allow up to 10 time slots per reminder.
    for (int i = 0; i < 10; i++) {
      final notifId = _reminderNotifId(reminderId, i);
      await _localPlugin.cancel(notifId);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Converts a "h:mm AM/PM" string to the next daily TZDateTime occurrence.
  /// Returns null if the string cannot be parsed.
  static tz.TZDateTime? _nextOccurrence(String timeStr) {
    try {
      final trimmed = timeStr.trim().toUpperCase();
      final isPm = trimmed.endsWith('PM');
      final isAm = trimmed.endsWith('AM');
      final withoutAmPm =
          trimmed.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = withoutAmPm.split(':');
      if (parts.length < 2) return null;

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (isPm && hour != 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      // If the time has already passed today, schedule for tomorrow.
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    } catch (_) {
      return null;
    }
  }

  /// Generates a stable int notification ID from a reminder id + slot index.
  static int _reminderNotifId(String reminderId, int slotIndex) {
    return (reminderId.hashCode.abs() % 100000) * 10 + slotIndex;
  }

  /// Returns the current FCM device token. Useful for saving to Firestore.
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
