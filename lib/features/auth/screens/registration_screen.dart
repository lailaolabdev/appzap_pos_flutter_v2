import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/auth_provider.dart';

/// Self-service registration screen for new users
/// 
/// This screen is shown after OTP verification when the user is not registered.
/// Allows users to create their own account with just 3 fields!
class RegistrationScreen extends ConsumerStatefulWidget {
  final String registrationToken;
  final String phone;

  const RegistrationScreen({
    super.key,
    required this.registrationToken,
    required this.phone,
  });

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _restaurantController = TextEditingController();
  final _pinController = TextEditingController();

  bool _setupPIN = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _restaurantController.dispose();
    _pinController.dispose();
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

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      await ref.read(authProvider.notifier).registerWithPhone(
            registrationToken: widget.registrationToken,
            name: _nameController.text.trim(),
            restaurantName: _restaurantController.text.trim(),
            pin: _setupPIN ? _pinController.text.trim() : null,
          );

      if (mounted) {
        // 🎉 Account created! Navigate to main app
        context.go(AppRoutes.pos);

        // Show welcome message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome to AppZap POS! 🎉\nYour account is ready!',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 4),
          ),
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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Create Your Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome message
                Text(
                  'Almost there!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phone verified: ${widget.phone}',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Just 3 quick details and you\'re ready to start selling!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral500,
                      ),
                ),
                const SizedBox(height: 32),

                // Name input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person_outline),
                    helperText: 'This will be your display name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                  autofocus: true,
                ),
                const SizedBox(height: 20),

                // Restaurant name input
                TextFormField(
                  controller: _restaurantController,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant/Shop Name',
                    hintText: 'John\'s Coffee Shop',
                    prefixIcon: Icon(Icons.store_outlined),
                    helperText: 'Your business name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your restaurant name';
                    }
                    if (value.trim().length < 2) {
                      return 'Restaurant name must be at least 2 characters';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // Optional PIN setup section
                Card(
                  elevation: 0,
                  color: AppTheme.primaryOrangeBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.flash_on,
                              color: AppTheme.primaryOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Setup PIN for Faster Logins',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppTheme.primaryOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Optional: Set up a 4-digit PIN for ultra-fast daily logins (2 seconds!)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.neutral600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _setupPIN,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _setupPIN = value ?? false);
                                },
                          title: const Text('Yes, setup PIN now'),
                          subtitle: const Text('You can always skip and set it up later'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_setupPIN) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      labelText: '4-Digit PIN',
                      hintText: '****',
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: 'Choose a memorable 4-digit PIN',
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (_setupPIN) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a PIN';
                        }
                        if (value.length != 4) {
                          return 'PIN must be exactly 4 digits';
                        }
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 20),
                  ErrorBanner(
                    message: _error!,
                    onDismiss: () {
                      if (mounted) setState(() => _error = null);
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Create Account button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket_launch, size: 20),
                              SizedBox(width: 8),
                              Text('Create Account & Start Selling'),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppTheme.neutral500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What you get:',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.neutral700,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow('Your own restaurant account'),
                      _buildBenefitRow('Owner role with full permissions'),
                      _buildBenefitRow('Start selling immediately'),
                      _buildBenefitRow('Add staff later as you grow'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Terms text
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral400,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.success,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.neutral600,
                ),
          ),
        ],
      ),
    );
  }
}

