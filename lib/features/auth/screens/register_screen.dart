import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
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
      setState(() => _pinError = 'PINs do not match');
      return;
    }

    final pinError = Validators.pin(_pinController.text);
    if (pinError != null) {
      setState(() => _pinError = pinError);
      return;
    }

    setState(() => _pinError = null);

    try {
      await ref.read(authProvider.notifier).register(
        tempToken: widget.tempToken,
        phone: widget.phone,
        name: _nameController.text.trim(),
        pin: _pinController.text,
        restaurantId: _restaurantIdController.text.trim(),
      );
      // Navigation handled by router redirect
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        title: Text('Step ${_currentStep + 1} of 3'),
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
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryOrange),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentStep(isLoading),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isLoading) {
    switch (_currentStep) {
      case 0:
        return _buildNameStep(isLoading);
      case 1:
        return _buildRestaurantStep(isLoading);
      case 2:
        return _buildPinStep(isLoading);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep(bool isLoading) {
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
              Icons.person_outline_rounded,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'What\'s your name?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'This will be displayed on receipts',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.neutral500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
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
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantStep(bool isLoading) {
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
              Icons.store_outlined,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Enter your store ID',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Ask your manager for the store ID',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.neutral500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        TextFormField(
          controller: _restaurantIdController,
          decoration: const InputDecoration(
            labelText: 'Store/Restaurant ID',
            hintText: 'Enter store ID',
            prefixIcon: Icon(Icons.tag),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _nextStep,
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildPinStep(bool isLoading) {
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
              Icons.lock_outline_rounded,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Create your PIN',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You\'ll use this PIN to login quickly',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.neutral500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // PIN Input
        Text(
          'Enter PIN',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
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
            if (_pinError != null) {
              setState(() => _pinError = null);
            }
          },
        ),
        const SizedBox(height: 24),

        // Confirm PIN
        Text(
          'Confirm PIN',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
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
            if (_pinError != null) {
              setState(() => _pinError = null);
            }
          },
        ),

        // Error message
        if (_pinError != null) ...[
          const SizedBox(height: 16),
          Text(
            _pinError!,
            style: const TextStyle(
              color: AppTheme.error,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create Account'),
          ),
        ),
      ],
    );
  }
}

