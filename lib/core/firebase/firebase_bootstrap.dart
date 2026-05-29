import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  /// Dynamically checks if Firebase has been successfully initialized.
  /// This keeps your app state and cloud sync logic working perfectly.
  static bool get enabled => Firebase.apps.isNotEmpty;
}
