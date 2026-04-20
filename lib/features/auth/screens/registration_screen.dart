import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
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
      await ref
          .read(authProvider.notifier)
          .registerWithPhone(
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
    final languageCode = ref.read(localizationProvider).languageCode;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(Translations.get('create_your_account', languageCode)),
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
                  Translations.get('almost_there', languageCode),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translations.get('phone_verified', languageCode),
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
                  Translations.get(
                    'just_3_quick_details_and_you_re_ready_to_start_selling',
                    languageCode,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral500),
                ),
                const SizedBox(height: 32),

                // Name input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: Translations.get('your_name', languageCode),
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person_outline),
                    helperText: Translations.get(
                      'this_will_be_your_display_name',
                      languageCode,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return Translations.get(
                        'please_enter_your_name',
                        languageCode,
                      );
                    }
                    if (value.trim().length < 2) {
                      return Translations.get(
                        'name_must_be_at_least_2_characters',
                        languageCode,
                      );
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
                  decoration: InputDecoration(
                    labelText: Translations.get(
                      'restaurant_shop_name',
                      languageCode,
                    ),
                    hintText: 'John\'s Coffee Shop',
                    prefixIcon: Icon(Icons.store_outlined),
                    helperText: Translations.get(
                      'your_business_name',
                      languageCode,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return Translations.get(
                        'please_enter_your_restaurant_name',
                        languageCode,
                      );
                    }
                    if (value.trim().length < 2) {
                      return Translations.get(
                        'restaurant_name_must_be_at_least_2_characters',
                        languageCode,
                      );
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
                                Translations.get(
                                  'setup_pin_for_faster_logins',
                                  languageCode,
                                ),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Translations.get('optional_set_up', languageCode),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.neutral600),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _setupPIN,
                          onChanged:
                              _isLoading
                                  ? null
                                  : (value) {
                                    setState(() => _setupPIN = value ?? false);
                                  },
                          title: Text(
                            Translations.get('yes_setup_pin_now', languageCode),
                          ),
                          subtitle: Text(
                            Translations.get(
                              'you_can_always_skip_and_set_it_up_later',
                              languageCode,
                            ),
                          ),
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
                    decoration: InputDecoration(
                      labelText: Translations.get('4_digit_pin', languageCode),
                      hintText: '****',
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: Translations.get(
                        'choose_a_memorable_4_digit_pin',
                        languageCode,
                      ),
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
                          return Translations.get(
                            'please_enter_a_pin',
                            languageCode,
                          );
                        }
                        if (value.length != 4) {
                          return Translations.get(
                            'pin_must_be_exactly_4_digits',
                            languageCode,
                          );
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
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  Translations.get(
                                    'create_account_start_selling',
                                    languageCode,
                                  ),
                                ),
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
                            Translations.get('what_you_get', languageCode),
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(
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
                  Translations.get('by_creating_an_account', languageCode),
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

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral600),
          ),
        ],
      ),
    );
  }
}
