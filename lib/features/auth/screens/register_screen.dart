import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/auth_provider.dart';

/// Registration screen after OTP verification
class RegisterScreen extends ConsumerStatefulWidget {
  final String phone;
  final String tempToken;

  const RegisterScreen({
    super.key,
    required this.phone,
    required this.tempToken,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _restaurantIdController = TextEditingController();

  int _currentStep = 0;
  String? _pinError;
  String? _registrationError;
  bool _isLoading = false;

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
    return 'Registration failed. Please try again.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _restaurantIdController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validate PIN match
    if (_pinController.text != _confirmPinController.text) {
      if (mounted) setState(() => _pinError = 'PINs do not match');
      return;
    }

    final pinError = Validators.pin(_pinController.text);
    if (pinError != null) {
      if (mounted) setState(() => _pinError = pinError);
      return;
    }

    if (mounted) {
      setState(() {
        _pinError = null;
        _registrationError = null;
        _isLoading = true;
      });
    }

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            tempToken: widget.tempToken,
            phone: widget.phone,
            name: _nameController.text.trim(),
            pin: _pinController.text,
            restaurantId: _restaurantIdController.text.trim(),
          );
      // Navigation handled by router redirect
    } catch (e) {
      if (mounted) {
        setState(() {
          _registrationError = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate name
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Validate restaurant ID
      if (_restaurantIdController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your store/restaurant ID'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Widget _buildStepIcon(IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.maxWidth < 360 ? 64.0 : 80.0;
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrangeBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: iconSize * 0.5,
            color: AppTheme.primaryOrange,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use local loading state to avoid disposed widget issues
    final isLoading = _isLoading;
    final languageCode = ref.read(localizationProvider).languageCode;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        title: Text(
          Translations.get('step ${_currentStep + 1}', languageCode) +
              Translations.get('of 3', languageCode),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: AppTheme.neutral200,
                valueColor: const AlwaysStoppedAnimation(
                  AppTheme.primaryOrange,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentStep(isLoading, languageCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isLoading, String languageCode) {
    switch (_currentStep) {
      case 0:
        return _buildNameStep(isLoading, languageCode);
      case 1:
        return _buildRestaurantStep(isLoading, languageCode);
      case 2:
        return _buildPinStep(isLoading, languageCode);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep(bool isLoading, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        // Icon
        Center(
          child: _buildStepIcon(Icons.person_outline_rounded),
        ),
        const SizedBox(height: 32),

        Text(
          Translations.get('what_s_your_name', languageCode),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          Translations.get('this_will_be_displayed_on_receipts', languageCode),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.neutral500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: Translations.get('full_name', languageCode),
            hintText: Translations.get('enter_your_full_name', languageCode),
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: Validators.name,
          enabled: !isLoading,
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _nextStep,
            child: Text(Translations.get('continue', languageCode)),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantStep(bool isLoading, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        // Icon
        Center(
          child: _buildStepIcon(Icons.store_outlined),
        ),
        const SizedBox(height: 32),

        Text(
          Translations.get('enter_your_store_id', languageCode),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          Translations.get('ask_your_manager_for_the_store_id', languageCode),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.neutral500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        TextFormField(
          controller: _restaurantIdController,
          decoration: InputDecoration(
            labelText: Translations.get('store_restaurant_id', languageCode),
            hintText: Translations.get('enter_store_id', languageCode),
            prefixIcon: Icon(Icons.tag),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _nextStep,
            child: Text(Translations.get('continue', languageCode)),
          ),
        ),
      ],
    );
  }

  Widget _buildPinStep(bool isLoading, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        // Icon
        Center(
          child: _buildStepIcon(Icons.lock_outline_rounded),
        ),
        const SizedBox(height: 32),

        Text(
          Translations.get('create_your_pin', languageCode),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          Translations.get(
            'you_ll_use_this_pin_to_login_quickly',
            languageCode,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.neutral500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // PIN Input
        Text(
          Translations.get('enter_pin', languageCode),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
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
            fieldHeight: Responsive.getPinFieldHeight(context),
            fieldWidth: Responsive.getPinFieldWidth(context, fieldCount: 4),
            activeFillColor: Colors.white,
            selectedFillColor: Colors.white,
            inactiveFillColor: AppTheme.neutral50,
            activeColor: AppTheme.primaryOrange,
            selectedColor: AppTheme.primaryOrange,
            inactiveColor: AppTheme.neutral300,
          ),
          enableActiveFill: true,
          onChanged: (value) {
            if (_pinError != null) {
              setState(() => _pinError = null);
            }
          },
        ),
        const SizedBox(height: 24),

        // Confirm PIN
        Text(
          Translations.get('confirm_pin', languageCode),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        PinCodeTextField(
          appContext: context,
          controller: _confirmPinController,
          length: 4,
          keyboardType: TextInputType.number,
          obscureText: true,
          obscuringCharacter: '●',
          animationType: AnimationType.fade,
          enabled: !isLoading,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: Responsive.getPinFieldHeight(context),
            fieldWidth: Responsive.getPinFieldWidth(context, fieldCount: 4),
            activeFillColor: Colors.white,
            selectedFillColor: Colors.white,
            inactiveFillColor: AppTheme.neutral50,
            activeColor: AppTheme.primaryOrange,
            selectedColor: AppTheme.primaryOrange,
            inactiveColor: AppTheme.neutral300,
          ),
          enableActiveFill: true,
          onChanged: (value) {
            if (_pinError != null) {
              setState(() => _pinError = null);
            }
          },
        ),

        // Error message
        if (_pinError != null || _registrationError != null) ...[
          const SizedBox(height: 20),
          ErrorBanner(
            key: ValueKey(_pinError ?? _registrationError),
            message: _registrationError ?? _pinError!,
            title:
                _registrationError != null
                    ? Translations.get('registration_failed', languageCode)
                    : Translations.get('invalid_pin', languageCode),
            onDismiss: () {
              if (mounted) {
                setState(() {
                  _pinError = null;
                  _registrationError = null;
                });
              }
            },
            onRetry:
                _registrationError != null
                    ? () {
                      if (mounted) setState(() => _registrationError = null);
                    }
                    : null,
          ),
        ],

        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
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
                    : Text(Translations.get('create_account', languageCode)),
          ),
        ),
      ],
    );
  }
}
