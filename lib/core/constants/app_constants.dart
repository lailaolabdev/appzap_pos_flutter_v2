/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'AppZap POS';
  static const String appVersion = '1.0.0';
  static const String defaultCurrency = 'LAK';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String branchIdKey = 'branch_id';
  static const String restaurantIdKey = 'restaurant_id';
  static const String pinEnabledKey = 'pin_enabled';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String lastSyncKey = 'last_sync';
  static const String offlineModeKey = 'offline_mode';

  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 500;

  // OTP
  static const int otpLength = 6;
  static const int otpExpirySeconds = 300;
  static const int maxOtpAttempts = 3;

  // PIN
  static const int pinLength = 4;
  static const int maxPinLength = 6;

  // PhayPay
  static const Duration phayPayPollInterval = Duration(seconds: 3);
  static const Duration phayPayTimeout = Duration(minutes: 10);

  // Sync
  static const Duration autoSyncInterval = Duration(minutes: 5);
  static const Duration syncRetryDelay = Duration(seconds: 30);

  // Cart
  static const int maxCartItems = 100;
  static const double maxDiscountPercent = 100;

  // Image
  static const double productImageSize = 200;
  static const double thumbnailSize = 80;
}
