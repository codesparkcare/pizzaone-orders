import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class AppStrings {
  static const String defaultLanguage = 'en';

  static const Map<String, Map<String, String>> _values = {
    'en': {
      // App & Common
      'app_name': 'PIZZA ONE',
      'app_subtitle': 'Order Management',
      'orders': 'Orders',
      'all_shops': 'All Stores',
      'search_hint': 'Search customer, phone, #id...',
      'live': 'LIVE',
      'local': 'LOCAL',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'error': 'Error',
      'loading': 'Loading...',
      'refresh': 'Refresh',

      // Dashboard Metrics
      'stat_today': 'Today',
      'stat_today_orders': '{count} orders',
      'stat_revenue': "Today's Revenue",
      'stat_pending': 'Pending',

      // Filter Tabs
      'filter_all': 'All',
      'filter_pending': 'Pending',
      'filter_kitchen': 'In Kitchen',
      'filter_ready': 'Ready',
      'filter_delivered': 'Delivered',
      'filter_cancelled': 'Cancelled',

      // Audio Alarm Banner
      'alarm_new_orders': 'new orders waiting for confirmation!',
      'alarm_view': 'View',
      'alarm_dismiss': 'Dismiss',

      // Order Types
      'type_delivery': 'Delivery',
      'type_delivery_home': 'Home Delivery',
      'type_takeaway': 'Takeaway',
      'type_takeaway_pickup': 'Takeaway (Click & Collect)',

      // Payment
      'pay_cash': 'Cash',
      'pay_cash_detail': 'Cash (to driver / at counter)',
      'pay_card': 'Credit Card',

      // Statuses
      'status_pending': 'Pending',
      'status_confirmed': 'Confirmed',
      'status_preparing': 'In Preparation',
      'status_ready': 'Ready',
      'status_ready_delivery': 'Ready for delivery',
      'status_ready_pickup': 'Ready for pickup',
      'status_delivered': 'Delivered',
      'status_picked_up': 'Picked up',
      'status_cancelled': 'Cancelled',

      // Action Buttons
      'btn_accept': 'ACCEPT',
      'btn_ready': 'READY !',
      'btn_delivered': 'DELIVERED',
      'btn_picked_up': 'PICKED UP',
      'btn_view_details': 'View Details',
      'btn_call': 'Call',

      // Empty State
      'empty_orders_title': 'No orders in this category',
      'empty_orders_subtitle': 'Pull down to refresh or check other filters',

      // Order Details Screen
      'order_details_title': 'Order #{id}',
      'section_customer': 'Customer Information',
      'section_delivery_address': 'Delivery Address',
      'section_items': 'Ordered Items',
      'section_instructions': 'Customer Instructions',
      'section_payment': 'Payment Breakdown',
      'subtotal': 'Subtotal',
      'delivery_fee': 'Delivery Fee',
      'total': 'Total',
      'notes_empty': 'No special instructions provided.',
      'btn_print_receipt': 'Print Receipt',
      'btn_start_prep': 'Start Preparation',
      'btn_mark_ready': 'Mark as Ready',
      'btn_mark_delivered': 'Mark as Delivered',
      'btn_cancel_order': 'Cancel Order',
      'dialog_confirm_status': 'Confirm status change to {status}?',

      // Settings Screen
      'settings_title': 'Settings',
      'lang_section': 'Language',
      'lang_en': 'English',
      'lang_fr': 'Français',
      'sound_section': 'Audio Notifications',
      'sound_title': 'Order Sound Alert',
      'sound_desc': 'Play looping sound alert when new orders arrive',
      'sound_test': 'Test Alarm Sound',
      'sound_stop': 'Stop Sound',
      'push_section': 'Push Notifications (FCM)',
      'push_test': 'Test Push Notification',
      'push_test_success': 'Test notification triggered!',
      'server_section': 'Server Connection',
      'server_live': 'Live Server (Production)',
      'server_local': 'Local Server (Development)',
      'server_custom': 'Custom API URL',
      'server_url_hint': 'https://pizzaonerestaurant.com',
      'btn_save': 'Save',
      'refresh_interval_title': 'Auto-refresh Interval',
      'refresh_seconds': '{sec} seconds',
      'account_section': 'Logged in Account',
      'btn_logout': 'Logout',
      'logout_confirm': 'Are you sure you want to log out?',

      // Login Screen
      'login_title': 'Staff Login',
      'login_subtitle': 'Enter your credentials to access the kitchen terminal',
      'username': 'Username',
      'password': 'Password',
      'btn_login': 'Sign In',
      'login_invalid': 'Invalid username or password',
    },

    'fr': {
      // App & Common
      'app_name': 'PIZZA ONE',
      'app_subtitle': 'Gestion des Commandes',
      'orders': 'Commandes',
      'all_shops': 'Toutes boutiques',
      'search_hint': 'Rechercher client, tél, n°...',
      'live': 'LIVE',
      'local': 'LOCAL',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'error': 'Erreur',
      'loading': 'Chargement...',
      'refresh': 'Actualiser',

      // Dashboard Metrics
      'stat_today': "Aujourd'hui",
      'stat_today_orders': '{count} cdes',
      'stat_revenue': 'Recette du jour',
      'stat_pending': 'En attente',

      // Filter Tabs
      'filter_all': 'Toutes',
      'filter_pending': 'En attente',
      'filter_kitchen': 'En cuisine',
      'filter_ready': 'Prêtes',
      'filter_delivered': 'Livrées',
      'filter_cancelled': 'Annulées',

      // Audio Alarm Banner
      'alarm_new_orders': 'nouvelles commandes en attente de confirmation !',
      'alarm_view': 'Voir',
      'alarm_dismiss': 'Masquer',

      // Order Types
      'type_delivery': 'Livraison',
      'type_delivery_home': 'Livraison à domicile',
      'type_takeaway': 'À emporter',
      'type_takeaway_pickup': 'À emporter (Click & Collect)',

      // Payment
      'pay_cash': 'Espèces',
      'pay_cash_detail': 'Espèces (au livreur / comptoir)',
      'pay_card': 'Carte bancaire',

      // Statuses
      'status_pending': 'En attente',
      'status_confirmed': 'Confirmée',
      'status_preparing': 'En préparation',
      'status_ready': 'Prête',
      'status_ready_delivery': 'Prête à livrer',
      'status_ready_pickup': 'Prête à retirer',
      'status_delivered': 'Livrée',
      'status_picked_up': 'Retirée',
      'status_cancelled': 'Annulée',

      // Action Buttons
      'btn_accept': 'ACCEPTER',
      'btn_ready': 'PRÊTE !',
      'btn_delivered': 'LIVRÉE',
      'btn_picked_up': 'RETIRÉE',
      'btn_view_details': 'Voir détails',
      'btn_call': 'Appeler',

      // Empty State
      'empty_orders_title': 'Aucune commande dans cette catégorie',
      'empty_orders_subtitle': 'Tirez vers le bas pour actualiser',

      // Order Details Screen
      'order_details_title': 'Commande #{id}',
      'section_customer': 'Informations client',
      'section_delivery_address': 'Adresse de livraison',
      'section_items': 'Articles commandés',
      'section_instructions': 'Instructions / Notes du client',
      'section_payment': 'Détail du paiement',
      'subtotal': 'Sous-total',
      'delivery_fee': 'Frais de livraison',
      'total': 'Total',
      'notes_empty': 'Aucune instruction particulière.',
      'btn_print_receipt': 'Imprimer le ticket',
      'btn_start_prep': 'Mettre en préparation',
      'btn_mark_ready': 'Marquer comme prête',
      'btn_mark_delivered': 'Marquer comme livrée',
      'btn_cancel_order': 'Annuler la commande',
      'dialog_confirm_status': 'Confirmer le passage à {status} ?',

      // Settings Screen
      'settings_title': 'Paramètres',
      'lang_section': 'Langue',
      'lang_en': 'English',
      'lang_fr': 'Français',
      'sound_section': 'Alertes sonores',
      'sound_title': 'Sonnerie de commande',
      'sound_desc': 'Sonnerie en boucle pour toute nouvelle commande',
      'sound_test': 'Tester la sonnerie',
      'sound_stop': 'Arrêter le son',
      'push_section': 'Notifications Push (FCM)',
      'push_test': 'Tester la notification push',
      'push_test_success': 'Notification de test déclenchée !',
      'server_section': 'Connexion serveur',
      'server_live': 'Serveur Live (Production)',
      'server_local': 'Serveur Local (Développement)',
      'server_custom': 'URL API personnalisée',
      'server_url_hint': 'https://pizzaonerestaurant.com',
      'btn_save': 'Enregistrer',
      'refresh_interval_title': "Intervalle d'actualisation",
      'refresh_seconds': '{sec} secondes',
      'account_section': 'Compte connecté',
      'btn_logout': 'Déconnexion',
      'logout_confirm': 'Voulez-vous vraiment vous déconnecter ?',

      // Login Screen
      'login_title': 'Connexion Staff',
      'login_subtitle': 'Entrez vos identifiants pour accéder aux commandes',
      'username': "Nom d'utilisateur",
      'password': 'Mot de passe',
      'btn_login': 'Se connecter',
      'login_invalid': 'Identifiants invalides',
    },
  };

  static String tr(String key, {String lang = defaultLanguage, Map<String, String>? params}) {
    String text = _values[lang]?[key] ?? _values['en']?[key] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramVal) {
        text = text.replaceAll('{$paramKey}', paramVal);
      });
    }
    return text;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key, {Map<String, String>? params}) {
    final lang = watch<SettingsProvider>().language;
    return AppStrings.tr(key, lang: lang, params: params);
  }

  String trRead(String key, {Map<String, String>? params}) {
    final lang = read<SettingsProvider>().language;
    return AppStrings.tr(key, lang: lang, params: params);
  }
}
