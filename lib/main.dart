import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'presentation/app.dart';

/// Entry point.
/// 1. Ensures Flutter engine is ready.
/// 2. Initialises Firebase directly.
/// 3. Runs the real [MediQApp] from presentation/app.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guard against duplicate initialization
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!kIsWeb) {
        // Enable disk persistence so the app works offline.
        FirebaseDatabase.instance.setPersistenceEnabled(true);
        FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
          10 * 1024 * 1024,
        );
      }
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  runApp(const MediQApp());
}
