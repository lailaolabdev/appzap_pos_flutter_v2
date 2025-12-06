import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

/// PIN Login screen for fast authentication
class PinLoginScreen extends ConsumerStatefulWidget {
  final String phone;

  const PinLoginScreen({
    super.key,
    required this.phone,
  });

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final pin = _pinController.text.trim();
    final error = Validators.pin(pin);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _error = null);

    try {
      await ref.read(authProvider.notifier).login(
        phone: widget.phone,
        pin: pin,
      );
      // Navigation handled by router redirect
    } catch (e) {
      setState(() => _error = 'Invalid PIN. Please try again.');
      _pinController.clear();
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
                'Enter your PIN',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 4-digit PIN to login',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Phone display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, size: 18, color: AppTheme.neutral500),
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
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppTheme.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 24),

              // Forgot PIN
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.push(AppRoutes.forgotPin),
                child: const Text('Forgot PIN?'),
              ),

              // Different account
              TextButton(
                onPressed: isLoading ? null : () => context.pop(),
                child: Text(
                  'Use a different account',
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

