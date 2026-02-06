import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Forgot PIN screen
class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  int _currentStep = 0;
  String? _error;
  bool _isLoading = false;

  String _getErrorMessage(dynamic error, String languageCode) {
    if (error is ApiException) {
      if (error.isNetworkError) {
        return Translations.get('no_internet_connection', languageCode);
      }
      if (error.isServerError) {
        return Translations.get('server_unavailable_try_again', languageCode);
      }
      if (error.isRateLimited) {
        return Translations.get('too_many_attempts_wait', languageCode);
      }
      return error.message;
    }
    return Translations.get('something_went_wrong', languageCode);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final languageCode = ref.watch(localizationProvider).languageCode;
    final phoneError = Validators.phone(_phoneController.text);
    if (phoneError != null) {
      if (mounted) setState(() => _error = phoneError);
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
          .forgotPin(Validators.normalizePhone(_phoneController.text));
      if (mounted) {
        setState(() {
          _currentStep = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getErrorMessage(e, languageCode);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAndReset() async {
    final languageCode = ref.watch(localizationProvider).languageCode;
    // Validate OTP
    final otpError = Validators.otp(_otpController.text);
    if (otpError != null) {
      if (mounted) setState(() => _error = otpError);
      return;
    }

    // Validate PIN match
    if (_newPinController.text != _confirmPinController.text) {
      if (mounted) setState(() => _error = 'PINs do not match');
      return;
    }

    final pinError = Validators.pin(_newPinController.text);
    if (pinError != null) {
      if (mounted) setState(() => _error = pinError);
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
          .resetPin(
            phone: Validators.normalizePhone(_phoneController.text),
            otp: _otpController.text,
            newPin: _newPinController.text,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN reset successfully! Please login.'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getErrorMessage(e, languageCode);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use local loading state to avoid disposed widget issues
    final isLoading = _isLoading;
    final languageCode = ref.watch(localizationProvider).languageCode;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(Translations.get('reset_pin', languageCode)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
              _currentStep == 0
                  ? _buildPhoneStep(isLoading, languageCode)
                  : _buildResetStep(isLoading, languageCode),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(bool isLoading, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

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
              Icons.lock_reset_rounded,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
        const SizedBox(height: 32),

        Text(
          Translations.get('reset_your_pin', languageCode),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          Translations.get(
            'enter_phone_number_to_receive_verification_code',
            languageCode,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.neutral500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: InputDecoration(
            labelText: Translations.get('phone_number', languageCode),
            hintText: '020 1234 5678',
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          enabled: !isLoading,
        ),

        if (_error != null) ...[
          const SizedBox(height: 20),
          ErrorBanner(
            key: ValueKey(_error),
            message: _error!,
            onDismiss: () {
              if (mounted) setState(() => _error = null);
            },
          ),
        ],

        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _sendOtp,
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
                    : Text(Translations.get('send_code', languageCode)),
          ),
        ),
      ],
    );
  }

  Widget _buildResetStep(bool isLoading, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        Text(
          Translations.get('enter_verification_code', languageCode),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${Translations.get('code_sent_to', languageCode)} ${Validators.formatPhone(_phoneController.text)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral500),
        ),
        const SizedBox(height: 24),

        // OTP Input
        PinCodeTextField(
          appContext: context,
          controller: _otpController,
          length: 6,
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          enabled: !isLoading,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: 50,
            fieldWidth: 45,
            activeFillColor: Colors.white,
            selectedFillColor: Colors.white,
            inactiveFillColor: AppTheme.neutral50,
            activeColor: AppTheme.primaryOrange,
            selectedColor: AppTheme.primaryOrange,
            inactiveColor: AppTheme.neutral300,
          ),
          enableActiveFill: true,
          onChanged: (value) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 32),

        Text(
          Translations.get('create_new_pin', languageCode),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // New PIN
        Text(
          Translations.get('enter_new_pin', languageCode),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        PinCodeTextField(
          appContext: context,
          controller: _newPinController,
          length: 4,
          keyboardType: TextInputType.number,
          obscureText: true,
          obscuringCharacter: '●',
          enabled: !isLoading,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: 56,
            fieldWidth: 56,
            activeFillColor: Colors.white,
            selectedFillColor: Colors.white,
            inactiveFillColor: AppTheme.neutral50,
            activeColor: AppTheme.primaryOrange,
            selectedColor: AppTheme.primaryOrange,
            inactiveColor: AppTheme.neutral300,
          ),
          enableActiveFill: true,
          onChanged: (value) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 16),

        // Confirm PIN
        Text(
          Translations.get('confirm_new_pin', languageCode),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        PinCodeTextField(
          appContext: context,
          controller: _confirmPinController,
          length: 4,
          keyboardType: TextInputType.number,
          obscureText: true,
          obscuringCharacter: '●',
          enabled: !isLoading,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: 56,
            fieldWidth: 56,
            activeFillColor: Colors.white,
            selectedFillColor: Colors.white,
            inactiveFillColor: AppTheme.neutral50,
            activeColor: AppTheme.primaryOrange,
            selectedColor: AppTheme.primaryOrange,
            inactiveColor: AppTheme.neutral300,
          ),
          enableActiveFill: true,
          onChanged: (value) {
            if (_error != null) setState(() => _error = null);
          },
        ),

        if (_error != null) ...[
          const SizedBox(height: 20),
          ErrorBanner(
            key: ValueKey(_error),
            message: _error!,
            title: Translations.get('reset_failed', languageCode),
            onDismiss: () {
              if (mounted) setState(() => _error = null);
            },
            onRetry: () {
              if (mounted) setState(() => _error = null);
            },
          ),
        ],

        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _verifyAndReset,
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
                    : Text(Translations.get('reset_pin', languageCode)),
          ),
        ),
      ],
    );
  }
}
