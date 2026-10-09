// wake_lock_service.dart
// Cross-platform Wake Lock Service.
// On web (iOS PWA, Chrome): uses Screen Wake Lock API via JavaScript interop.
// On native: no-op stub (can be extended with wakelock_plus package).

import 'package:flutter/foundation.dart';

import 'wake_lock_service_web.dart'
    if (dart.library.io) 'wake_lock_service_native.dart';

class WakeLockService {
  static final WakeLockService _instance = WakeLockService._internal();
  factory WakeLockService() => _instance;
  WakeLockService._internal();

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;
  bool get isSupported => kIsWeb;

  /// Enable wake lock (keep screen on)
  Future<bool> enable() async {
    try {
      final success = await WakeLockPlatform.enable();
      _isEnabled = success;
      if (success) {
        debugPrint('[WakeLock] Screen wake lock enabled ✅');
      } else {
        debugPrint('[WakeLock] Screen wake lock not supported or failed');
      }
      return success;
    } catch (e) {
      debugPrint('[WakeLock] Enable error: $e');
      _isEnabled = false;
      return false;
    }
  }

  /// Disable wake lock (allow screen to sleep normally)
  Future<void> disable() async {
    try {
      await WakeLockPlatform.disable();
      _isEnabled = false;
      debugPrint('[WakeLock] Screen wake lock disabled');
    } catch (e) {
      debugPrint('[WakeLock] Disable error: $e');
    }
  }

  /// Toggle wake lock on/off
  Future<bool> toggle() async {
    if (_isEnabled) {
      await disable();
      return false;
    } else {
      return await enable();
    }
  }
}
