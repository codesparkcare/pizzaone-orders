import 'dart:js_interop';

@JS('showPwaInstallModal')
external void _showPwaInstallModal();

class PwaPlatform {
  static void showInstallPrompt() {
    try {
      _showPwaInstallModal();
    } catch (_) {}
  }
}
