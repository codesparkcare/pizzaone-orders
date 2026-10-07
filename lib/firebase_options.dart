// File generated for Pizza One Firebase Configuration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3VXIhjiM54cn-dVrEYlG3g9BmIEHjfNA',
    appId: '1:2627187244:android:1e3edaee502486a52dd789',
    messagingSenderId: '2627187244',
    projectId: 'pizzaone-25548',
    storageBucket: 'pizzaone-25548.firebasestorage.app',
  );
}
