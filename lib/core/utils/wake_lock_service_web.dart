// wake_lock_service_web.dart
// Web implementation of Wake Lock using dart:js_interop (modern API).
// Calls window.pizzaWakeLock defined in index.html
//
// Uses dart:js_interop which is the current recommended way (no deprecations).

import 'package:flutter/foundation.dart';
import 'dart:js_interop';

// Define external JS interface for pizzaWakeLock
@JS('pizzaWakeLock')
external _PizzaWakeLockJS get _pizzaWakeLock;

extension type _PizzaWakeLockJS._(JSObject _) implements JSObject {
  external JSBoolean isSupported();
  external JSBoolean isEnabled();
  external JSObject enable();
  external void disable();
}

class WakeLockPlatform {
  /// Enable screen wake lock via the JS API defined in index.html
  static Future<bool> enable() async {
    if (!kIsWeb) return false;
    try {
      // Check support
      final isSupported = _pizzaWakeLock.isSupported().toDart;
      if (!isSupported) {
        debugPrint('[WakeLock Web] Screen Wake Lock API not supported (needs HTTPS + iOS 16.4+/Chrome)');
        return false;
      }

      // Call enable() – async JS promise, fire and forget
      _pizzaWakeLock.enable();
      debugPrint('[WakeLock Web] Wake lock enable() called');
      return true;
    } catch (e) {
      debugPrint('[WakeLock Web] enable error: $e');
      return false;
    }
  }

  /// Disable screen wake lock
  static Future<void> disable() async {
    if (!kIsWeb) return;
    try {
      _pizzaWakeLock.disable();
    } catch (e) {
      debugPrint('[WakeLock Web] disable error: $e');
    }
  }
}
