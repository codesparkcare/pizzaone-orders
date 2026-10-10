import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/audio_alert_service.dart';
import '../core/utils/notification_service.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/order_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/utils/pwa_install_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isTestingPush = false;

  void _showIosInstallGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E212A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.install_mobile_rounded, color: AppTheme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add to Home Screen Required',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'On iPhone, push notifications only work when Pizza One is added to your Home Screen.\n\n1. Tap the Share button in Safari or Chrome\n2. Select "Add to Home Screen"\n3. Open Pizza One from your Home Screen & tap Enable',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  PwaInstallService.promptInstall();
                },
                icon: const Icon(Icons.touch_app_rounded),
                label: const Text('View Installation Steps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testPushNotification() async {
    setState(() => _isTestingPush = true);
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();

    try {
      final client = ApiClient(initialBaseUrl: settings.baseUrl, token: auth.currentUser?.token);
      final response = await client.get(ApiConstants.testNotification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.success
                ? (response.message.isNotEmpty ? response.message : 'Test notification sent to registered devices!')
                : (response.message.isNotEmpty ? response.message : 'Failed to send test notification')),
            backgroundColor: response.success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingPush = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final order = context.watch<OrderProvider>();
    final notif = NotificationService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          if (auth.currentUser != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser!.username.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Role: ${auth.currentUser!.role} • ${(auth.currentUser!.shopName == 'Toutes les boutiques' || auth.currentUser!.shopName.isEmpty) ? 'All Stores' : auth.currentUser!.shopName}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.statusCancelled),
                    tooltip: 'Logout',
                    onPressed: () => _confirmLogout(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Section 2: Sound & Alerts
          _buildSectionHeader('SOUND & ALERTS'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.soundEnabled,
                  activeThumbColor: AppTheme.primary,
                  title: const Text(
                    'New order ringtone',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Plays continuous chime alert until the order is accepted',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  secondary: Icon(
                    settings.soundEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                    color: settings.soundEnabled ? AppTheme.accentGold : AppTheme.textMuted,
                  ),
                  onChanged: (val) => settings.setSoundEnabled(val),
                ),
                const Divider(color: AppTheme.surfaceBorder, height: 1),
                ListTile(
                  title: const Text('Test chime alert', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Listen to the Pizza One alert chime', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  trailing: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Test'),
                    onPressed: () {
                      AudioAlertService().playSingleChime();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Auto-Refresh / Realtime Polling
          _buildSectionHeader('AUTO-REFRESH INTERVAL'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded, color: AppTheme.primary, size: 20),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Check new orders every:',
                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: settings.autoRefreshSeconds,
                  dropdownColor: AppTheme.surfaceElevated,
                  style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10 sec')),
                    DropdownMenuItem(value: 15, child: Text('15 sec')),
                    DropdownMenuItem(value: 30, child: Text('30 sec')),
                    DropdownMenuItem(value: 60, child: Text('60 sec')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      settings.setAutoRefreshSeconds(val);
                      order.startAutoPolling(
                        baseUrl: settings.baseUrl,
                        token: auth.currentUser?.token,
                        intervalSeconds: val,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 4: Firebase Push Notification Status
          _buildSectionHeader('FIREBASE CLOUD MESSAGING (PUSH)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      notif.isFirebaseInitialized ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: notif.isFirebaseInitialized ? Colors.greenAccent : AppTheme.accentGold,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      notif.isFirebaseInitialized ? 'FCM Active' : 'FCM Pending Setup',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: notif.isFirebaseInitialized ? Colors.greenAccent : AppTheme.accentGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Firebase Project: Pizzaone (pizzaone-25548)\nBackground push notifications when screen is locked.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
                if (notif.fcmToken != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Token: ${notif.fcmToken}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Copy FCM token',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: notif.fcmToken!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('FCM token copied!'), backgroundColor: Colors.green),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                if (notif.fcmToken == null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.notifications_active_rounded, size: 18),
                      label: const Text('Enable Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        if (kIsWeb && PwaInstallService.isIOS() && !PwaInstallService.isStandalone()) {
                          _showIosInstallGuide(context);
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final granted = await notif.requestPermissionAndRegister(
                          customBaseUrl: settings.baseUrl,
                          authToken: auth.currentUser?.token,
                          shopId: auth.currentUser?.shopId,
                        );
                        if (mounted) {
                          setState(() {});
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(granted
                                  ? 'Notifications enabled! Push token registered.'
                                  : (notif.lastError ??
                                      'Permission not granted. Please check device Settings > Notifications > Pizza One.')),
                              backgroundColor: granted ? Colors.green : Colors.red,
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isTestingPush
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send test push notification'),
                    onPressed: _isTestingPush ? null : _testPushNotification,
                  ),
                ),
              ],
            ),
          ),

          if (kIsWeb) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('APPLICATION INSTALLATION (PWA)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.install_mobile_rounded, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Install App on Device',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Add to Home Screen for fast kitchen mode',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Install Pizza One App (PWA)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        PwaInstallService.promptInstall();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusCancelled.withValues(alpha: 0.15),
                foregroundColor: AppTheme.statusCancelled,
                elevation: 0,
                side: const BorderSide(color: AppTheme.statusCancelled),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _confirmLogout(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  void _confirmLogout() {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final order = context.read<OrderProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Logout', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Are you sure you want to log out of the order management app?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCancelled),
            onPressed: () async {
              Navigator.pop(ctx);
              order.stopAutoPolling();
              await auth.logout(settings.baseUrl);
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
