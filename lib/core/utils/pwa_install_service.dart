import 'package:flutter/foundation.dart';
import 'pwa_install_web.dart' if (dart.library.io) 'pwa_install_stub.dart';

class PwaInstallService {
  static void promptInstall() {
    if (kIsWeb) {
      PwaPlatform.showInstallPrompt();
    }
  }

  static bool isStandalone() {
    if (kIsWeb) {
      return PwaPlatform.isStandalone();
    }
    return true; // Native apps are always standalone
  }

  static bool isIOS() {
    if (kIsWeb) {
      return PwaPlatform.isIOS();
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}

