// notification_service_local.dart
// Native (Android/iOS) local notification implementation.
// Conditionally imported in notification_service.dart for non-web platforms.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init(Function(String orderId)? onNotificationTapped) async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty && onNotificationTapped != null) {
            onNotificationTapped(payload);
          }
        },
      );

      // Create high-importance Android notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'order_notifications',
        'Commandes Pizza One',
        description: 'Alertes sonores instantanées pour les nouvelles commandes',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('order_alert'),
        enableVibration: true,
      );

      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);

      debugPrint('[LocalNotification] Initialized for native platform');
    } catch (e) {
      debugPrint('[LocalNotification] Init error: $e');
    }
  }

  static Future<void> showOrderNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'order_notifications',
        'Commandes Pizza One',
        channelDescription: 'Alertes sonores pour nouvelles commandes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('order_alert'),
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[LocalNotification] showNotification error: $e');
    }
  }
}
