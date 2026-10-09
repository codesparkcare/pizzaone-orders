import 'package:flutter/foundation.dart';
import 'pwa_install_web.dart' if (dart.library.io) 'pwa_install_stub.dart';

class PwaInstallService {
  static void promptInstall() {
    if (kIsWeb) {
      PwaPlatform.showInstallPrompt();
    }
  }
}
