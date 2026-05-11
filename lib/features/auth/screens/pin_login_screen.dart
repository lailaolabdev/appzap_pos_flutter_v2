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

class PinLoginScreen extends ConsumerStatefulWidget {
  final String phone;
  const PinLoginScreen({super.key, required this.phone});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  String _getErrorMessage(dynamic error, String code) {
    if (error is ApiException) {
      if (error.isUnauthorized) {
        return Translations.get(
          'incorrect_pin_please_check_and_try_again',
          code,
        );
      }
      if (error.isNetworkError) {
        return Translations.get(
          'no_internet_connection_please_check_your_network_and_try_again',
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
    return Translations.get('something_went_wrong_please_try_again', code);
  }

  Future<void> _handleLogin() async {
    final code = ref.read(localizationProvider).languageCode;
    final pin = _pinController.text.trim();
    final pinError = Validators.pin(pin);
    if (pinError != null) {
      setState(() => _error = Translations.get('invalid_pin', code));
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(phone: widget.phone, pin: pin);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _getErrorMessage(e, code);
        _isLoading = false;
      });
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(localizationProvider).languageCode;
    final isLao = code == 'lo';

    final hero = HeroContent(
      badge: isLao ? 'ເຂົ້າສູ່ລະບົບໄວ' : 'Quick sign in',
      headline: isLao
          ? 'ກັບເຂົ້າສູ່\nເຮືອນຄົວ\nຂອງທ່ານ.'
          : 'Welcome back\nto your\nkitchen.',
      subline: isLao
          ? 'ໃສ່ລະຫັດ PIN 4 ຕົວເລກ ເພື່ອເລີ່ມຄາບເຮັດວຽກ.'
          : 'Tap in your four-digit PIN — the floor is waiting.',
      features: isLao
          ? const [
              'ດຳເນີນຄາບເຮັດວຽກຕໍ່ ຂ້ຽນຄຳສັ່ງຄ້າງໄວ້',
              'ສະຫຼັບບັນຊີໄດ້ທຸກເວລາ',
              'ລືມລະຫັດ? ຣີເຊັດດ້ວຍ OTP ໄດ້',
            ]
          : const [
              'Resume open tabs and orders',
              'Switch staff accounts anytime',
              'Forgot it? Reset by phone OTP',
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
              isLao ? 'ເຂົ້າສູ່ລະບົບດ້ວຍ PIN' : 'Sign in with PIN',
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
            isLao ? 'ໃສ່ລະຫັດ PIN ຂອງທ່ານ' : 'Enter your PIN',
            textAlign: TextAlign.center,
            style: BrandFonts.display(
              26,
              weight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLao
                ? 'ໃສ່ລະຫັດ PIN 4 ຕົວເລກ ເພື່ອເຂົ້າສູ່ລະບົບ'
                : 'Tap in your four digits to keep going',
            textAlign: TextAlign.center,
            style: BrandFonts.body(
              14,
              color: BrandPalette.inkMuted,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: BrandPalette.cream,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: BrandPalette.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone_rounded,
                    size: 14,
                    color: BrandPalette.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+856 ${Validators.formatPhone(widget.phone)}',
                    style: BrandFonts.body(
                      13,
                      color: BrandPalette.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          PinCodeTextField(
            appContext: context,
            controller: _pinController,
            length: 4,
            keyboardType: TextInputType.number,
            obscureText: true,
            obscuringCharacter: '●',
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
              fieldWidth: Responsive.getPinFieldWidth(context, fieldCount: 4),
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
            onCompleted: (_) => _handleLogin(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 18),
            ErrorBanner(
              key: ValueKey(_error),
              message: _error!,
              title: Translations.get('login_failed', code),
              onDismiss: () => setState(() => _error = null),
              onRetry: () {
                setState(() => _error = null);
                _pinController.clear();
              },
            ),
          ],

          const SizedBox(height: 28),
          BrandPrimaryButton(
            label: Translations.get('login', code),
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : () => context.push(AppRoutes.forgotPin),
              child: Text(
                Translations.get('forgot_pin', code),
                style: BrandFonts.body(
                  13.5,
                  color: BrandPalette.primary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: _isLoading ? null : () => context.pop(),
              child: Text(
                Translations.get('use_a_different_account', code),
                style: BrandFonts.body(
                  13,
                  color: BrandPalette.inkMuted,
                  weight: FontWeight.w500,
                ),
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
