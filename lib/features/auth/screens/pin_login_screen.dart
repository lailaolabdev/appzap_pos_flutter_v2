import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/auth_provider.dart';

/// PIN Login screen for fast authentication
class PinLoginScreen extends ConsumerStatefulWidget {
  final String phone;

  const PinLoginScreen({super.key, required this.phone});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final languageCode = ref.read(localizationProvider).languageCode;
    final pin = _pinController.text.trim();
    final error = Validators.pin(pin);

    if (error != null) {
      if (mounted)
        setState(() => _error = Translations.get('invalid_pin', languageCode));
      return;
    }

    if (mounted) {
      setState(() {
        _error = null;
        _isLoading = true;
      });
    }

    try {
      await ref
          .read(authProvider.notifier)
          .login(phone: widget.phone, pin: pin);
      // Navigation handled by router redirect
    } catch (e) {
      if (mounted) {
        String errorMessage = _getErrorMessage(e, languageCode);
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
        _pinController.clear();
      }
    }
  }

  String _getErrorMessage(dynamic error, String languageCode) {
    if (error is ApiException) {
      if (error.isUnauthorized) {
        return Translations.get(
          'incorrect_pin_please_check_and_try_again',
          languageCode,
        );
      }
      if (error.isNetworkError) {
        return Translations.get(
          'no_internet_connection_please_check_your_network_and_try_again',
          languageCode,
        );
      }
      if (error.isServerError) {
        return Translations.get(
          'server_is_temporarily_unavailable_please_try_again_later',
          languageCode,
        );
      }
      if (error.isRateLimited) {
        return Translations.get(
          'too_many_attempts_please_wait_a_moment',
          languageCode,
        );
      }
      return error.message;
    }
    return Translations.get(
      'something_went_wrong_please_try_again',
      languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use local loading state to avoid disposed widget issues with provider updates
    final isLoading = _isLoading;

    final languageCode = ref.watch(localizationProvider).languageCode;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrangeBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                Translations.get('enter_your_pin', languageCode),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                Translations.get(
                  'enter_your_4_digit_pin_to_login',
                  languageCode,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.neutral500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Phone display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone,
                      size: 18,
                      color: AppTheme.neutral500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Validators.formatPhone(widget.phone),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // PIN Input
              PinCodeTextField(
                appContext: context,
                controller: _pinController,
                length: 4,
                keyboardType: TextInputType.number,
                obscureText: true,
                obscuringCharacter: '●',
                animationType: AnimationType.fade,
                enabled: !isLoading,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 60,
                  fieldWidth: 60,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: AppTheme.neutral50,
                  activeColor: AppTheme.primaryOrange,
                  selectedColor: AppTheme.primaryOrange,
                  inactiveColor: AppTheme.neutral300,
                  errorBorderColor: AppTheme.error,
                ),
                enableActiveFill: true,
                onCompleted: (value) => _handleLogin(),
                onChanged: (value) {
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 20),
                ErrorBanner(
                  key: ValueKey(_error),
                  message: _error!,
                  title: Translations.get('login_failed', languageCode),
                  onDismiss: () {
                    if (mounted) setState(() => _error = null);
                  },
                  onRetry: () {
                    if (mounted) {
                      setState(() => _error = null);
                      _pinController.clear();
                    }
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                          : Text(Translations.get('login', languageCode)),
                ),
              ),
              const SizedBox(height: 24),

              // Forgot PIN
              TextButton(
                onPressed:
                    isLoading ? null : () => context.push(AppRoutes.forgotPin),
                child: Text(Translations.get('forgot_pin', languageCode)),
              ),

              // Different account
              TextButton(
                onPressed: isLoading ? null : () => context.pop(),
                child: Text(
                  Translations.get('use_a_different_account', languageCode),
                  style: TextStyle(color: AppTheme.neutral500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
