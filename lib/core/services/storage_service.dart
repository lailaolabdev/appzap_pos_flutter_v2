import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../models/user.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Secure storage service for sensitive data
class StorageService {
  final FlutterSecureStorage _secureStorage;

  StorageService()
    : _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  // ============ TOKEN MANAGEMENT ============

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(
        key: AppConstants.accessTokenKey,
        value: accessToken,
      ),
      _secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: refreshToken,
      ),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  /// Check if user has valid tokens
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: AppConstants.accessTokenKey),
      _secureStorage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  // ============ USER DATA ============

  /// Save user data
  Future<void> saveUserData(User user) async {
    final jsonString = jsonEncode(user.toJson());
    await _secureStorage.write(
      key: AppConstants.userDataKey,
      value: jsonString,
    );
  }

  /// Get user data
  Future<User?> getUserData() async {
    final jsonString = await _secureStorage.read(key: AppConstants.userDataKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Clear user data
  Future<void> clearUserData() async {
    await _secureStorage.delete(key: AppConstants.userDataKey);
  }

  // ============ BRANCH/RESTAURANT ============

  /// Save current branch ID
  Future<void> saveBranchId(String branchId) async {
    await _secureStorage.write(key: AppConstants.branchIdKey, value: branchId);
  }

  /// Get current branch ID
  Future<String?> getBranchId() async {
    return await _secureStorage.read(key: AppConstants.branchIdKey);
  }

  /// Save current restaurant ID
  Future<void> saveRestaurantId(String restaurantId) async {
    await _secureStorage.write(
      key: AppConstants.restaurantIdKey,
      value: restaurantId,
    );
  }

  /// Get current restaurant ID
  Future<String?> getRestaurantId() async {
    return await _secureStorage.read(key: AppConstants.restaurantIdKey);
  }

  // ============ SETTINGS ============

  /// Save PIN enabled preference
  Future<void> setPinEnabled(bool enabled) async {
    await _secureStorage.write(
      key: AppConstants.pinEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Check if PIN is enabled
  Future<bool> isPinEnabled() async {
    final value = await _secureStorage.read(key: AppConstants.pinEnabledKey);
    return value == 'true';
  }

  /// Save biometric enabled preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: AppConstants.biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(
      key: AppConstants.biometricEnabledKey,
    );
    return value == 'true';
  }

  // ============ SYNC ============

  /// Save last sync timestamp
  Future<void> saveLastSync(DateTime dateTime) async {
    await _secureStorage.write(
      key: AppConstants.lastSyncKey,
      value: dateTime.toIso8601String(),
    );
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSync() async {
    final value = await _secureStorage.read(key: AppConstants.lastSyncKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Save offline mode preference
  Future<void> setOfflineMode(bool enabled) async {
    await _secureStorage.write(
      key: AppConstants.offlineModeKey,
      value: enabled.toString(),
    );
  }

  /// Check if offline mode is enabled
  Future<bool> isOfflineMode() async {
    final value = await _secureStorage.read(key: AppConstants.offlineModeKey);
    return value == 'true';
  }

  // ============ CLEAR ALL ============

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }

  /// Write custom key-value pair
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Read custom key
  Future<String?> read(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete custom key
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }
}
