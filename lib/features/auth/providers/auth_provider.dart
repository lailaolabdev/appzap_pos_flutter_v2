import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/services/auth_service.dart';

/// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth state model
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Current branch ID provider
final currentBranchIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.branch?.id;
});

/// Current restaurant ID provider
final currentRestaurantIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.restaurant?.id;
});

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
          return;
        }
      }

      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Send OTP for registration
  Future<void> sendOtp({
    required String phone,
    String purpose = 'registration',
  }) async {
    // UI handles loading state locally to prevent disposed widget issues
    try {
      await _authService.sendOtp(phone: phone, purpose: purpose);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP - Smart Response (Handles both login AND registration)
  /// 
  /// Returns OTPVerificationResult which can be:
  /// 1. isRegistered=true → User logged in (update auth state)
  /// 2. isRegistered=false → Registration required (no auth state change)
  Future<OTPVerificationResult> verifyOtpAndLogin({
    required String phone,
    required String otp,
  }) async {
    // UI handles loading state locally to prevent disposed widget issues
    try {
      final result = await _authService.verifyOtpAndLogin(
        phone: phone,
        otp: otp,
      );

      // If user is registered, update auth state
      if (result.isRegistered && result.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.user,
        );
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Complete registration for new users (Self-service!)
  /// 
  /// Called after OTP verification returns registrationToken.
  /// Creates account and logs user in automatically.
  Future<void> registerWithPhone({
    required String registrationToken,
    required String name,
    required String restaurantName,
    String? pin,
  }) async {
    // UI handles loading state locally
    try {
      final result = await _authService.registerWithPhone(
        registrationToken: registrationToken,
        name: name,
        restaurantName: restaurantName,
        pin: pin,
      );

      // Update auth state - user is now authenticated!
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Legacy method - Verify OTP (DEPRECATED)
  /// Use verifyOtpAndLogin() for login flow instead
  @Deprecated('Use verifyOtpAndLogin() for login flow')
  Future<String> verifyOtp({required String phone, required String otp}) async {
    // UI handles loading state locally to prevent disposed widget issues
    try {
      final tempToken = await _authService.verifyOtp(phone: phone, otp: otp);
      return tempToken;
    } catch (e) {
      rethrow;
    }
  }

  /// Register new user
  Future<void> register({
    required String tempToken,
    required String phone,
    required String name,
    required String pin,
    required String restaurantId,
    String? branchId,
  }) async {
    // UI handles loading state locally to prevent disposed widget issues
    try {
      final user = await _authService.register(
        tempToken: tempToken,
        phone: phone,
        name: name,
        pin: pin,
        restaurantId: restaurantId,
        branchId: branchId,
      );

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      rethrow;
    }
  }

  /// Login with phone and PIN
  Future<void> login({required String phone, required String pin}) async {
    // Don't update state here - let the UI handle loading state locally
    // This prevents disposed widget issues with Riverpod notifications

    try {
      final user = await _authService.login(phone: phone, pin: pin);

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      // Don't update state on error - just rethrow
      // The calling screen handles error state locally
      rethrow;
    }
  }

  /// Forgot PIN - send OTP
  Future<void> forgotPin(String phone) async {
    // UI handles loading state locally to prevent disposed widget issues
    try {
      await _authService.forgotPin(phone: phone);
    } catch (e) {
      rethrow;
    }
  }

  /// Reset PIN with OTP
  Future<void> resetPin({
    required String phone,
    required String otp,
    required String newPin,
  }) async {
    // UI handles loading state locally to prevent disposed widget issues
    try {
      await _authService.resetPin(phone: phone, otp: otp, newPin: newPin);
    } catch (e) {
      rethrow;
    }
  }

  /// Change PIN
  Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    // UI handles loading state locally to prevent disposed widget issues
    try {
      await _authService.changePin(oldPin: oldPin, newPin: newPin);
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
