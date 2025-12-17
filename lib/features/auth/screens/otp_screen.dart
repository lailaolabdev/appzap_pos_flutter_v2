import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
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

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.isNetworkError) {
        return 'No internet connection. Please check your network.';
      }
      if (error.isServerError) {
        return 'Server is temporarily unavailable. Please try again later.';
      }
      if (error.isRateLimited) {
        return 'Too many attempts. Please wait a moment.';
      }
      return error.message;
    }
    return 'Invalid OTP. Please try again.';
  }

  Future<void> _resendOtp() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .sendOtp(phone: widget.phone, purpose: widget.purpose);
      _startResendTimer();

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleVerify() async {
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
                  _showPINSetupSuggestion();
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
          _error = _getErrorMessage(e);
          _isLoading = false;
        });
        _otpController.clear();
      }
    }
  }

  void _showPINSetupSuggestion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.flash_on, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            const Text('Setup PIN for Faster Login?'),
          ],
        ),
        content: const Text(
          'Setup a 4-digit PIN for quicker logins in the future. '
          'You can always login with OTP if you forget your PIN.\n\n'
          '⚡ PIN login takes only 2 seconds!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to settings where user can setup PIN
              context.push(AppRoutes.settings);
            },
            icon: const Icon(Icons.security, size: 20),
            label: const Text('Setup PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use local loading state to avoid disposed widget issues
    final isLoading = _isLoading;

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
                    Icons.sms_outlined,
                    size: 40,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Verify your phone',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to',
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
                  fieldHeight: 56,
                  fieldWidth: 48,
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
                  title: 'Verification Failed',
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
                          : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
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
                      child: const Text('Resend'),
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
