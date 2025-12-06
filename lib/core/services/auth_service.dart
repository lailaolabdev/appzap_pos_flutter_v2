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

  /// Verify OTP and get temp token
  Future<String> verifyOtp({required String phone, required String otp}) async {
    final response = await _apiClient.post(
      ApiConstants.verifyOtp,
      data: {'phone': phone, 'otp': otp},
    );

    final data = response['data'] ?? response;
    if (data['verified'] != true) {
      throw ApiException(
        message: data['message'] ?? 'Verification failed',
        code: 'VERIFICATION_FAILED',
      );
    }

    return data['tempToken'] as String;
  }

  /// Register new user with phone
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

  /// Login with phone and PIN
  Future<User> login({
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

    return user;
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
