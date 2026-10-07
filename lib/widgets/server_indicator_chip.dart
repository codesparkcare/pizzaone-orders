import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';

class ServerIndicatorChip extends StatelessWidget {
  const ServerIndicatorChip({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isLive = settings.isLiveServer;

    return GestureDetector(
      onTap: () => _showServerSwitchDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (isLive ? Colors.green : Colors.amber).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isLive ? Colors.green : Colors.amber).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isLive ? Colors.greenAccent : Colors.amberAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isLive ? 'LIVE' : 'LOCAL',
              style: TextStyle(
                color: isLive ? Colors.greenAccent : Colors.amberAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.swap_horiz_rounded,
              size: 14,
              color: isLive ? Colors.greenAccent : Colors.amberAccent,
            ),
          ],
        ),
      ),
    );
  }

  void _showServerSwitchDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final order = context.read<OrderProvider>();
    final customUrlController = TextEditingController(text: settings.baseUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Serveur de Commande',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Basculez entre le serveur en production et l\'environnement local.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Option 1: Live Server
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: settings.isLiveServer ? AppTheme.primary : AppTheme.surfaceBorder,
                    width: settings.isLiveServer ? 2 : 1,
                  ),
                ),
                tileColor: AppTheme.surfaceElevated,
                leading: const Icon(Icons.cloud_done_rounded, color: Colors.greenAccent),
                title: const Text('Serveur Live (Production)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('https://pizzaonerestaurant.com', style: TextStyle(fontSize: 12)),
                trailing: settings.isLiveServer ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                onTap: () async {
                  await settings.switchToLive();
                  if (ctx.mounted) Navigator.pop(ctx);
                  order.startAutoPolling(baseUrl: settings.baseUrl, token: auth.currentUser?.token);
                },
              ),
              const SizedBox(height: 10),

              // Option 2: Localhost
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: settings.isLocalServer ? AppTheme.primary : AppTheme.surfaceBorder,
                    width: settings.isLocalServer ? 2 : 1,
                  ),
                ),
                tileColor: AppTheme.surfaceElevated,
                leading: const Icon(Icons.computer_rounded, color: Colors.amberAccent),
                title: const Text('Serveur Local (XAMPP)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('http://localhost/pizzaone', style: TextStyle(fontSize: 12)),
                trailing: settings.isLocalServer ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                onTap: () async {
                  await settings.switchToLocal();
                  if (ctx.mounted) Navigator.pop(ctx);
                  order.startAutoPolling(baseUrl: settings.baseUrl, token: auth.currentUser?.token);
                },
              ),
              const SizedBox(height: 16),

              // Custom URL field
              TextField(
                controller: customUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL personnalisée (ex: http://192.168.1.50/pizzaone)',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (customUrlController.text.trim().isNotEmpty) {
                      await settings.setBaseUrl(customUrlController.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      order.startAutoPolling(baseUrl: settings.baseUrl, token: auth.currentUser?.token);
                    }
                  },
                  child: const Text('Enregistrer et reconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
