import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/auth_provider.dart';

/// Login screen with phone number entry
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.isNetworkError) {
        return 'No internet connection. Please check your network.';
      }
      if (error.isServerError) {
        return 'Server is temporarily unavailable. Please try again later.';
      }
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = Validators.normalizePhone(_phoneController.text.trim());

    if (mounted) {
      setState(() {
        _error = null;
        _isLoading = true;
      });
    }

    try {
      // Send OTP for login (works for all users)
      await ref
          .read(authProvider.notifier)
          .sendOtp(phone: phone, purpose: 'login');

      if (mounted) {
        setState(() => _isLoading = false);
        // Go to OTP screen for verification
        context.push(
          AppRoutes.otp,
          extra: {'phone': phone, 'purpose': 'login'},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use local loading state to avoid disposed widget issues
    final isLoading = _isLoading;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrangeBackground,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      size: 50,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Welcome to AppZap POS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your phone number to receive OTP',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.neutral500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Error Banner
                if (_error != null) ...[
                  ErrorBanner(
                    key: ValueKey(_error),
                    message: _error!,
                    onDismiss: () {
                      if (mounted) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                    _PhoneNumberFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '020 1234 5678',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: '+856 ',
                    prefixStyle: TextStyle(
                      color: AppTheme.neutral700,
                      fontSize: 16,
                    ),
                  ),
                  validator: Validators.phone,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 32),

                // Send OTP Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _sendOTP,
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
                            : const Text('Send OTP'),
                  ),
                ),
                const SizedBox(height: 16),

                // Login with PIN instead (for returning users)
                TextButton.icon(
                  onPressed:
                      isLoading
                          ? null
                          : () => context.push(AppRoutes.pinLogin),
                  icon: const Icon(Icons.flash_on, size: 20),
                  label: const Text('Login with PIN instead (⚡ faster)'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryOrange,
                  ),
                ),

                const SizedBox(height: 48),

                // Footer
                Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone number formatter (020 1234 5678)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 7) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
