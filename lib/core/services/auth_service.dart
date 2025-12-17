import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';
import 'storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(apiClient, storageService);
});

/// Authentication service for handling user auth
class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService(this._apiClient, this._storageService);

  /// Send OTP for registration or verification
  Future<void> sendOtp({
    required String phone,
    String userType = 'staff',
    String purpose = 'registration',
  }) async {
    await _apiClient.post(
      ApiConstants.sendOtp,
      data: {'phone': phone, 'userType': userType, 'purpose': purpose},
    );
  }

  /// Verify OTP - Smart Response (Handles both login AND registration)
  /// 
  /// This method handles two scenarios:
  /// 1. Existing user → Returns user + tokens (logged in immediately!)
  /// 2. New user → Returns registrationToken (needs to complete registration)
  /// 
  /// Returns OTPVerificationResult with different data based on user status.
  Future<OTPVerificationResult> verifyOtpAndLogin({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.verifyOtp,
      data: {'phone': phone, 'otp': otp},
    );

    final data = response['data'] ?? response;

    // Check if OTP was verified successfully
    if (data['verified'] != true) {
      throw ApiException(
        message: data['message'] ?? 'Invalid OTP',
        code: data['code'] ?? 'INVALID_OTP',
        statusCode: 400,
      );
    }

    // SCENARIO 1: Existing User - Login
    if (data['isRegistered'] == true) {
      final userData = data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      // Save tokens
      final tokens = data['tokens'] as Map<String, dynamic>;
      await _storageService.saveTokens(
        accessToken: tokens['access']['token'] as String,
        refreshToken: tokens['refresh']['token'] as String,
      );

      // Save user data
      await _storageService.saveUserData(user);

      // Save branch and restaurant IDs
      if (user.restaurant != null) {
        await _storageService.saveRestaurantId(user.restaurant!.id);
      }
      if (user.branch != null) {
        await _storageService.saveBranchId(user.branch!.id);
      }

      return OTPVerificationResult.loggedIn(
        user: user,
        hasPIN: data['hasPIN'] as bool? ?? false,
      );
    } 
    // SCENARIO 2: New User - Registration Required
    else {
      return OTPVerificationResult.registrationRequired(
        registrationToken: data['registrationToken'] as String,
        phone: data['phone'] as String,
      );
    }
  }

  /// Complete registration for new users (Self-service!)
  /// 
  /// This is called after OTP verification returns registrationToken.
  /// Creates restaurant, branch, and owner account automatically.
  /// 
  /// Only 3 required fields: registrationToken, name, restaurantName
  /// PIN is optional for faster future logins.
  Future<AuthResult> registerWithPhone({
    required String registrationToken,
    required String name,
    required String restaurantName,
    String? pin,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.registerWithPhone,
      data: {
        'registrationToken': registrationToken,
        'name': name,
        'restaurantName': restaurantName,
        if (pin != null) 'pin': pin,
      },
    );

    final data = response['data'] ?? response;

    if (data['success'] == true && data['registered'] == true) {
      final userData = data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      // Save tokens
      final tokens = data['tokens'] as Map<String, dynamic>;
      await _storageService.saveTokens(
        accessToken: tokens['access']['token'] as String,
        refreshToken: tokens['refresh']['token'] as String,
      );

      // Save user data
      await _storageService.saveUserData(user);

      // Save branch and restaurant IDs
      if (user.restaurant != null) {
        await _storageService.saveRestaurantId(user.restaurant!.id);
      }
      if (user.branch != null) {
        await _storageService.saveBranchId(user.branch!.id);
      }

      return AuthResult(
        user: user,
        hasPIN: pin != null,
      );
    }

    throw ApiException(
      message: data['message'] ?? 'Registration failed',
      code: 'REGISTRATION_FAILED',
      statusCode: 400,
    );
  }

  /// Legacy method for backward compatibility (DEPRECATED)
  /// Use verifyOtpAndLogin() for complete authentication instead
  @Deprecated('Use verifyOtpAndLogin() instead')
  Future<String> verifyOtp({required String phone, required String otp}) async {
    // This now throws error for unregistered users
    // Use the new flow with OTPVerificationResult
    await verifyOtpAndLogin(phone: phone, otp: otp);
    return ''; // Return empty string for legacy code
  }

  /// Register new user with phone (DEPRECATED - Admin flow)
  /// Use registerWithPhone() for self-service registration instead
  @Deprecated('Use registerWithPhone() for self-service registration')
  Future<User> register({
    required String tempToken,
    required String phone,
    required String name,
    required String pin,
    required String restaurantId,
    String? branchId,
    String role = 'cashier',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      data: {
        'tempToken': tempToken,
        'phone': phone,
        'name': name,
        'pin': pin,
        'restaurantId': restaurantId,
        if (branchId != null) 'branchId': branchId,
        'role': role,
      },
    );

    final userData = response['user'] as Map<String, dynamic>;
    final user = User.fromJson(userData);

    // Save tokens
    final tokens = response['tokens'] as Map<String, dynamic>;
    await _storageService.saveTokens(
      accessToken: tokens['access']['token'] as String,
      refreshToken: tokens['refresh']['token'] as String,
    );

    // Save user data
    await _storageService.saveUserData(user);

    // Save branch and restaurant IDs
    if (user.restaurant != null) {
      await _storageService.saveRestaurantId(user.restaurant!.id);
    }
    if (user.branch != null) {
      await _storageService.saveBranchId(user.branch!.id);
    }

    return user;
  }

  /// Login with phone and PIN (Fast login for daily use)
  Future<AuthResult> loginWithPIN({
    required String phone,
    required String pin,
    String userType = 'staff',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {'phone': phone, 'pin': pin, 'userType': userType},
    );

    final userData = response['user'] as Map<String, dynamic>;
    final user = User.fromJson(userData);

    // Save tokens
    final tokens = response['tokens'] as Map<String, dynamic>;
    await _storageService.saveTokens(
      accessToken: tokens['access']['token'] as String,
      refreshToken: tokens['refresh']['token'] as String,
    );

    // Save user data
    await _storageService.saveUserData(user);

    // Save branch and restaurant IDs
    if (user.restaurant != null) {
      await _storageService.saveRestaurantId(user.restaurant!.id);
    }
    if (user.branch != null) {
      await _storageService.saveBranchId(user.branch!.id);
    }

    return AuthResult(
      user: user,
      hasPIN: true, // User logged in with PIN, so they have one
    );
  }

  /// Legacy method for backward compatibility (DEPRECATED)
  /// Use loginWithPIN() instead
  @Deprecated('Use loginWithPIN() instead')
  Future<User> login({
    required String phone,
    required String pin,
    String userType = 'staff',
  }) async {
    final result = await loginWithPIN(
      phone: phone,
      pin: pin,
      userType: userType,
    );
    return result.user;
  }

  /// Setup PIN (Optional - for faster future logins)
  /// Can be called after OTP login to setup PIN for convenience
  Future<void> setupPIN({required String pin, String? oldPin}) async {
    await _apiClient.post(
      ApiConstants.setupPin,
      data: {
        'pin': pin,
        if (oldPin != null) 'oldPin': oldPin,
      },
    );
  }

  /// Request forgot PIN OTP
  Future<void> forgotPin({
    required String phone,
    String userType = 'staff',
  }) async {
    await _apiClient.post(
      ApiConstants.forgotPin,
      data: {'phone': phone, 'userType': userType},
    );
  }

  /// Reset PIN with OTP
  Future<void> resetPin({
    required String phone,
    required String otp,
    required String newPin,
    String userType = 'staff',
  }) async {
    await _apiClient.post(
      ApiConstants.resetPin,
      data: {
        'phone': phone,
        'otp': otp,
        'newPin': newPin,
        'userType': userType,
      },
    );
  }

  /// Change PIN (authenticated)
  Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    await _apiClient.post(
      ApiConstants.setupPin,
      data: {'oldPin': oldPin, 'pin': newPin},
    );
  }

  /// Get current user from storage
  Future<User?> getCurrentUser() async {
    return await _storageService.getUserData();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.hasTokens();
  }

  /// Get current branch ID
  Future<String?> getBranchId() async {
    return await _storageService.getBranchId();
  }

  /// Get current restaurant ID
  Future<String?> getRestaurantId() async {
    return await _storageService.getRestaurantId();
  }

  /// Logout user
  Future<void> logout() async {
    await _storageService.clearAll();
  }

  /// Send OTP for login purpose (simplified)
  Future<void> sendOtpForLogin(String phone) async {
    await sendOtp(phone: phone, purpose: 'login');
  }

  /// Refresh tokens
  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiClient.post(
        ApiConstants.refreshTokens,
        data: {'refreshToken': refreshToken},
      );

      final tokens = response['tokens'] as Map<String, dynamic>;
      await _storageService.saveTokens(
        accessToken: tokens['access']['token'] as String,
        refreshToken: tokens['refresh']['token'] as String,
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Authentication result containing user and authentication state
class AuthResult {
  /// The authenticated user
  final User user;

  /// Whether the user has PIN set up
  final bool hasPIN;

  const AuthResult({
    required this.user,
    this.hasPIN = false,
  });

  @override
  String toString() {
    return 'AuthResult(user: ${user.name}, hasPIN: $hasPIN)';
  }
}

/// OTP Verification result - Union type for login or registration flow
/// 
/// This class represents two possible outcomes after OTP verification:
/// 1. User is registered → Returns user + tokens (logged in!)
/// 2. User is NOT registered → Returns registrationToken (needs registration)
class OTPVerificationResult {
  /// Whether the user is already registered
  final bool isRegistered;

  /// User data (only for registered users)
  final User? user;

  /// Whether user has PIN set up (only for registered users)
  final bool? hasPIN;

  /// Registration token for completing signup (only for new users)
  final String? registrationToken;

  /// Phone number (only for new users)
  final String? phone;

  OTPVerificationResult._({
    required this.isRegistered,
    this.user,
    this.hasPIN,
    this.registrationToken,
    this.phone,
  });

  /// Factory for logged in user (existing user scenario)
  factory OTPVerificationResult.loggedIn({
    required User user,
    required bool hasPIN,
  }) {
    return OTPVerificationResult._(
      isRegistered: true,
      user: user,
      hasPIN: hasPIN,
    );
  }

  /// Factory for registration required (new user scenario)
  factory OTPVerificationResult.registrationRequired({
    required String registrationToken,
    required String phone,
  }) {
    return OTPVerificationResult._(
      isRegistered: false,
      registrationToken: registrationToken,
      phone: phone,
    );
  }

  @override
  String toString() {
    if (isRegistered) {
      return 'OTPVerificationResult.loggedIn(user: ${user?.name}, hasPIN: $hasPIN)';
    } else {
      return 'OTPVerificationResult.registrationRequired(phone: $phone)';
    }
  }
}
