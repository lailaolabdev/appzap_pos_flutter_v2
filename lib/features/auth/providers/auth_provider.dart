import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/services/auth_service.dart';

/// Auth state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

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

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
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
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
          );
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.sendOtp(
        phone: phone,
        purpose: purpose,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Verify OTP
  Future<String> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tempToken = await _authService.verifyOtp(
        phone: phone,
        otp: otp,
      );
      state = state.copyWith(isLoading: false);
      return tempToken;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.register(
        tempToken: tempToken,
        phone: phone,
        name: name,
        pin: pin,
        restaurantId: restaurantId,
        branchId: branchId,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Login with phone and PIN
  Future<void> login({
    required String phone,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.login(
        phone: phone,
        pin: pin,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Forgot PIN - send OTP
  Future<void> forgotPin(String phone) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.forgotPin(phone: phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Reset PIN with OTP
  Future<void> resetPin({
    required String phone,
    required String otp,
    required String newPin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.resetPin(
        phone: phone,
        otp: otp,
        newPin: newPin,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Change PIN
  Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.changePin(
        oldPin: oldPin,
        newPin: newPin,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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

