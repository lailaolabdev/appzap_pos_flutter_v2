/// API Constants for AppZap POS
class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String productionBaseUrl = 'https://api.appzap.la/api/v1';
  static const String stagingBaseUrl = 'https://staging-api.appzap.la/api/v1';

  // WebSocket URLs
  static const String productionWsUrl = 'wss://ws.appzap.la';
  static const String stagingWsUrl = 'wss://staging-ws.appzap.la';

  // Current environment (change for production)
  static const bool isProduction = false;

  static String get baseUrl =>
      isProduction ? productionBaseUrl : stagingBaseUrl;
  static String get wsUrl => isProduction ? productionWsUrl : stagingWsUrl;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String sendOtp = '/auth/phone/send-otp';
  static const String verifyOtp = '/auth/phone/verify-otp';
  static const String register = '/auth/phone/register';
  static const String login = '/auth/phone/login';
  static const String forgotPin = '/auth/phone/forgot-pin';
  static const String resetPin = '/auth/phone/reset-pin';
  static const String setupPin = '/auth/phone/setup-pin';
  static const String refreshTokens = '/auth/refresh-tokens';

  // Product Endpoints
  static const String menuItems = '/menu/items';
  static const String menuCategories = '/menu/categories';

  // Order Endpoints
  static const String createOrder = '/orders/takeaway';
  static const String orders = '/orders';

  // Payment Endpoints
  static const String calculatePricing = '/checkout/calculate-pricing';
  static const String processPayment = '/checkout/process-payment';
  static const String createPhayPay = '/payments/phajay/create';
  static const String phayPayStatus = '/payments/phajay/status';

  // Inventory Endpoints
  static const String inventoryItems = '/inventory/items';
  static const String stockAdjust = '/inventory/stock/adjust';
  static const String inventoryAlerts = '/inventory/alerts';
  static const String purchaseOrders = '/inventory/purchase-orders';
  static const String inventoryValuation = '/inventory/valuation';

  // Customer Endpoints
  static const String customers = '/crm/customers';
  static const String customerPoints = '/crm/customers/{customerId}/points';
  static const String redeemPoints = '/crm/loyalty-program/redeem';

  // Report Endpoints
  static const String dailySummary = '/reports/daily-summary';
  static const String endOfDay = '/reports/end-of-day';
  static const String salesItemsReport = '/reports/sales-items-report';
  static const String salesByEmployee = '/reports/sales-by-employee';
}
