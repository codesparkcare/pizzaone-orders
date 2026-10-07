import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/status_badge.dart';
import 'receipt_preview_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClient(initialBaseUrl: settings.baseUrl, token: auth.currentUser?.token);
      final response = await client.get(ApiConstants.orderDetails(widget.orderId));

      if (response.success && response.data is Map && response.data['order'] != null) {
        setState(() {
          _order = OrderModel.fromJson(response.data['order']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty ? response.message : 'Commande introuvable';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus, {String? note}) async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    final success = await orderProvider.updateOrderStatus(
      orderId: widget.orderId,
      newStatus: newStatus,
      note: note,
      baseUrl: settings.baseUrl,
      token: auth.currentUser?.token,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour : ${newStatus.toUpperCase()}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadOrderDetails();
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('sms:$cleaned');
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: Text('Commande #${widget.orderId}')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: Text('Commande #${widget.orderId}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.statusCancelled),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Erreur', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrderDetails,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Commande #${order.id}'),
        actions: [
          // Print / Preview Receipt Button
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Ticket de caisse',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(order: order)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Type Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (order.isDelivery ? Colors.blue : Colors.purple).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      order.orderTypeIcon,
                      size: 26,
                      color: order.isDelivery ? Colors.blueAccent : Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderTypeLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Commandé le ${order.formattedTime} (${order.timeAgo})',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        if (order.shopName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Boutique : ${order.shopName}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: order.statusLabelFr,
                    color: order.statusColor,
                    icon: order.statusIcon,
                    isGlowing: order.isPending,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Information Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_rounded, size: 18, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'Informations Client',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 14),

                  // Name
                  Row(
                    children: [
                      const SizedBox(
                        width: 90,
                        child: Text('Nom :', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Phone
                  Row(
                    children: [
                      const SizedBox(
                        width: 90,
                        child: Text('Téléphone :', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(
                          order.customerPhone,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone_rounded, color: Colors.greenAccent, size: 20),
                        tooltip: 'Appeler',
                        onPressed: () => _makePhoneCall(order.customerPhone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sms_rounded, color: Colors.blueAccent, size: 20),
                        tooltip: 'SMS',
                        onPressed: () => _sendSms(order.customerPhone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Address
                  if (order.isDelivery && order.customerAddress.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 90,
                          child: Text('Adresse :', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ),
                        Expanded(
                          child: Text(
                            order.customerAddress,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.map_rounded, color: AppTheme.primary, size: 20),
                          tooltip: 'Ouvrir dans Google Maps',
                          onPressed: () => _openMap(order.customerAddress),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Notes / Instructions
                  if (order.notes.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 90,
                          child: Text('Notes :', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.notes,
                              style: const TextStyle(color: AppTheme.accentGold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Items Card
            Container(
              padding: const EdgeInsets.all(18),
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
                      const Icon(Icons.local_pizza_rounded, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Articles Commandés',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${order.items.length} produit(s)',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 14),

                  if (order.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Détail des articles non disponible pour cette commande historique.',
                        style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      separatorBuilder: (context, index) => const Divider(color: AppTheme.surfaceBorder, height: 16),
                      itemBuilder: (ctx, i) {
                        final item = order.items[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.size.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Taille: ${item.size}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                  if (item.addons.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: item.addons
                                          .map((a) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surfaceElevated,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '+ $a',
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.accentGold),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                  if (item.instructions.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note: ${item.instructions}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '€${item.itemTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Financial Breakdown Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payments_rounded, size: 18, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'Total & Paiement',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Moyen de paiement :', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.paymentMethodLabel,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sous-total :', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Text('€${order.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    ],
                  ),
                  if (order.isDelivery) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Frais de livraison :', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text('€${order.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL À ENCAISSER :',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '€${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons Workflow Bar
            _buildActionButtons(order),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    if (order.isPending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.statusCancelled,
                side: const BorderSide(color: AppTheme.statusCancelled),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _confirmCancelDialog(),
              child: const Text('REFUSER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('ACCEPTER LA COMMANDE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              onPressed: () => _updateStatus('preparing'),
            ),
          ),
        ],
      );
    }

    if (order.isPreparing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.statusReady,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.done_all_rounded, size: 22),
          label: Text(
            order.isDelivery ? 'COMMANDE PRÊTE POUR LE LIVREUR' : 'COMMANDE PRÊTE AU COMPTOIR',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          onPressed: () => _updateStatus('ready'),
        ),
      );
    }

    if (order.isReady) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.statusDelivered,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.task_alt_rounded, size: 22),
          label: Text(
            order.isDelivery ? 'CONFIRMER COMMANDE LIVRÉE' : 'CONFIRMER RETRAIT CLIENT',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          onPressed: () => _updateStatus('delivered'),
        ),
      );
    }

    return Center(
      child: Text(
        'Commande terminée (${order.statusLabelFr})',
        style: const TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic),
      ),
    );
  }

  void _confirmCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Refuser la commande ?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette commande ? Cette action est irréversible.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non, retour', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCancelled),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus('cancelled', note: 'Refusée par le restaurant');
            },
            child: const Text('Oui, refuser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
