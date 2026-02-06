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
    // Environment.development: 'http://10.237.190.208/api/v1',
    Environment.development: 'http://192.168.1.177/api/v1',
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
  static const String menuItems = '/menu-items'; // Fixed: hyphen not slash
  static const String menuCategories =
      '/menu-categories'; // Fixed: hyphen not slash

  // ============ ORDER ENDPOINTS ============
  static const String createOrder =
      '/orders/takeaway-order'; // Fixed: added -order
  static const String orders = '/orders';

  // ============ PAYMENT ENDPOINTS ============
  static const String calculatePricing = '/checkout/calculate-pricing';
  static const String processPayment = '/checkout/process-payment';
  static const String createPhayPay = '/payments/phajay/create';
  static const String phayPayStatus = '/payments/phajay/status';

  // ============ INVENTORY ENDPOINTS ============
  static const String inventoryItems = '/inventory/items';
  static const String stockAdjust = '/inventory/stock/adjust';
  static const String stockTransfer = '/inventory/stock/transfer';
  static const String inventoryTransactions = '/inventory/transactions';
  static const String inventoryAlerts = '/inventory/alerts';
  static const String inventoryValuation = '/inventory/valuation';
  static const String inventoryHealth = '/inventory/health';
  static const String purchaseOrders = '/inventory/purchase-orders';

  // ============ CUSTOMER ENDPOINTS ============
  static const String customers = '/crm/customers';
  static const String customerAvailablePoints =
      '/crm/customers/{customerId}/loyalty/available-points'; // Fixed path
  static const String redeemPoints =
      '/crm/customers/{customerId}/loyalty/redeem-points'; // Fixed path

  // ============ TRANSACTION ENDPOINTS ============
  static const String transactions = '/transactions';
  static const String transactionById = '/transactions/{transactionId}';
  static const String transactionSummary = '/transactions/summary';
  static const String transactionReceipt =
      '/transactions/{transactionId}/receipt';
  static const String transactionRefund =
      '/transactions/{transactionId}/refund';
  static const String transactionVoid = '/transactions/{transactionId}/void';
  static const String adjustmentsReport = '/transactions/reports/adjustments';
  static const String refundsVoidsReport =
      '/transactions/reports/refunds-voids';

  // ============ REPORT ENDPOINTS ============
  static const String dailySummary =
      '/daily-summary'; // Fixed: removed /reports prefix
  static const String endOfDay =
      '/end-of-day'; // Fixed: removed /reports prefix
  static const String salesItemsReport = '/reports/sales-items-report';
  static const String salesByEmployee = '/reports/sales-by-employee';
}
