import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/pwa_install_service.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/order_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus to capture desktop/hardware keyboard input immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_pin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin += digit;
      });
      if (_pin.length == 6) {
        _submitPin(_pin);
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onClearPressed() {
    if (_pin.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() {
        _pin = '';
      });
    }
  }

  Future<void> _submitPin(String pinToVerify) async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final order = context.read<OrderProvider>();

    final success = await auth.loginWithPin(
      pin: pinToVerify,
      baseUrl: settings.baseUrl,
    );

    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      order.startAutoPolling(
        baseUrl: settings.baseUrl,
        token: auth.currentUser?.token,
        intervalSeconds: settings.autoRefreshSeconds,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final keyLabel = event.logicalKey.keyLabel;
      if (RegExp(r'^[0-9]$').hasMatch(keyLabel)) {
        _onDigitPressed(keyLabel);
      } else if (event.logicalKey == LogicalKeyboardKey.backspace ||
          event.logicalKey == LogicalKeyboardKey.delete) {
        _onDeletePressed();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _onClearPressed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Install App (PWA) Button (replaces former LIVE badge)
                    if (kIsWeb) ...[
                      Align(
                        alignment: Alignment.topRight,
                        child: _buildInstallPwaButton(),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      const SizedBox(height: 16),
                    ],

                    // Logo Emblem
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.surfaceElevated,
                            child: const Icon(
                              Icons.local_pizza_rounded,
                              size: 45,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Titles
                    const Text(
                      'Pizza One Restaurant',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Order Reception Portal',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message Banner
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.statusCancelled.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.statusCancelled.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.statusCancelled,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // PIN Code Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.surfaceBorder),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'PIN Access Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Enter 6-digit PIN code',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // 6 PIN Dots / Spinner
                          if (auth.isLoading)
                            const SizedBox(
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                final isFilled = index < _pin.length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutBack,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  width: isFilled ? 18 : 14,
                                  height: isFilled ? 18 : 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFilled
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isFilled
                                          ? AppTheme.primary
                                          : AppTheme.surfaceBorder,
                                      width: 2,
                                    ),
                                    boxShadow: isFilled
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),

                          const SizedBox(height: 28),

                          // Keypad (1 to 9, C, 0, Backspace)
                          Column(
                            children: [
                              _buildKeypadRow(['1', '2', '3'], auth.isLoading),
                              const SizedBox(height: 12),
                              _buildKeypadRow(['4', '5', '6'], auth.isLoading),
                              const SizedBox(height: 12),
                              _buildKeypadRow(['7', '8', '9'], auth.isLoading),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Clear Button
                                  _buildActionKey(
                                    label: 'C',
                                    icon: null,
                                    onTap: auth.isLoading ? null : _onClearPressed,
                                    color: AppTheme.textSecondary,
                                  ),
                                  // 0 Button
                                  _buildDigitKey('0', auth.isLoading),
                                  // Backspace Button
                                  _buildActionKey(
                                    label: null,
                                    icon: Icons.backspace_outlined,
                                    onTap: auth.isLoading
                                        ? null
                                        : _onDeletePressed,
                                    color: AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Default PIN info hint
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 13,
                                color: AppTheme.textMuted.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PIN Code: 812282',
                                style: TextStyle(
                                  color:
                                      AppTheme.textMuted.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Current Server Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.dns_rounded,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Server: ${settings.baseUrl}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitKey(d, isLoading)).toList(),
    );
  }

  Widget _buildDigitKey(String digit, bool isLoading) {
    return SizedBox(
      width: 68,
      height: 60,
      child: Material(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primary.withValues(alpha: 0.3),
          highlightColor: AppTheme.primary.withValues(alpha: 0.15),
          onTap: isLoading ? null : () => _onDigitPressed(digit),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    String? label,
    IconData? icon,
    VoidCallback? onTap,
    required Color color,
  }) {
    return SizedBox(
      width: 68,
      height: 60,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primary.withValues(alpha: 0.2),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, color: color, size: 22)
                : Text(
                    label ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstallPwaButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => PwaInstallService.promptInstall(),
        borderRadius: BorderRadius.circular(20),
        splashColor: AppTheme.primary.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.download_for_offline_rounded,
                size: 15,
                color: AppTheme.primary,
              ),
              SizedBox(width: 6),
              Text(
                'Install App (PWA)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
