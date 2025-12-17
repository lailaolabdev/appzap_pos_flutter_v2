/// Environment enum for API configuration
enum Environment { development, staging, production }

/// API Constants for AppZap POS
class ApiConstants {
  ApiConstants._();

  // ============ ENVIRONMENT CONFIGURATION ============
  // Change this to switch environments
  static const Environment currentEnvironment = Environment.development;

  // Base URLs by environment
  static const Map<Environment, String> _baseUrls = {
    Environment.development: 'http://localhost/api/v1',
    Environment.staging: 'https://api-v2.appzap.la:9090/api/v1',
    Environment.production: 'https://api-v2.appzap.la/api/v1',
  };

  // WebSocket URLs by environment
  static const Map<Environment, String> _wsUrls = {
    Environment.development: 'http://localhost:3001',
    Environment.staging: 'https://ws.appzap.la',
    Environment.production: 'https://ws.appzap.la',
  };

  // Get current base URL
  static String get baseUrl => _baseUrls[currentEnvironment]!;

  // Get current WebSocket URL
  static String get wsUrl => _wsUrls[currentEnvironment]!;

  // Environment checks
  static bool get isProduction => currentEnvironment == Environment.production;
  static bool get isStaging => currentEnvironment == Environment.staging;
  static bool get isDevelopment =>
      currentEnvironment == Environment.development;

  // ============ TIMEOUTS ============
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ============ AUTH ENDPOINTS ============
  static const String sendOtp = '/auth/phone/send-otp';
  static const String verifyOtp = '/auth/phone/verify-otp';
  static const String register =
      '/auth/phone/register'; // Legacy admin registration
  static const String registerWithPhone =
      '/auth/phone/register'; // Self-service registration
  static const String login = '/auth/phone/login';
  static const String forgotPin = '/auth/phone/forgot-pin';
  static const String resetPin = '/auth/phone/reset-pin';
  static const String setupPin = '/auth/phone/setup-pin';
  static const String refreshTokens = '/auth/refresh-tokens';

  // ============ PRODUCT ENDPOINTS ============
  static const String menuItems = '/menu/items';
  static const String menuCategories = '/menu/categories';

  // ============ ORDER ENDPOINTS ============
  static const String createOrder = '/orders/takeaway';
  static const String orders = '/orders';

  // ============ PAYMENT ENDPOINTS ============
  static const String calculatePricing = '/checkout/calculate-pricing';
  static const String processPayment = '/checkout/process-payment';
  static const String createPhayPay = '/payments/phajay/create';
  static const String phayPayStatus = '/payments/phajay/status';

  // ============ INVENTORY ENDPOINTS ============
  static const String inventoryItems = '/inventory/items';
  static const String stockAdjust = '/inventory/stock/adjust';
  static const String inventoryAlerts = '/inventory/alerts';
  static const String purchaseOrders = '/inventory/purchase-orders';
  static const String inventoryValuation = '/inventory/valuation';

  // ============ CUSTOMER ENDPOINTS ============
  static const String customers = '/crm/customers';
  static const String customerPoints = '/crm/customers/{customerId}/points';
  static const String redeemPoints = '/crm/loyalty-program/redeem';

  // ============ REPORT ENDPOINTS ============
  static const String dailySummary = '/reports/daily-summary';
  static const String endOfDay = '/reports/end-of-day';
  static const String salesItemsReport = '/reports/sales-items-report';
  static const String salesByEmployee = '/reports/sales-by-employee';
}
