import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/auth_provider.dart';

/// OTP verification screen
class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String purpose;

  const OtpScreen({super.key, required this.phone, required this.purpose});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  String? _error;
  int _resendCountdown = 60;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _resendCountdown = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _getErrorMessage(dynamic error, String languageCode) {
    if (error is ApiException) {
      if (error.isNetworkError) {
        return Translations.get(
          'no_internet_connection_please_check_your_network',
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
    return Translations.get('invalid_otp_please_try_again', languageCode);
  }

  Future<void> _resendOtp() async {
    final languageCode = ref.read(localizationProvider).languageCode;
    if (mounted) setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .sendOtp(phone: widget.phone, purpose: widget.purpose);
      _startResendTimer();

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.get('otp_sent_successfully', languageCode),
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e, languageCode)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleVerify() async {
    final languageCode = ref.read(localizationProvider).languageCode;
    final otp = _otpController.text.trim();
    final error = Validators.otp(otp);

    if (error != null) {
      if (mounted) setState(() => _error = error);
      return;
    }

    if (mounted) {
      setState(() {
        _error = null;
        _isLoading = true;
      });
    }

    try {
      if (widget.purpose == 'login') {
        // Smart OTP flow: Handles both login AND registration!
        final result = await ref
            .read(authProvider.notifier)
            .verifyOtpAndLogin(phone: widget.phone, otp: otp);

        if (mounted) {
          setState(() => _isLoading = false);

          if (result.isRegistered) {
            // ✅ SCENARIO 1: Existing User - LOGGED IN!
            context.go(AppRoutes.pos);

            // Show PIN setup suggestion if user doesn't have PIN
            if (result.hasPIN == false) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  _showPINSetupSuggestion(languageCode);
                }
              });
            }
          } else {
            // 📝 SCENARIO 2: New User - Show Registration Screen
            context.push(
              AppRoutes.register,
              extra: {
                'registrationToken': result.registrationToken!,
                'phone': result.phone!,
              },
            );
          }
        }
      } else {
        // Legacy flows (registration, forgot_pin)
        final tempToken = await ref
            .read(authProvider.notifier)
            .verifyOtp(phone: widget.phone, otp: otp);

        if (mounted) {
          setState(() => _isLoading = false);
          if (widget.purpose == 'registration') {
            context.pushReplacement(
              AppRoutes.register,
              extra: {'phone': widget.phone, 'tempToken': tempToken},
            );
          } else if (widget.purpose == 'forgot_pin') {
            // Handle forgot PIN flow
            context.pop(tempToken);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getErrorMessage(e, languageCode);
          _isLoading = false;
        });
        _otpController.clear();
      }
    }
  }

  void _showPINSetupSuggestion(String languageCode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.flash_on, color: AppTheme.primaryOrange),
                const SizedBox(width: 8),
                Text(
                  Translations.get('setup_pin_for_faster_login', languageCode),
                ),
              ],
            ),
            content: Text(
              '${Translations.get('setup_a_4_digit_pin_for_quicker_logins_in_the_future', languageCode)} '
              '${Translations.get('you_can_always_login_with_otp_if_you_forget_your_pin', languageCode)}\n\n'
              '${Translations.get('⚡_pin_login_takes_only_2_seconds!', languageCode)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(Translations.get('skip', languageCode)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to settings where user can setup PIN
                  context.push(AppRoutes.settings);
                },
                icon: const Icon(Icons.security, size: 20),
                label: Text(Translations.get('setup_pin', languageCode)),
              ),
            ],
          ),
    );
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
                child: LayoutBuilder(
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
                        Icons.sms_outlined,
                        size: iconSize * 0.5,
                        color: AppTheme.primaryOrange,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                Translations.get('verify_your_phone', languageCode),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                Translations.get('we_sent_a_6_digit_code_to', languageCode),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.neutral500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                Validators.formatPhone(widget.phone),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

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
                  fieldHeight: Responsive.getPinFieldHeight(context),
                  fieldWidth: Responsive.getPinFieldWidth(context, fieldCount: 6),
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: AppTheme.neutral50,
                  activeColor: AppTheme.primaryOrange,
                  selectedColor: AppTheme.primaryOrange,
                  inactiveColor: AppTheme.neutral300,
                  errorBorderColor: AppTheme.error,
                ),
                enableActiveFill: true,
                onCompleted: (value) => _handleVerify(),
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
                  title: Translations.get('verification_failed', languageCode),
                  onDismiss: () {
                    if (mounted) setState(() => _error = null);
                  },
                  onRetry: () {
                    if (mounted) {
                      setState(() => _error = null);
                      _otpController.clear();
                    }
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleVerify,
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
                          : Text(Translations.get('verify', languageCode)),
                ),
              ),
              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Translations.get('didnt_receive_the_code', languageCode),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      '${Translations.get('resend_in', languageCode)} ${_resendCountdown}s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral400,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: isLoading ? null : _resendOtp,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(Translations.get('resend', languageCode)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
