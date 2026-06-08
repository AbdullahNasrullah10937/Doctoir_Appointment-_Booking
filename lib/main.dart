import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/background/background_sync_worker.dart';
import 'core/logging/logging_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/security/encryption_service.dart';
import 'firebase_options.dart';
import 'presentation/app.dart';

/// Entry point — initialization order matters:
/// 1. Flutter engine binding
/// 2. LoggingService initialization
/// 3. FCM background handler (must precede Firebase.initializeApp)
/// 4. Load .env
/// 5. Firebase initialization
/// 6. Global crash reporting configuration (Crashlytics)
/// 7. Workmanager background sync initialization
/// 8. EncryptionService (reads from secure storage — must run after binding)
/// 9. runApp
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Logging Service ──────────────────────────────────────────────────────────
  await LoggingService.initialize();

  // ── FCM background handler ───────────────────────────────────────────────────
  // MUST be registered before Firebase.initializeApp so the background isolate
  // entry point is set up correctly by the FCM plugin.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    LoggingService.error('Could not load .env file', error: e);
  }

  // Guard against duplicate initialization on some Android devices where the
  // google-services Gradle plugin initialises Firebase natively before Dart.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (!kIsWeb) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
    }
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('duplicate-app')) {
      LoggingService.info('[Firebase] Already initialised by native layer — continuing.');
    } else {
      LoggingService.error('[Firebase] Init error', error: e);
    }
  }

  // ── Firebase Crashlytics ──────────────────────────────────────────────────────
  // Bind global hooks to record unhandled exception logs in production
  try {
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    LoggingService.info('[Crashlytics] Global fatal exception handlers registered.');
  } catch (e) {
    LoggingService.error('[Crashlytics] Setup error', error: e);
  }

  // ── Background Sync Worker ───────────────────────────────────────────────────
  // Initialise Workmanager and schedule periodic synchronization tasks
  if (!kIsWeb) {
    await BackgroundSyncWorker.initialize();
    await BackgroundSyncWorker.schedulePeriodicSync();
  }

  // ── EncryptionService ────────────────────────────────────────────────────────
  // CRITICAL: Must be awaited before runApp. If skipped, every call to
  // EncryptionService.decrypt() throws a StateError which is silently caught
  // by the codec fallback blocks — causing notification titles and health record
  // fields to appear as raw AES ciphertext (e.g. "dGVzdA==:abc123...").
  await EncryptionService.initialize();

  runApp(const QurexaApp());
}
