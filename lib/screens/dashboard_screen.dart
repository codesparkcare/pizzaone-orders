import "package:flutter/material.dart";
import "package:flutter/foundation.dart" show kIsWeb;
import "package:provider/provider.dart";
import "../core/localization/app_strings.dart";
import "../core/theme/app_theme.dart";
import "../core/utils/audio_alert_service.dart";
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling();
      _setupWebVisibilityRefresh();
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
                    auth.currentUser?.shopName ?? context.tr("orders"),
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
}
