import 'dart:js_interop';

@JS('showPwaInstallModal')
external void _showPwaInstallModal();

@JS('isPwaStandalone')
external JSBoolean? _isPwaStandalone();

@JS('isIOSDevice')
external JSBoolean? _isIOSDevice();

class PwaPlatform {
  static void showInstallPrompt() {
    try {
      _showPwaInstallModal();
    } catch (_) {}
  }

  static bool isStandalone() {
    try {
      return _isPwaStandalone()?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool isIOS() {
    try {
      return _isIOSDevice()?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }
}

