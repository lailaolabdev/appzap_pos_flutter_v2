import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/pin_login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/forgot_pin_screen.dart';
import '../features/pos/screens/pos_screen.dart';
import '../features/inventory/screens/inventory_screen.dart';
import '../features/customers/screens/customers_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../shared/widgets/splash_screen.dart';

/// Route names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String pinLogin = '/pin-login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPin = '/forgot-pin';
  static const String pos = '/pos';
  static const String inventory = '/inventory';
  static const String customers = '/customers';
  static const String reports = '/reports';
  static const String settings = '/settings';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.pinLogin ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.forgotPin;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // Still loading - stay on splash
      if (isLoading && isSplash) {
        return null;
      }

      // Loading complete but on splash - redirect appropriately
      if (!isLoading && isSplash) {
        return isAuthenticated ? AppRoutes.pos : AppRoutes.login;
      }

      // Not authenticated but trying to access protected route
      if (!isAuthenticated && !isAuthRoute && !isSplash) {
        return AppRoutes.login;
      }

      // Authenticated but on auth route - go to POS
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.pos;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinLogin,
        builder: (context, state) {
          final phone = state.extra as String?;
          return PinLoginScreen(phone: phone ?? '');
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return RegisterScreen(
            phone: data?['phone'] as String? ?? '',
            tempToken: data?['tempToken'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            phone: data?['phone'] as String? ?? '',
            purpose: data?['purpose'] as String? ?? 'registration',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPin,
        builder: (context, state) => const ForgotPinScreen(),
      ),
      GoRoute(
        path: AppRoutes.pos,
        builder: (context, state) => const POSScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.customers,
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.pos),
              child: const Text('Go to POS'),
            ),
          ],
        ),
      ),
    ),
  );
});

