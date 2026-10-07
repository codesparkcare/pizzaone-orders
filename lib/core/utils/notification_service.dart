import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import 'audio_alert_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('[FCM Background Message] ${message.messageId} | ${message.notification?.title} | data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFirebaseInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  Future<void> init({Function(String orderId)? onOrderNotificationTapped}) async {
    // 1. Initialize Flutter Local Notifications
    await _initLocalNotifications(onOrderNotificationTapped);

    // 2. Initialize Firebase Messaging safely
    await _initFirebase(onOrderNotificationTapped);
  }

  Future<void> _initLocalNotifications(Function(String orderId)? onNotificationTapped) async {
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

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty && onNotificationTapped != null) {
            onNotificationTapped(payload);
          }
        },
      );

      // Create high-importance Android channel for restaurant alerts with loud custom chime
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'order_notifications',
        'Commandes Pizza One',
        description: 'Alertes sonores instantanées pour les nouvelles commandes',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('order_alert'),
        enableVibration: true,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('[NotificationService] Local notification init error: $e');
    }
  }

  Future<void> _initFirebase(Function(String orderId)? onNotificationTapped) async {
    try {
      // Check if Firebase is available
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseInitialized = true;
      debugPrint('[NotificationService] Firebase initialized successfully');

      final messaging = FirebaseMessaging.instance;

      // Request notification permissions (mandatory on Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        sound: true,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Get FCM device token
      _fcmToken = await messaging.getToken();
      debugPrint('[FCM Token] $_fcmToken');

      // Auto-register device token with active backend URL
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        unawaited(registerDeviceWithBackend());
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _fcmToken = newToken;
        registerDeviceWithBackend();
      });

      // Handle message that launched the app from KILLED state
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM Initial Message] App opened from killed state via notification: ${initialMessage.messageId}');
        final orderId = initialMessage.data['order_id']?.toString() ?? '';
        if (orderId.isNotEmpty && onNotificationTapped != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            onNotificationTapped(orderId);
          });
        }
      }

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] ${message.notification?.title}: ${message.notification?.body}');

        // Ring loud order alarm chime
        AudioAlertService().startRingtone();

        // Show local notification banner
        final notification = message.notification;
        final orderId = message.data['order_id']?.toString() ?? '';

        showOrderNotification(
          title: notification?.title ?? message.data['title'] ?? '🍕 Nouvelle Commande !',
          body: notification?.body ?? message.data['body'] ?? 'Appuyez pour consulter la commande',
          payload: orderId,
        );
      });

      // App opened from background notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final orderId = message.data['order_id']?.toString() ?? '';
        if (orderId.isNotEmpty && onNotificationTapped != null) {
          onNotificationTapped(orderId);
        }
      });
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint('[NotificationService] Firebase init error: $e');
    }
  }

  /// Register the current FCM token with the backend REST API
  Future<void> registerDeviceWithBackend({String? customBaseUrl, String? authToken, int? shopId}) async {
    try {
      if (_fcmToken == null || _fcmToken!.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final baseUrl = customBaseUrl ?? prefs.getString('setting_base_url') ?? ApiConstants.liveBaseUrl;
      final savedToken = authToken ?? prefs.getString('auth_token');

      final client = ApiClient(initialBaseUrl: baseUrl, token: savedToken);
      final body = {
        'token': _fcmToken,
        'platform': defaultTargetPlatform.name,
        'device_name': 'itel P661N (Android 13)',
        'shop_id': ?shopId,
      };

      final response = await client.post(ApiConstants.registerToken, body: body);
      debugPrint('[FCM Auto-Register] Token sent to $baseUrl/api/register_token: status=${response.statusCode}, success=${response.success}');
    } catch (e) {
      debugPrint('[FCM Auto-Register] Error: $e');
    }
  }

  Future<void> showOrderNotification({
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

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showNotification error: $e');
    }
  }
}
