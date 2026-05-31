import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'presentation/app.dart';

/// Entry point.
/// 1. Ensures Flutter engine is ready.
/// 2. Initialises Firebase directly.
/// 3. Runs the real [QurexaApp] from presentation/app.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  // Guard against duplicate initialization.
  // Note: on some Android devices the google-services Gradle plugin initialises
  // Firebase natively before Dart starts, so Firebase.apps.isEmpty can still be
  // true in Dart while the native layer already has a [DEFAULT] app. We catch
  // the duplicate-app error and treat it as a success.
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
      // Firebase was already initialised by the native layer — safe to ignore.
      debugPrint('[Firebase] Already initialised by native layer — continuing.');
    } else {
      debugPrint('[Firebase] Init error: $e');
    }
  }

  runApp(const QurexaApp());
}
