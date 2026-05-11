import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../app/router.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

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
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  String _getErrorMessage(dynamic error, String code) {
    if (error is ApiException) {
      if (error.isNetworkError) {
        return Translations.get(
          'no_internet_connection_please_check_your_network',
          code,
        );
      }
      if (error.isServerError) {
        return Translations.get(
          'server_is_temporarily_unavailable_please_try_again_later',
          code,
        );
      }
      if (error.isRateLimited) {
        return Translations.get(
          'too_many_attempts_please_wait_a_moment',
          code,
        );
      }
      return error.message;
    }
    return Translations.get('invalid_otp_please_try_again', code);
  }

  Future<void> _resendOtp() async {
    final code = ref.read(localizationProvider).languageCode;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .sendOtp(phone: widget.phone, purpose: widget.purpose);
      _startResendTimer();
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: BrandPalette.success,
          content: Text(
            Translations.get('otp_sent_successfully', code),
            style: BrandFonts.body(14, color: BrandPalette.paper),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: BrandPalette.danger,
          content: Text(
            _getErrorMessage(e, code),
            style: BrandFonts.body(14, color: BrandPalette.paper),
          ),
        ),
      );
    }
  }

  Future<void> _handleVerify() async {
    final code = ref.read(localizationProvider).languageCode;
    final otp = _otpController.text.trim();
    final otpError = Validators.otp(otp);
    if (otpError != null) {
      setState(() => _error = otpError);
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      if (widget.purpose == 'login') {
        final result = await ref
            .read(authProvider.notifier)
            .verifyOtpAndLogin(phone: widget.phone, otp: otp);
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (result.isRegistered) {
          context.go(AppRoutes.pos);
          if (result.hasPIN == false) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _showPINSetupSuggestion(code);
            });
          }
        } else {
          context.push(
            AppRoutes.register,
            extra: {
              'registrationToken': result.registrationToken!,
              'phone': result.phone!,
            },
          );
        }
      } else {
        final tempToken = await ref
            .read(authProvider.notifier)
            .verifyOtp(phone: widget.phone, otp: otp);
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (widget.purpose == 'registration') {
          context.pushReplacement(
            AppRoutes.register,
            extra: {'phone': widget.phone, 'tempToken': tempToken},
          );
        } else if (widget.purpose == 'forgot_pin') {
          context.pop(tempToken);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _getErrorMessage(e, code);
        _isLoading = false;
      });
      _otpController.clear();
    }
  }

  void _showPINSetupSuggestion(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandPalette.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: BrandPalette.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Translations.get('setup_pin_for_faster_login', code),
                style: BrandFonts.display(
                  18,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '${Translations.get('setup_a_4_digit_pin_for_quicker_logins_in_the_future', code)} '
          '${Translations.get('you_can_always_login_with_otp_if_you_forget_your_pin', code)}',
          style: BrandFonts.body(13.5, color: BrandPalette.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Translations.get('skip', code),
              style: BrandFonts.button(
                14,
                color: BrandPalette.inkMuted,
                weight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandPalette.primary,
              foregroundColor: BrandPalette.paper,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
            icon: const Icon(Icons.security_rounded, size: 18),
            label: Text(Translations.get('setup_pin', code)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(localizationProvider).languageCode;
    final isLao = code == 'lo';

    final hero = HeroContent(
      badge: isLao ? 'ຢືນຢັນເບີໂທ' : 'Verify your phone',
      headline: isLao
          ? 'ອີກໜຶ່ງ\nຂັ້ນຕອນ\nເທົ່ານັ້ນ.'
          : 'Just one\nmore quick\nstep.',
      subline: isLao
          ? 'ພວກເຮົາໄດ້ສົ່ງລະຫັດ 6 ຕົວເລກໄປຍັງເບີຂອງທ່ານ — ໃສ່ດ້ານຂວາເພື່ອດຳເນີນຕໍ່.'
          : 'We\'ve texted a six-digit code to your phone — drop it in to keep moving.',
      features: isLao
          ? const [
              'ລະຫັດໝົດອາຍຸໃນ 5 ນາທີ',
              'ສ່ົງໃໝ່ໄດ້ ຖ້າບໍ່ໄດ້ຮັບ',
              'ການເຊື່ອມຕໍ່ປອດໄພແບບ end-to-end',
            ]
          : const [
              'Codes expire in 5 minutes',
              'Resend if you miss it',
              'End-to-end encrypted delivery',
            ],
    );

    return AuthShell(
      hero: hero,
      topRight: _LangPill(),
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [_BackChip(onTap: () => context.pop())],
          ),
          const SizedBox(height: 28),
          Center(child: AppZapMark(size: 56)),
          const SizedBox(height: 18),
          Center(
            child: Text(
              isLao ? 'ຢືນຢັນເບີໂທ' : 'Verify phone',
              style: BrandFonts.small(
                11.5,
                color: BrandPalette.primary,
                weight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLao ? 'ໃສ່ລະຫັດ 6 ຕົວເລກ' : 'Enter the 6-digit code',
            textAlign: TextAlign.center,
            style: BrandFonts.display(
              26,
              weight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: BrandFonts.body(
                14,
                color: BrandPalette.inkMuted,
                weight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: isLao ? 'ສົ່ງໄປທີ່ ' : 'Sent to ',
                ),
                TextSpan(
                  text: '+856 ${Validators.formatPhone(widget.phone)}',
                  style: BrandFonts.body(
                    14,
                    color: BrandPalette.ink,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          PinCodeTextField(
            appContext: context,
            controller: _otpController,
            length: 6,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            enabled: !_isLoading,
            textStyle: BrandFonts.display(
              22,
              color: BrandPalette.ink,
              weight: FontWeight.w700,
            ),
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(14),
              fieldHeight: Responsive.getPinFieldHeight(context),
              fieldWidth: Responsive.getPinFieldWidth(context, fieldCount: 6),
              activeFillColor: BrandPalette.cream,
              selectedFillColor: BrandPalette.paper,
              inactiveFillColor: BrandPalette.cream,
              activeColor: BrandPalette.primary,
              selectedColor: BrandPalette.primary,
              inactiveColor: BrandPalette.border,
              errorBorderColor: BrandPalette.danger,
              borderWidth: 1,
              activeBorderWidth: 1.6,
              selectedBorderWidth: 1.6,
            ),
            enableActiveFill: true,
            onCompleted: (_) => _handleVerify(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 18),
            ErrorBanner(
              key: ValueKey(_error),
              message: _error!,
              title: Translations.get('verification_failed', code),
              onDismiss: () => setState(() => _error = null),
              onRetry: () {
                setState(() => _error = null);
                _otpController.clear();
              },
            ),
          ],

          const SizedBox(height: 28),
          BrandPrimaryButton(
            label: Translations.get('verify', code),
            onPressed: _isLoading ? null : _handleVerify,
            isLoading: _isLoading,
            trailingIcon: Icons.east_rounded,
          ),
          const SizedBox(height: 18),

          Center(
            child: _resendCountdown > 0
                ? RichText(
                    text: TextSpan(
                      style: BrandFonts.body(
                        13,
                        color: BrandPalette.inkMuted,
                        weight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${Translations.get('didnt_receive_the_code', code)} ',
                        ),
                        TextSpan(
                          text:
                              '${Translations.get('resend_in', code)} ${_resendCountdown}s',
                          style: BrandFonts.body(
                            13,
                            color: BrandPalette.ink,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: BrandFonts.body(
                        13,
                        color: BrandPalette.inkMuted,
                        weight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${Translations.get('didnt_receive_the_code', code)} ',
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _resendOtp,
                            child: Text(
                              Translations.get('resend', code),
                              style: BrandFonts.body(
                                13,
                                color: BrandPalette.primary,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LangPill extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localizationProvider).languageCode;
    return LangSwitch(
      current: code,
      onChanged: (c) =>
          ref.read(localizationProvider.notifier).setLanguage(c),
    );
  }
}

class _BackChip extends StatelessWidget {
  final VoidCallback onTap;
  const _BackChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandPalette.cream,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: BrandPalette.border, width: 1),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: BrandPalette.ink,
          ),
        ),
      ),
    );
  }
}
