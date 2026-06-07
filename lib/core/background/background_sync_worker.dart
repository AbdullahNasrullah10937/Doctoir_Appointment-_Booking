import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[BackgroundSyncWorker] executeTask started: $task');
    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialise Firebase if it hasn't been already
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Record background sync telemetry log to the RTDB
        final ref = FirebaseDatabase.instance.ref('users/${user.uid}/sync_telemetry');
        await ref.update({
          'lastBackgroundSyncUtcMillis': ServerValue.timestamp,
          'taskName': task,
        }).timeout(const Duration(seconds: 10));
        debugPrint('[BackgroundSyncWorker] Telemetry sync complete for: ${user.uid}');
      } else {
        debugPrint('[BackgroundSyncWorker] No logged-in user found. Skipping sync.');
      }
    } catch (e) {
      debugPrint('[BackgroundSyncWorker] Failed to run sync task: $e');
      return false;
    }
    return true;
  });
}

class BackgroundSyncWorker {
  BackgroundSyncWorker._();

  static const String syncTaskName = 'com.example.qurexa.background_sync_task';

  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      debugPrint('[BackgroundSyncWorker] Workmanager initialised.');
    } catch (e) {
      debugPrint('[BackgroundSyncWorker] Failed to initialise: $e');
    }
  }

  static Future<void> schedulePeriodicSync() async {
    try {
      await Workmanager().registerPeriodicTask(
        'qurexa-periodic-sync-id',
        syncTaskName,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      debugPrint('[BackgroundSyncWorker] Periodic sync task registered.');
    } catch (e) {
      debugPrint('[BackgroundSyncWorker] Failed to schedule periodic task: $e');
    }
  }
}
