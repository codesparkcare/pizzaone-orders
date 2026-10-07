import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'order_item_model.dart';

class OrderModel {
  final int id;
  final String orderType; // 'delivery' or 'collect'
  final int? shopId;
  final String shopName;
  final String shopPhone;
  final String shopAddress;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String notes;
  final String paymentMethod; // 'cash' or 'card'
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'
  final String createdAt;
  final String formattedTime;
  final String timeAgo;
  final int itemsCount;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderType,
    this.shopId,
    required this.shopName,
    this.shopPhone = '',
    this.shopAddress = '',
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.notes,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.formattedTime,
    required this.timeAgo,
    required this.itemsCount,
    required this.items,
  });

  bool get isDelivery => orderType.toLowerCase() == 'delivery';
  bool get isCollect => orderType.toLowerCase() == 'collect';

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => !isDelivered && !isCancelled;

  String get orderTypeLabel => getOrderTypeLabel();

  String getOrderTypeLabel({String lang = 'en'}) => isDelivery
      ? (lang == 'fr' ? 'Livraison à domicile' : 'Home Delivery')
      : (lang == 'fr' ? 'À emporter (Click & Collect)' : 'Takeaway (Click & Collect)');

  String orderTypeShortLabel({String lang = 'en'}) => isDelivery
      ? (lang == 'fr' ? 'Livraison' : 'Delivery')
      : (lang == 'fr' ? 'À emporter' : 'Takeaway');

  IconData get orderTypeIcon => isDelivery ? Icons.moped_rounded : Icons.shopping_bag_rounded;

  String get paymentMethodLabel => getPaymentMethodLabel();

  String getPaymentMethodLabel({String lang = 'en'}) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return lang == 'fr' ? 'Espèces (au livreur / comptoir)' : 'Cash (to driver / at counter)';
      case 'card':
        return lang == 'fr' ? 'Carte bancaire' : 'Credit Card';
      default:
        return paymentMethod.toUpperCase();
    }
  }

  String statusLabel({String lang = 'en'}) {
    switch (status) {
      case 'pending':
        return lang == 'fr' ? 'En attente' : 'Pending';
      case 'confirmed':
        return lang == 'fr' ? 'Confirmée' : 'Confirmed';
      case 'preparing':
        return lang == 'fr' ? 'En préparation' : 'In Preparation';
      case 'ready':
        return isDelivery
            ? (lang == 'fr' ? 'Prête à livrer' : 'Ready for delivery')
            : (lang == 'fr' ? 'Prête à retirer' : 'Ready for pickup');
      case 'delivered':
        return isDelivery
            ? (lang == 'fr' ? 'Livrée' : 'Delivered')
            : (lang == 'fr' ? 'Retirée' : 'Picked up');
      case 'cancelled':
        return lang == 'fr' ? 'Annulée' : 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String get statusLabelFr => statusLabel(lang: 'fr');
  String get statusLabelEn => statusLabel(lang: 'en');

  Color get statusColor {
    switch (status) {
      case 'pending':
        return AppTheme.statusPending;
      case 'confirmed':
        return AppTheme.statusConfirmed;
      case 'preparing':
        return AppTheme.statusPreparing;
      case 'ready':
        return AppTheme.statusReady;
      case 'delivered':
        return AppTheme.statusDelivered;
      case 'cancelled':
        return AppTheme.statusCancelled;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.notifications_active_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'preparing':
        return Icons.microwave_rounded;
      case 'ready':
        return isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded;
      case 'delivered':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      orderType: json['order_type'] ?? 'delivery',
      shopId: json['shop_id'] != null ? int.tryParse(json['shop_id'].toString()) : null,
      shopName: json['shop_name'] ?? 'Pizza One',
      shopPhone: json['shop_phone'] ?? '',
      shopAddress: json['shop_address'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerAddress: json['customer_address'] ?? '',
      notes: json['notes'] ?? '',
      paymentMethod: json['payment_method'] ?? 'cash',
      subtotal: json['subtotal'] is num
          ? (json['subtotal'] as num).toDouble()
          : double.tryParse(json['subtotal'].toString()) ?? 0.0,
      deliveryFee: json['delivery_fee'] is num
          ? (json['delivery_fee'] as num).toDouble()
          : double.tryParse(json['delivery_fee'].toString()) ?? 0.0,
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.tryParse(json['total_amount'].toString()) ?? 0.0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      formattedTime: json['formatted_time'] ?? '',
      timeAgo: json['time_ago'] ?? '',
      itemsCount: json['items_count'] is int
          ? json['items_count']
          : (json['items_count'] != null
              ? int.tryParse(json['items_count'].toString()) ?? parsedItems.length
              : parsedItems.length),
      items: parsedItems,
    );
  }
}
