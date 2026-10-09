// File generated for Pizza One Firebase Configuration
// Supports: Android (native), Web (PWA/iOS Safari, Chrome)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Web platform → used for PWA on iOS Safari, Chrome, etc.
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        // Fallback to web config for unknown/desktop platforms
        return web;
    }
  }

  /// Android native app configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3VXIhjiM54cn-dVrEYlG3g9BmIEHjfNA',
    appId: '1:2627187244:android:1e3edaee502486a52dd789',
    messagingSenderId: '2627187244',
    projectId: 'pizzaone-25548',
    storageBucket: 'pizzaone-25548.firebasestorage.app',
  );

  /// Web PWA configuration (iOS Safari, Chrome, Firefox)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYZnpN0yNJbLDWSsgtlBsaMNvrvxl8eFw',
    appId: '1:2627187244:web:78c7f45b4d3651302dd789',
    messagingSenderId: '2627187244',
    projectId: 'pizzaone-25548',
    storageBucket: 'pizzaone-25548.firebasestorage.app',
    authDomain: 'pizzaone-25548.firebaseapp.com',
    measurementId: 'G-XCJMB7GCMF',
  );

  /// iOS native app configuration (if you ever build native iOS)
  /// ⚠️  IMPORTANT: Replace with your iOS GoogleService-Info.plist values
  ///    if you create an iOS app in Firebase Console.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3VXIhjiM54cn-dVrEYlG3g9BmIEHjfNA',         // ← Replace with iOS API Key
    appId: '1:2627187244:ios:REPLACE_WITH_IOS_APP_ID',            // ← Replace with iOS App ID
    messagingSenderId: '2627187244',
    projectId: 'pizzaone-25548',
    storageBucket: 'pizzaone-25548.firebasestorage.app',
    iosBundleId: 'com.pizzaone.orderapp',                          // ← Replace with your bundle ID
  );
}
