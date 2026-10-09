import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_constants.dart';
import '../core/utils/audio_alert_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyBaseUrl = 'setting_base_url';
  static const String _keySoundEnabled = 'setting_sound_enabled';
  static const String _keyRefreshInterval = 'setting_refresh_interval';
  static const String _keySelectedShop = 'setting_selected_shop_id';

  String _baseUrl = ApiConstants.defaultBaseUrl;
  bool _soundEnabled = true;
  int _autoRefreshSeconds = 15;
  int? _selectedShopId;
  bool _isInitialized = false;

  String get baseUrl => _baseUrl;
  bool get soundEnabled => _soundEnabled;
  int get autoRefreshSeconds => _autoRefreshSeconds;
  int? get selectedShopId => _selectedShopId;
  String get language => 'en';
  bool get isEnglish => true;
  bool get isFrench => false;
  bool get isInitialized => _isInitialized;

  bool get isLiveServer => _baseUrl.contains('pizzaonerestaurant.com');
  bool get isLocalServer => _baseUrl.contains('localhost') || _baseUrl.contains('127.0.0.1') || _baseUrl.contains('10.0.2.2') || _baseUrl.contains('192.168.');

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString(_keyBaseUrl) ?? ApiConstants.defaultBaseUrl;
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      _autoRefreshSeconds = prefs.getInt(_keyRefreshInterval) ?? 15;
      _selectedShopId = prefs.getInt(_keySelectedShop);

      AudioAlertService().setMuted(!_soundEnabled);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[SettingsProvider] loadSettings error: $e');
    }
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _baseUrl);
    notifyListeners();
  }

  Future<void> switchToLive() async {
    await setBaseUrl(ApiConstants.liveBaseUrl);
  }

  Future<void> switchToLocal() async {
    await setBaseUrl(ApiConstants.localBaseUrl);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    AudioAlertService().setMuted(!enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, _soundEnabled);
    notifyListeners();
  }

  Future<void> setAutoRefreshSeconds(int seconds) async {
    _autoRefreshSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRefreshInterval, _autoRefreshSeconds);
    notifyListeners();
  }

  Future<void> setSelectedShopId(int? shopId) async {
    _selectedShopId = shopId;
    final prefs = await SharedPreferences.getInstance();
    if (shopId == null) {
      await prefs.remove(_keySelectedShop);
    } else {
      await prefs.setInt(_keySelectedShop, shopId);
    }
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    // English only mode
  }

  Future<void> toggleLanguage() async {
    // English only mode
  }
}