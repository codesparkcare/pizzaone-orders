import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/audio_alert_service.dart';
import 'core/utils/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/order_detail_screen.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sound player service
  AudioAlertService().init();

  // Initialize Firebase Messaging in the background without blocking UI startup
  NotificationService().init(
    onOrderNotificationTapped: (orderIdStr) {
      final orderId = int.tryParse(orderIdStr);
      if (orderId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
        );
      }
    },
  );

  runApp(const PizzaOneOrderApp());
}

class PizzaOneOrderApp extends StatelessWidget {
  const PizzaOneOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Pizza One - Gestion des Commandes',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const LoginScreen(),
      ),
    );
  }
}
