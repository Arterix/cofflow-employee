class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String fcmToken = '/auth/fcm-token';

  // Menu (public)
  static const String menus = '/menus';
  static const String categories = '/categories';
  static String menuDetail(int id) => '/menus/$id';

  // Orders
  static const String createOrder = '/orders';
  static String cancelOrder(int id) => '/orders/$id';
  static String orderPaymentStatus(int id) => '/orders/$id/payment-status';

  // Staff orders
  static const String staffOrders = '/staff/orders';
  static String staffOrderDetail(int id) => '/staff/orders/$id';
  static String updateOrderStatus(int id) => '/staff/orders/$id/status';

  // Queue
  static const String queueActive = '/queue/active';
  static const String queueEstimate = '/queue/estimate';
}
