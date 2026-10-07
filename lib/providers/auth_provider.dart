import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/utils/notification_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  static const String _keyUser = 'auth_user_data';
  static const String _keyToken = 'auth_token';
  static const String _keySavedUsername = 'auth_saved_username';
  static const String _keySavedPassword = 'auth_saved_password';

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _keepAliveTimer;
  DateTime? _lastKeepAliveCheck;
  bool _isServerConnected = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastKeepAliveCheck => _lastKeepAliveCheck;
  bool get isServerConnected => _isServerConnected;

  /// Attempt auto login on app start or resume
  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(_keyUser);
      final token = prefs.getString(_keyToken);

      if (userDataStr != null && token != null) {
        final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userData, token: token);
        notifyListeners();

        final baseUrl = prefs.getString('setting_base_url') ?? ApiConstants.liveBaseUrl;
        _registerDeviceToken(baseUrl, token);

        // Start 1-minute server heartbeat keep-alive
        _startKeepAliveTimer();
        return true;
      }

      // Fallback: If saved credentials exist, silently auto-login
      final savedUser = prefs.getString(_keySavedUsername);
      final savedPass = prefs.getString(_keySavedPassword);
      final baseUrl = prefs.getString('setting_base_url') ?? ApiConstants.liveBaseUrl;

      if (savedUser != null && savedPass != null) {
        debugPrint('[AuthProvider] Auto-restoring session from persistent credentials');
        return await login(username: savedUser, password: savedPass, baseUrl: baseUrl);
      }
    } catch (e) {
      debugPrint('[AuthProvider] tryAutoLogin error: $e');
    }
    return false;
  }

  /// Explicit user login
  Future<bool> login({
    required String username,
    required String password,
    required String baseUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final client = ApiClient(initialBaseUrl: baseUrl);
      final response = await client.post(
        ApiConstants.login,
        body: {'username': username, 'password': password},
      );

      if (response.success && response.data is Map && response.data['status'] == 'success') {
        final token = response.data['token']?.toString() ?? '';
        final userJson = response.data['user'] as Map<String, dynamic>;

        _currentUser = UserModel.fromJson(userJson, token: token);

        // Persist session and credentials permanently (never log out unless explicit)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUser, jsonEncode(_currentUser!.toJson()));
        await prefs.setString(_keyToken, token);
        await prefs.setString(_keySavedUsername, username);
        await prefs.setString(_keySavedPassword, password);

        // Register FCM device token with backend
        _registerDeviceToken(baseUrl, token);

        // Start 1-minute keep-alive ping loop
        _startKeepAliveTimer();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Identifiant ou mot de passe incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la connexion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Start the 1-minute periodic heartbeat keep-alive timer
  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkServerSession();
    });
    // Trigger initial check immediately
    unawaited(checkServerSession());
  }

  /// Check server session every minute to keep login alive and refresh device token
  Future<void> checkServerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('setting_base_url') ?? ApiConstants.liveBaseUrl;
      final fcmToken = NotificationService().fcmToken;

      // If user is null but credentials exist, restore login silently
      if (_currentUser == null) {
        final savedUser = prefs.getString(_keySavedUsername);
        final savedPass = prefs.getString(_keySavedPassword);
        if (savedUser != null && savedPass != null) {
          await login(username: savedUser, password: savedPass, baseUrl: baseUrl);
          return;
        }
      }

      final client = ApiClient(initialBaseUrl: baseUrl, token: _currentUser?.token);

      // 1. Try dedicated check_session endpoint
      final response = await client.post(
        ApiConstants.checkSession,
        body: {
          'token': _currentUser?.token ?? '',
          'username': _currentUser?.username ?? '',
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        },
      );

      if (response.success) {
        _isServerConnected = true;
        _lastKeepAliveCheck = DateTime.now();
        debugPrint('[AuthProvider] Keep-alive success (1m tick): server_time=${response.data?['server_time']}');
      } else if (response.statusCode == 404) {
        // Fallback for older server deployment: Ping dashboard / health check
        final fallback = await client.get(ApiConstants.healthCheck);
        if (fallback.success) {
          _isServerConnected = true;
          _lastKeepAliveCheck = DateTime.now();
          debugPrint('[AuthProvider] Keep-alive fallback ping success (1m tick)');
        }
      } else {
        // Network timeout / temporary error: DO NOT LOG OUT!
        _isServerConnected = false;
        debugPrint('[AuthProvider] Keep-alive network issue (status=${response.statusCode}). Keeping user logged in.');
      }

      // Re-touch FCM registration to ensure push notifications never lapse
      if (fcmToken != null && fcmToken.isNotEmpty) {
        NotificationService().registerDeviceWithBackend(
          customBaseUrl: baseUrl,
          authToken: _currentUser?.token,
          shopId: _currentUser?.shopId,
        );
      }
    } catch (e) {
      _isServerConnected = false;
      debugPrint('[AuthProvider] Keep-alive check error: $e (retaining logged in state)');
    }
  }

  /// Only explicit manual logout called from UI Settings screen
  Future<void> logout(String baseUrl) async {
    try {
      _keepAliveTimer?.cancel();
      _keepAliveTimer = null;

      // Unregister token from backend
      final fcmToken = NotificationService().fcmToken;
      if (fcmToken != null && _currentUser?.token != null) {
        final client = ApiClient(initialBaseUrl: baseUrl, token: _currentUser?.token);
        await client.post(ApiConstants.unregisterToken, body: {'token': fcmToken});
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
      await prefs.remove(_keyToken);
      await prefs.remove(_keySavedUsername);
      await prefs.remove(_keySavedPassword);

      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] logout error: $e');
    }
  }

  void _registerDeviceToken(String baseUrl, String token) {
    try {
      final fcmToken = NotificationService().fcmToken;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        final client = ApiClient(initialBaseUrl: baseUrl, token: token);
        client.post(ApiConstants.registerToken, body: {
          'token': fcmToken,
          'platform': defaultTargetPlatform.name,
          'shop_id': _currentUser?.shopId,
          'device_name': 'Pizza One Partner App',
        });
      }
    } catch (e) {
      debugPrint('[AuthProvider] registerDeviceToken error: $e');
    }
  }

  @override
  void dispose() {
    _keepAliveTimer?.cancel();
    super.dispose();
  }
}
