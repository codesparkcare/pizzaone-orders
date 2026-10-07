import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../models/order_model.dart';
import 'status_badge.dart';
import '../core/localization/app_strings.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final Function(String newStatus)? onQuickStatusUpdate;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onQuickStatusUpdate,
  });

  Future<void> _makePhoneCall(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = order.isPending;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending ? AppTheme.statusPending.withValues(alpha: 0.6) : AppTheme.surfaceBorder,
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: isPending ? AppTheme.pendingGlow : AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID, Type Badge, Status Badge
                Row(
                  children: [
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (order.isDelivery ? Colors.blue : Colors.purple).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.orderTypeIcon,
                            size: 13,
                            color: order.isDelivery ? Colors.blueAccent : Colors.purpleAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.orderTypeShortLabel(lang: context.watch<SettingsProvider>().language),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: order.isDelivery ? Colors.blueAccent : Colors.purpleAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: order.statusLabel(lang: context.watch<SettingsProvider>().language),
                      color: order.statusColor,
                      icon: order.statusIcon,
                      isGlowing: isPending,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: AppTheme.surfaceBorder, height: 1),
                const SizedBox(height: 12),

                // Customer & Time Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${order.formattedTime} (${order.timeAgo})',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          if (order.shopName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.storefront_rounded, size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  order.shopName,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Total Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${order.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isPending ? AppTheme.accentGold : AppTheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          order.paymentMethod.toUpperCase(),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),

                // Address for Delivery
                if (order.isDelivery && order.customerAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openMap(order.customerAddress),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.customerAddress,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ),
                ],

                // Action Buttons Row
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Call Button
                    if (order.customerPhone.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.surfaceBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 14, color: Colors.greenAccent),
                        label: Text(order.customerPhone, style: const TextStyle(fontSize: 12)),
                        onPressed: () => _makePhoneCall(order.customerPhone),
                      ),
                    const Spacer(),

                    // Quick Action button based on state
                    if (isPending && onQuickStatusUpdate != null) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => onQuickStatusUpdate!('preparing'),
                        child: Text(context.tr('btn_accept'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ] else if (order.isPreparing && onQuickStatusUpdate != null) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusReady,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => onQuickStatusUpdate!('ready'),
                        child: Text(context.tr('btn_ready'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ] else if (order.isReady && onQuickStatusUpdate != null) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusDelivered,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => onQuickStatusUpdate!('delivered'),
                        child: Text(order.isDelivery ? context.tr('btn_delivered') : context.tr('btn_picked_up'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ] else ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.surfaceBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: onTap,
                        child: Text(context.tr('btn_view_details').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
