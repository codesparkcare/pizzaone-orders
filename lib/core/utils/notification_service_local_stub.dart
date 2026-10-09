// notification_service_local_stub.dart
// Web stub for flutter_local_notifications.
// On web, local notifications are handled by the Firebase Service Worker.
// This file is conditionally imported to prevent compilation errors on web.

import 'package:flutter/foundation.dart';

class LocalNotificationService {
  static Future<void> init(Function(String orderId)? onNotificationTapped) async {
    // No-op on web. Notifications handled by firebase-messaging-sw.js
    debugPrint('[LocalNotification Stub] Web platform – using Firebase SW instead');
  }

  static Future<void> showOrderNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // No-op on web. Background notifications shown by firebase-messaging-sw.js
    // Foreground notifications are shown via Web Notification API or audio alert.
    debugPrint('[LocalNotification Stub] Web: $title - $body');
  }
}
