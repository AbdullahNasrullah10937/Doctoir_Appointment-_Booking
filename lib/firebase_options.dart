// ignore_for_file: lines_longer_than_80_chars
//
// Replace this file by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Until then, update the placeholder values below to match your Firebase project
// (Project settings → Your apps). `databaseURL` must point at your Realtime Database.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSi-G6JfcsA6U8cHgJJAmdFuLLtkYXAyw',
    appId: '1:771232081967:web:11f1cc3e855eaab4a0beda',
    messagingSenderId: '771232081967',
    projectId: 'doctor-appointment--booking',
    authDomain: 'doctor-appointment--booking.firebaseapp.com',
    storageBucket: 'doctor-appointment--booking.firebasestorage.app',
    measurementId: 'G-C0ET8ZSP6D',
    databaseURL: 'https://doctor-appointment--booking-default-rtdb.firebaseio.com/', // Added this line
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDB8WqRpUWc7p4S3o0Wys768oydXWNWbI4',
    appId: '1:771232081967:android:b8893b5e9b2fae42a0beda',
    messagingSenderId: '771232081967',
    projectId: 'doctor-appointment--booking',
    storageBucket: 'doctor-appointment--booking.firebasestorage.app',
    databaseURL: 'https://doctor-appointment--booking-default-rtdb.firebaseio.com/', // Added this line
  );

  // iOS: run `flutterfire configure` after adding your app in Firebase Console
  // (Project Settings → Your apps → Add app → iOS) to get the real values.
  // The GoogleService-Info.plist must be placed inside the ios/Runner directory.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:771232081967:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '771232081967',
    projectId: 'doctor-appointment--booking',
    databaseURL: 'https://doctor-appointment--booking-default-rtdb.firebaseio.com/',
    storageBucket: 'doctor-appointment--booking.firebasestorage.app',
    iosBundleId: 'com.example.doctorBookingSystem',
  );

  static const FirebaseOptions macos = ios;

  // Windows uses the same Firebase Web SDK as Flutter Web.
  // These are the real project values — same as the `web` config above.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBSi-G6JfcsA6U8cHgJJAmdFuLLtkYXAyw',
    appId: '1:771232081967:web:11f1cc3e855eaab4a0beda',
    messagingSenderId: '771232081967',
    projectId: 'doctor-appointment--booking',
    authDomain: 'doctor-appointment--booking.firebaseapp.com',
    storageBucket: 'doctor-appointment--booking.firebasestorage.app',
    measurementId: 'G-C0ET8ZSP6D',
    databaseURL: 'https://doctor-appointment--booking-default-rtdb.firebaseio.com/',
  );
}