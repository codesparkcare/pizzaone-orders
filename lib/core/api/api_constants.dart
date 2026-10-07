class ApiConstants {
  // Base URLs
  static const String liveBaseUrl = 'https://pizzaonerestaurant.com';
  static const String localBaseUrl = 'http://localhost/pizzaone';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2/pizzaone';

  // Default active base URL (can be customized in settings)
  static const String defaultBaseUrl = liveBaseUrl;

  // Endpoints
  static const String healthCheck = '/api';
  static const String login = '/api/login';
  static const String dashboard = '/api/dashboard';
  static const String orders = '/api/orders';
  static const String shops = '/api/shops';
  static const String registerToken = '/api/register_token';
  static const String unregisterToken = '/api/unregister_token';
  static const String testNotification = '/api/test_notification';
  static const String checkSession = '/api/check_session';

  static String orderDetails(int id) => '/api/orders/$id';
  static String updateOrderStatus(int id) => '/api/orders/$id/status';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
