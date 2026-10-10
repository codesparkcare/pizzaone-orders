import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/utils/audio_alert_service.dart';
import '../core/utils/notification_service.dart';
import '../models/order_model.dart';
import '../models/shop_model.dart';

class OrderProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  List<ShopModel> _shops = [];
  Map<String, int> _counts = {
    'pending': 0,
    'confirmed': 0,
    'preparing': 0,
    'ready': 0,
    'delivered': 0,
    'cancelled': 0,
  };
  Map<String, dynamic> _dashboardStats = {
    'today_orders_count': 0,
    'today_revenue': 0.0,
    'active_pending': 0,
  };

  bool _isLoading = false;
  String? _errorMessage;
  String _statusFilter = 'all'; // 'all', 'pending', 'preparing', 'ready', 'delivered', 'cancelled'
  String _searchQuery = '';
  int? _shopFilter;

  Timer? _pollingTimer;
  Set<int> _knownPendingOrderIds = {};
  bool _hasActiveAlert = false;

  List<OrderModel> get orders {
    var filtered = _orders;

    if (_statusFilter == 'all') {
      // In "All" tab: show only active / new orders (pending, confirmed, preparing, ready)
      // Delivered orders move to the "Delivered" tab!
      filtered = filtered.where((o) => !o.isDelivered && !o.isCancelled).toList();
    } else if (_statusFilter == 'preparing') {
      // "In Kitchen" tab includes both confirmed and preparing
      filtered = filtered.where((o) => o.isConfirmed || o.isPreparing).toList();
    } else if (_statusFilter != 'all') {
      filtered = filtered.where((o) => o.status == _statusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((o) {
        return o.id.toString().contains(q) ||
            o.customerName.toLowerCase().contains(q) ||
            o.customerPhone.contains(q) ||
            o.customerAddress.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  List<ShopModel> get shops => _shops;
  Map<String, int> get counts => _counts;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  int? get shopFilter => _shopFilter;
  bool get hasActiveAlert => _hasActiveAlert;

  int get pendingCount => _counts['pending'] ?? 0;
  int get preparingCount => (_counts['confirmed'] ?? 0) + (_counts['preparing'] ?? 0);
  int get readyCount => _counts['ready'] ?? 0;
  int get deliveredCount => _counts['delivered'] ?? 0;
  int get cancelledCount => _counts['cancelled'] ?? 0;
  int get activeOrdersCount => pendingCount + preparingCount + readyCount;

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setShopFilter(int? shopId) {
    _shopFilter = shopId;
    notifyListeners();
  }

  void dismissActiveAlert() {
    _hasActiveAlert = false;
    AudioAlertService().stopRingtone();
    notifyListeners();
  }

  /// Start real-time polling timer
  void startAutoPolling({
    required String baseUrl,
    String? token,
    int intervalSeconds = 15,
  }) {
    stopAutoPolling();
    debugPrint('[OrderProvider] Auto polling started every ${intervalSeconds}s on $baseUrl');

    // Initial fetch
    fetchOrders(baseUrl: baseUrl, token: token, silent: false);
    fetchShops(baseUrl: baseUrl, token: token);
    fetchDashboard(baseUrl: baseUrl, token: token);

    _pollingTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      fetchOrders(baseUrl: baseUrl, token: token, silent: true);
      fetchDashboard(baseUrl: baseUrl, token: token);
    });
  }

  void stopAutoPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    AudioAlertService().stopRingtone();
  }

  /// Fetch orders list with active filters
  Future<void> fetchOrders({
    required String baseUrl,
    String? token,
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final client = ApiClient(initialBaseUrl: baseUrl, token: token);
      final queryParams = <String, String>{};

      if (_statusFilter != 'all') {
        queryParams['status'] = _statusFilter;
      }
      if (_shopFilter != null) {
        queryParams['shop_id'] = _shopFilter.toString();
      }

      final response = await client.get(ApiConstants.orders, queryParams: queryParams);

      if (response.success && response.data is Map) {
        final List rawOrders = response.data['orders'] ?? [];
        final parsedOrders = rawOrders.map((json) => OrderModel.fromJson(json)).toList();

        // Check for new pending orders
        _checkForNewPendingOrders(parsedOrders);

        _orders = parsedOrders;

        if (response.data['counts'] is Map) {
          final rawCounts = response.data['counts'] as Map;
          _counts = rawCounts.map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0));
        }

        _errorMessage = null;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des commandes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Detect new incoming orders and trigger alarm
  void _checkForNewPendingOrders(List<OrderModel> freshOrders) {
    final pendingTotal = _counts['pending'] ?? 0;
    if (pendingTotal == 0) {
      _hasActiveAlert = false;
      AudioAlertService().stopRingtone();
      _knownPendingOrderIds.clear();
      return;
    }

    // Only update ID tracking if we are viewing a filter that contains pending orders
    if (_statusFilter == 'all' || _statusFilter == 'pending') {
      final currentPending = freshOrders.where((o) => o.isPending).map((o) => o.id).toSet();
      final newOrders = currentPending.difference(_knownPendingOrderIds);

      if (newOrders.isNotEmpty) {
        debugPrint('[OrderProvider] NEW PENDING ORDERS DETECTED: $newOrders');
        _hasActiveAlert = true;

        // Start continuous ringing chime
        AudioAlertService().startRingtone();

        // Show local push banner
        NotificationService().showOrderNotification(
          title: '🍕 NEW ORDER RECEIVED!',
          body: '${newOrders.length} order(s) awaiting confirmation.',
          payload: newOrders.first.toString(),
        );
      }
      _knownPendingOrderIds = currentPending;
    }
  }

  /// Fetch active shops
  Future<void> fetchShops({required String baseUrl, String? token}) async {
    try {
      final client = ApiClient(initialBaseUrl: baseUrl, token: token);
      final response = await client.get(ApiConstants.shops);

      if (response.success && response.data is Map && response.data['shops'] is List) {
        final List rawShops = response.data['shops'];
        _shops = rawShops.map((s) => ShopModel.fromJson(s)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[OrderProvider] fetchShops error: $e');
    }
  }

  /// Fetch dashboard counters
  Future<void> fetchDashboard({required String baseUrl, String? token}) async {
    try {
      final client = ApiClient(initialBaseUrl: baseUrl, token: token);
      final queryParams = <String, String>{};
      if (_shopFilter != null) {
        queryParams['shop_id'] = _shopFilter.toString();
      }

      final response = await client.get(ApiConstants.dashboard, queryParams: queryParams);

      if (response.success && response.data is Map && response.data['stats'] is Map) {
        _dashboardStats = Map<String, dynamic>.from(response.data['stats']);
        if (_dashboardStats['status_counts'] is Map) {
          final rawCounts = _dashboardStats['status_counts'] as Map;
          _counts = rawCounts.map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[OrderProvider] fetchDashboard error: $e');
    }
  }

  /// Update an order's status
  Future<bool> updateOrderStatus({
    required int orderId,
    required String newStatus,
    String? note,
    required String baseUrl,
    String? token,
  }) async {
    try {
      final client = ApiClient(initialBaseUrl: baseUrl, token: token);
      final response = await client.post(
        ApiConstants.updateOrderStatus(orderId),
        body: {'status': newStatus, 'note': note ?? ''},
      );

      if (response.success) {
        // Optimistic / fast local update
        final idx = _orders.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          final old = _orders[idx];
          final previousStatus = old.status;
          _orders[idx] = OrderModel(
            id: old.id,
            orderType: old.orderType,
            shopId: old.shopId,
            shopName: old.shopName,
            shopPhone: old.shopPhone,
            shopAddress: old.shopAddress,
            customerName: old.customerName,
            customerPhone: old.customerPhone,
            customerAddress: old.customerAddress,
            notes: note != null && note.isNotEmpty ? '${old.notes}\n$note' : old.notes,
            paymentMethod: old.paymentMethod,
            subtotal: old.subtotal,
            deliveryFee: old.deliveryFee,
            totalAmount: old.totalAmount,
            status: newStatus,
            createdAt: old.createdAt,
            formattedTime: old.formattedTime,
            timeAgo: old.timeAgo,
            itemsCount: old.itemsCount,
            items: old.items,
          );

          // Update counts locally immediately
          if (_counts.containsKey(previousStatus) && (_counts[previousStatus] ?? 0) > 0) {
            _counts[previousStatus] = _counts[previousStatus]! - 1;
          }
          _counts[newStatus] = (_counts[newStatus] ?? 0) + 1;
        }

        // Re-check pending orders
        _knownPendingOrderIds.remove(orderId);
        if ((_counts['pending'] ?? 0) == 0) {
          _hasActiveAlert = false;
          AudioAlertService().stopRingtone();
        }

        notifyListeners();

        // Refresh latest numbers and sync with server
        fetchDashboard(baseUrl: baseUrl, token: token);
        fetchOrders(baseUrl: baseUrl, token: token, silent: true);
        return true;
      }
    } catch (e) {
      debugPrint('[OrderProvider] updateOrderStatus error: $e');
    }
    return false;
  }

  @override
  void dispose() {
    stopAutoPolling();
    super.dispose();
  }
}
