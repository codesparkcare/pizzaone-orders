// wake_lock_service_native.dart
// Native (Android/iOS) stub for Wake Lock.
// On native Android, you can add 'wakelock_plus' to pubspec.yaml for full support.
// For now this is a no-op stub.

import 'package:flutter/foundation.dart';

class WakeLockPlatform {
  static Future<bool> enable() async {
    debugPrint('[WakeLock Native] Native wake lock not implemented. Add wakelock_plus package for Android support.');
    return false;
  }

  static Future<void> disable() async {
    // no-op
  }
}
