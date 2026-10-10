import "package:flutter/material.dart";
import "package:flutter/foundation.dart" show kIsWeb;
import "package:provider/provider.dart";
import "../core/api/api_client.dart";
import "../core/api/api_constants.dart";
import "../core/localization/app_strings.dart";
import "../core/theme/app_theme.dart";
import "../core/utils/audio_alert_service.dart";
import "../core/utils/notification_service.dart";
import "../core/utils/pwa_install_service.dart";
import "../core/utils/wake_lock_service.dart";
import "../providers/auth_provider.dart";
import "../providers/settings_provider.dart";
import "../providers/order_provider.dart";
import "../widgets/audio_alarm_banner.dart";
import "../widgets/order_card.dart";
import "../widgets/order_filter_bar.dart";
import "../widgets/summary_stat_card.dart";
import "order_detail_screen.dart";
import "settings_screen.dart";

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  final _wakeLock = WakeLockService();
  bool _wakeLockEnabled = false;
  bool _notificationPermissionGranted = NotificationService().hasPermission;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling();
      _setupWebVisibilityRefresh();
      if (mounted) {
        setState(() {
          _notificationPermissionGranted = NotificationService().hasPermission;
        });
      }
    });
  }

  /// On iOS PWA, when user returns to the app after it was in background,
  /// trigger an immediate refresh so orders are up-to-date.
  void _setupWebVisibilityRefresh() {
    if (!kIsWeb) return;
    // Mark audio as unlocked on first user interaction (iOS Safari requirement)
    // This is handled in index.html JS, but we also mark it in Dart:
    // AudioAlertService will check this before playing
    AudioAlertService().markWebAudioUnlocked();
  }

  void _startPolling() {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final order = context.read<OrderProvider>();

    order.startAutoPolling(
      baseUrl: settings.baseUrl,
      token: auth.currentUser?.token,
      intervalSeconds: settings.autoRefreshSeconds,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final order = context.read<OrderProvider>();

    await Future.wait([
      order.fetchOrders(baseUrl: settings.baseUrl, token: auth.currentUser?.token, silent: false),
      order.fetchDashboard(baseUrl: settings.baseUrl, token: auth.currentUser?.token),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();

    final pendingCount = order.counts["pending"] ?? 0;
    final todayRevenue = (order.dashboardStats["today_revenue"] != null)
        ? (order.dashboardStats["today_revenue"] as num).toDouble()
        : 0.0;
    final todayOrdersCount = order.dashboardStats["today_orders_count"] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 10,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.primaryGlow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  "assets/images/logo.png",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.local_pizza_rounded, color: AppTheme.primary, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "PIZZA ONE",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    ((auth.currentUser?.shopName ?? '').toLowerCase().contains('toutes') ||
                            (auth.currentUser?.shopName ?? '').isEmpty)
                        ? 'All Stores'
                        : auth.currentUser!.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Push Notification Bell Status & Test
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: Icon(
              _notificationPermissionGranted ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              color: _notificationPermissionGranted ? Colors.greenAccent : Colors.amberAccent,
              size: 20,
            ),
            tooltip: _notificationPermissionGranted
                ? "Notifications Active (tap for test push)"
                : "Notifications Disabled (tap to enable)",
            onPressed: () {
              if (_notificationPermissionGranted) {
                _sendTestNotification(context);
              } else {
                _enableNotifications(context);
              }
            },
          ),

          // Screen Wake Lock (iOS PWA Kitchen Mode - keeps screen on)
          if (kIsWeb)
            IconButton(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              icon: Icon(
                _wakeLockEnabled ? Icons.brightness_high_rounded : Icons.brightness_low_rounded,
                color: _wakeLockEnabled ? Colors.amberAccent : AppTheme.textMuted,
                size: 20,
              ),
              tooltip: _wakeLockEnabled ? "Screen Stay-On: ON" : "Screen Stay-On: OFF",
              onPressed: () async {
                // Capture messenger before async gap (BuildContext safety)
                final messenger = ScaffoldMessenger.of(context);
                final enabled = await _wakeLock.toggle();
                if (mounted) setState(() => _wakeLockEnabled = enabled);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(enabled
                        ? '🔆 Screen will stay on (Kitchen Mode)'
                        : '😴 Screen auto-sleep restored'),
                    backgroundColor: enabled ? Colors.amber.shade800 : AppTheme.surfaceElevated,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

          // Mute / Sound Toggle
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: Icon(
              settings.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: settings.soundEnabled ? AppTheme.accentGold : AppTheme.textMuted,
              size: 20,
            ),
            tooltip: settings.soundEnabled ? "Sound enabled" : "Sound muted",
            onPressed: () => settings.setSoundEnabled(!settings.soundEnabled),
          ),

          // Refresh Button
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: context.tr("refresh"),
            onPressed: _refreshOrders,
          ),

          // Settings Button
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: context.tr("settings_title"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Audio Alarm Banner if pending orders are ringing
          if (order.hasActiveAlert && pendingCount > 0)
            AudioAlarmBanner(
              count: pendingCount,
              onDismiss: () => order.dismissActiveAlert(),
              onViewPending: () {
                order.dismissActiveAlert();
                order.setStatusFilter("pending");
              },
            ),

          // iOS Web Push Notification Enable Banner (shown if permissions not granted)
          if (kIsWeb && !_notificationPermissionGranted)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.22),
                    Colors.orange.shade900.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Notifications Disabled',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tap ENABLE to allow iPhone sound & lock-screen alerts',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _isRequestingPermission ? null : () => _enableNotifications(context),
                    child: _isRequestingPermission
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('ENABLE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Top Metrics Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SummaryStatCard(
                  title: context.tr("stat_today"),
                  value: context.tr("stat_today_orders", params: {"count": todayOrdersCount.toString()}),
                  icon: Icons.receipt_long_rounded,
                  accentColor: Colors.blueAccent,
                  onTap: () => order.setStatusFilter("all"),
                ),
                const SizedBox(width: 8),
                SummaryStatCard(
                  title: context.tr("stat_revenue"),
                  value: "€${todayRevenue.toStringAsFixed(2)}",
                  icon: Icons.payments_rounded,
                  accentColor: Colors.greenAccent,
                ),
                const SizedBox(width: 8),
                SummaryStatCard(
                  title: context.tr("stat_pending"),
                  value: "$pendingCount",
                  icon: Icons.notifications_active_rounded,
                  accentColor: AppTheme.statusPending,
                  onTap: () => order.setStatusFilter("pending"),
                ),
              ],
            ),
          ),

          // Search Bar & Shop Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Search Input
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: context.tr("search_hint"),
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  order.setSearchQuery("");
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onChanged: (val) => order.setSearchQuery(val),
                    ),
                  ),
                ),

                // Shop selector dropdown (if shops are loaded and user is superadmin)
                if (order.shops.isNotEmpty && (auth.currentUser?.isSuperAdmin ?? true)) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: order.shopFilter,
                        dropdownColor: AppTheme.surfaceElevated,
                        icon: const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primary),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                        hint: Text(context.tr("all_shops"), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(context.tr("all_shops"), style: const TextStyle(fontSize: 12)),
                          ),
                          ...order.shops.map((s) => DropdownMenuItem<int?>(
                                value: s.id,
                                child: Text(s.name, style: const TextStyle(fontSize: 12)),
                              )),
                        ],
                        onChanged: (id) {
                          order.setShopFilter(id);
                          order.fetchOrders(baseUrl: settings.baseUrl, token: auth.currentUser?.token);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status Filter Tabs
          OrderFilterBar(
            activeFilter: order.statusFilter,
            counts: order.counts,
            onFilterSelected: (newFilter) {
              order.setStatusFilter(newFilter);
              order.fetchOrders(baseUrl: settings.baseUrl, token: auth.currentUser?.token);
            },
          ),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surfaceElevated,
              onRefresh: _refreshOrders,
              child: _buildOrdersList(order, settings, auth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(OrderProvider order, SettingsProvider settings, AuthProvider auth) {
    if (order.isLoading && order.orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (order.errorMessage != null && order.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                order.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.tr("refresh")),
                onPressed: _refreshOrders,
              ),
            ],
          ),
        ),
      );
    }

    final filteredOrders = order.orders;

    if (filteredOrders.isEmpty) {
      final isAllFilter = order.statusFilter == 'all';
      final hasDelivered = order.deliveredCount > 0;

      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAllFilter ? Icons.check_circle_outline_rounded : Icons.inventory_2_outlined,
                    size: 48,
                    color: isAllFilter ? AppTheme.statusDelivered : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isAllFilter
                      ? (settings.isEnglish ? 'No Active Orders' : 'Aucune commande en cours')
                      : context.tr('empty_orders_title'),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAllFilter
                      ? (settings.isEnglish
                          ? 'New incoming orders will appear here automatically.'
                          : 'Les nouvelles commandes apparaîtront ici automatiquement.')
                      : context.tr('empty_orders_subtitle'),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                if (isAllFilter && hasDelivered) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceElevated,
                      foregroundColor: AppTheme.statusDelivered,
                      side: BorderSide(color: AppTheme.statusDelivered.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.moped_rounded, size: 18),
                    label: Text(
                      settings.isEnglish
                          ? 'View Delivered Orders (${order.deliveredCount})'
                          : 'Voir les commandes livrées (${order.deliveredCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      order.setStatusFilter('delivered');
                      order.fetchOrders(baseUrl: settings.baseUrl, token: auth.currentUser?.token);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: filteredOrders.length,
      itemBuilder: (ctx, index) {
        final item = filteredOrders[index];
        return OrderCard(
          order: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: item.id)),
            );
          },
          onQuickStatusUpdate: (newStatus) {
            order.updateOrderStatus(
              orderId: item.id,
              newStatus: newStatus,
              baseUrl: settings.baseUrl,
              token: auth.currentUser?.token,
            );
          },
        );
      },
    );
  }

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
                color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.install_mobile_rounded, color: Color(0xFFFF5722), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add to Home Screen Required',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'On iPhone, push notifications and lock-screen sound alerts only work when Pizza One is added to your Home Screen.\n\n1. Tap the Share button (or 3 dots in Chrome)\n2. Select "Add to Home Screen"\n3. Open Pizza One from your Home Screen & tap Enable',
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
                  backgroundColor: const Color(0xFFFF5722),
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

  Future<void> _enableNotifications(BuildContext context) async {
    if (_isRequestingPermission) return;

    if (kIsWeb && PwaInstallService.isIOS() && !PwaInstallService.isStandalone()) {
      _showIosInstallGuide(context);
      return;
    }

    setState(() => _isRequestingPermission = true);

    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Direct user tap satisfies iOS Safari / WebKit User Gesture requirement
    final granted = await NotificationService().requestPermissionAndRegister(
      customBaseUrl: settings.baseUrl,
      authToken: auth.currentUser?.token,
      shopId: auth.currentUser?.shopId,
    );

    if (mounted) {
      setState(() {
        _isRequestingPermission = false;
        _notificationPermissionGranted = granted;
      });
    }

    if (granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('🔔 Notifications enabled! Sending test notification...'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Trigger a test notification immediately so the user sees the iOS push banner
      try {
        final client = ApiClient(initialBaseUrl: settings.baseUrl, token: auth.currentUser?.token);
        await client.get(ApiConstants.testNotification);
      } catch (_) {}
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            NotificationService().lastError ??
                '⚠️ Notification permission was not granted. Please check device Settings > Notifications > Pizza One.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Sending test push to this device...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final client = ApiClient(initialBaseUrl: settings.baseUrl, token: auth.currentUser?.token);
      final res = await client.get(ApiConstants.testNotification);
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.success
              ? (res.message.isNotEmpty ? res.message : 'Test notification sent to registered devices!')
              : (res.message.isNotEmpty ? res.message : 'Failed to send test push')),
          backgroundColor: res.success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error sending test push: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
