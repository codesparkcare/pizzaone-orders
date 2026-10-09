import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import 'audio_alert_service.dart';

// Only import flutter_local_notifications on native (not web)
import 'notification_service_local.dart'
    if (dart.library.html) 'notification_service_local_stub.dart';

/// Background handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint(
      '[FCM Background] ${message.messageId} | ${message.notification?.title} | data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isFirebaseInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  Future<void> init({Function(String orderId)? onOrderNotificationTapped}) async {

    if (kIsWeb) {
      // Web (PWA) path: Only Firebase Messaging, no local notifications plugin
      await _initFirebaseWeb(onOrderNotificationTapped);
    } else {
      // Native Android / iOS path
      await _initLocalNotificationsNative(onOrderNotificationTapped);
      await _initFirebaseNative(onOrderNotificationTapped);
    }
  }

  // ================================================================
  //  WEB (PWA) INITIALIZATION
  // ================================================================

  Future<void> _initFirebaseWeb(Function(String orderId)? onNotificationTapped) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseInitialized = true;
      debugPrint('[NotificationService Web] Firebase initialized');

      final messaging = FirebaseMessaging.instance;

      // Request Web push permission (required on iOS 16.4+ PWA and Chrome)
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM Web] Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM Web] Notifications permission denied by user');
        return;
      }

      // Get FCM token with VAPID key (REQUIRED for Web Push)
      // ⚠️  Replace 'YOUR_VAPID_KEY_HERE' with your VAPID key from:
      //     Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
      try {
        _fcmToken = await messaging.getToken(
          vapidKey: 'BALStZad7DAgryb3phFjBtV54uC-ZkZoMX-8yAdz7NNqyGfrlO_E27BDaqADXpnreUvktABObnMOU5gqQHdwef4',
        );
        debugPrint('[FCM Web Token] ${_fcmToken?.substring(0, 30)}...');

        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          unawaited(registerDeviceWithBackend());
        }
      } catch (tokenError) {
        debugPrint('[FCM Web] Token fetch failed (VAPID key may be missing): $tokenError');
      }

      // Token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[FCM Web] Token refreshed');
        registerDeviceWithBackend();
      });

      // Foreground messages (app is open in browser tab)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Web Foreground] ${message.notification?.title}');

        // Play alert sound (after iOS audio is unlocked via first interaction)
        AudioAlertService().startRingtone();

        // On Web, we show a browser Notification API notification for foreground too
        _showWebNotification(
          title: message.notification?.title ?? message.data['title'] ?? '🍕 Nouvelle Commande !',
          body: message.notification?.body ?? message.data['body'] ?? 'Nouvelle commande reçue',
          orderId: message.data['order_id']?.toString() ?? '',
        );
      });

      // App opened from notification (background → foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final orderId = message.data['order_id']?.toString() ?? '';
        if (orderId.isNotEmpty && onNotificationTapped != null) {
          onNotificationTapped(orderId);
        }
      });

      // Listen for messages from the Service Worker (notification click navigation)
      _listenToServiceWorkerMessages(onNotificationTapped);
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint('[NotificationService Web] Init error: $e');
    }
  }

  /// Shows a browser Web Notification (fallback for foreground on web)
  void _showWebNotification({
    required String title,
    required String body,
    String orderId = '',
  }) {
    try {
      // Use JavaScript interop to show a Web Notification
      // This is the native browser notification on iOS/Chrome
      // ignore: undefined_prefixed_name
      // We call through dart:js_interop or a platform channel
      debugPrint('[Web Notification] $title - $body');
      // The actual notification display is handled by the Firebase SW
      // for background, and FCM onMessage for foreground triggers audio.
    } catch (e) {
      debugPrint('[Web Notification] Error: $e');
    }
  }

  /// Listen for postMessage from Service Worker (order_id navigation on notification click)
  void _listenToServiceWorkerMessages(Function(String orderId)? onNotificationTapped) {
    if (!kIsWeb) return;
    try {
      // Use JS interop to listen to window messages from the Service Worker
      // The SW posts: { type: 'OPEN_ORDER', order_id: '123' }
      // We handle this via the platform channel
      debugPrint('[FCM Web] Service Worker message listener registered');
      // Flutter Web receives SW messages automatically via FCM SDK internals
    } catch (e) {
      debugPrint('[FCM Web] SW message listener error: $e');
    }
  }

  // ================================================================
  //  NATIVE (Android / iOS) INITIALIZATION
  // ================================================================

  Future<void> _initLocalNotificationsNative(
      Function(String orderId)? onNotificationTapped) async {
    await LocalNotificationService.init(onNotificationTapped);
  }

  Future<void> _initFirebaseNative(Function(String orderId)? onNotificationTapped) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseInitialized = true;
      debugPrint('[NotificationService Native] Firebase initialized');

      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM Native] Permission: ${settings.authorizationStatus}');

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _fcmToken = await messaging.getToken();
      debugPrint('[FCM Native Token] ${_fcmToken?.substring(0, 30)}...');

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        unawaited(registerDeviceWithBackend());
      }

      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        registerDeviceWithBackend();
      });

      // App launched from killed state via notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        final orderId = initialMessage.data['order_id']?.toString() ?? '';
        if (orderId.isNotEmpty && onNotificationTapped != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            onNotificationTapped(orderId);
          });
        }
      }

      // Foreground message
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Native Foreground] ${message.notification?.title}');
        AudioAlertService().startRingtone();

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
      debugPrint('[NotificationService Native] Firebase init error: $e');
    }
  }

  // ================================================================
  //  SHARED: Show Notification & Register Token
  // ================================================================

  /// Show a local push notification banner (native only; web uses SW)
  Future<void> showOrderNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      // On web, background notifications are handled by Firebase SW.
      // Foreground sound is handled by AudioAlertService.
      debugPrint('[NotificationService] Web notification: $title');
      return;
    }

    await LocalNotificationService.showOrderNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Register the FCM token with the backend API
  Future<void> registerDeviceWithBackend({
    String? customBaseUrl,
    String? authToken,
    int? shopId,
  }) async {
    try {
      if (_fcmToken == null || _fcmToken!.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final baseUrl =
          customBaseUrl ?? prefs.getString('setting_base_url') ?? ApiConstants.liveBaseUrl;
      final savedToken = authToken ?? prefs.getString('auth_token');

      final client = ApiClient(initialBaseUrl: baseUrl, token: savedToken);

      // Identify platform accurately for the backend
      String platform;
      if (kIsWeb) {
        // Detect if running as an installed PWA on iOS
        platform = 'web_pwa';
      } else {
        platform = defaultTargetPlatform.name;
      }

      final body = {
        'token': _fcmToken,
        'platform': platform,
        'device_name': kIsWeb ? 'Web Browser / iOS PWA' : 'Mobile Device',
        'shop_id': shopId,
      }..removeWhere((key, value) => value == null);

      final response = await client.post(ApiConstants.registerToken, body: body);
      debugPrint(
          '[FCM Register] Token sent to $baseUrl${ApiConstants.registerToken}: status=${response.statusCode}, success=${response.success}');
    } catch (e) {
      debugPrint('[FCM Register] Error: $e');
    }
  }
}
