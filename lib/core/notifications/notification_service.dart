import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../presentation/routes/app_router.dart';
import 'notification_payload.dart';

// ─── Background handler ───────────────────────────────────────────────────────
// MUST be a top-level function — called by the FCM plugin in a separate isolate.
// Firebase must be re-initialized since this runs in an isolated context.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
  await NotificationService._showLocalNotification(message);
}

// ─── Android notification channel ─────────────────────────────────────────────
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'qurexa_high_importance_v2',       // ID referenced in AndroidManifest.xml
  'Qurexa Notifications',          // Display name
  description: 'Appointment updates, reminders, and doctor messages.',
  importance: Importance.max,
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

    // ── Create Android notification channel ───────────────────────────────
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

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

    debugPrint('[FCM] Token: ${await FirebaseMessaging.instance.getToken()}');
  }

  // ─── Permission ────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // Request permission on Android 13+ (API 33+)
    try {
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[NotificationService] Android notification permission request failed: $e');
    }
  }

  // ─── Foreground handler ────────────────────────────────────────────────────

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');
    // Show a local heads-up notification for foreground delivery
    _showLocalNotification(message);
  }

  // ─── Notification tap handler ──────────────────────────────────────────────

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
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

  /// Displays a heads-up notification manually.
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

  /// Returns the current FCM device token. Useful for saving to Firestore.
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
