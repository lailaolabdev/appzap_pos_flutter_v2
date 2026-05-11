import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _error;
  bool _isLoading = false;
  // 0 = Login, 1 = Register (sign up)
  int _tab = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
      return error.message;
    }
    return Translations.get(
      'something_went_wrong_please_try_again',
      languageCode,
    );
  }

  Future<void> _submit() async {
    final languageCode = ref.read(localizationProvider).languageCode;
    if (!_formKey.currentState!.validate()) return;

    final phone = Validators.normalizePhone(_phoneController.text.trim());
    final purpose = _tab == 0 ? 'login' : 'registration';

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .sendOtp(phone: phone, purpose: purpose);
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.push(
        AppRoutes.otp,
        extra: {'phone': phone, 'purpose': purpose},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _getErrorMessage(e, languageCode);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localizationProvider).languageCode;
    final isLao = languageCode == 'lo';

    final hero = HeroContent(
      badge: isLao ? 'POS ລຸ້ນໃໝ່ທັນສະໄໝ' : 'A modern POS for Laos',
      headline: isLao
          ? 'ໃຫ້ທຸລະກິດ\nເຕີບໃຫຍ່ໄປ\nພ້ອມ AppZap'
          : 'Grow your\nrestaurant with\nAppZap.',
      subline: isLao
          ? 'ລະບົບ POS ທີ່ສົມບູນທີ່ສຸດ ສຳລັບຮ້ານອາຫານຂອງທ່ານ — ຮັບອໍເດີ, ຈັດການເມນູ ແລະ ໄດ້ລາຍງານໄວ.'
          : 'A complete POS for restaurants — take orders, manage menus, and read crisp daily reports.',
      features: isLao
          ? const [
              'ຮັບເງິນຫຼາຍຮູບແບບ ຮອງຮັບໂມບາຍແບງກິ້ງ',
              'ລູກຄ້າສັ່ງຜ່ານ QR ທີ່ໂຕະ',
              'ທີມງານດູແລ 24/7',
            ]
          : const [
              'Accept cash, mobile banking, and card',
              'Guests order from QR codes at the table',
              '24/7 local support team',
            ],
    );

    return AuthShell(
      hero: hero,
      topRight: _LangPill(),
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: AppZapMark(size: 64)),
            const SizedBox(height: 28),

            BrandSegmented(
              labels: isLao
                  ? const ['ເຂົ້າສູ່ລະບົບ', 'ສະໝັກສະມາຊິກໃໝ່']
                  : const ['Sign in', 'Create account'],
              selected: _tab,
              onChanged: (v) => setState(() => _tab = v),
            ),
            const SizedBox(height: 24),

            Text(
              _tab == 0
                  ? (isLao
                      ? 'ເຂົ້າສູ່ລະບົບເພື່ອດຳເນີນທຸລະກິດ'
                      : 'Sign in to keep your kitchen running')
                  : (isLao
                      ? 'ສ້າງບັນຊີໃໝ່ໃນ 1 ນາທີ — ບໍ່ມີຄ່າໃຊ້ຈ່າຍ'
                      : 'Create an account in a minute — no card needed'),
              style: BrandFonts.body(
                14,
                color: BrandPalette.inkMuted,
                weight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),

            if (_error != null) ...[
              ErrorBanner(
                key: ValueKey(_error),
                message: _error!,
                onDismiss: () => setState(() => _error = null),
              ),
              const SizedBox(height: 18),
            ],

            BrandPhoneField(
              label: isLao ? 'ເບີໂທລະສັບ' : 'Phone number',
              hint: '20 1234 5678',
              helper: isLao
                  ? 'ພວກເຮົາຈະສົ່ງລະຫັດ OTP ໃຫ້ທ່ານ'
                  : 'We\'ll text you a 6-digit verification code',
              controller: _phoneController,
              enabled: !_isLoading,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                _PhoneNumberFormatter(),
              ],
              validator: Validators.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: () {
                if (!_isLoading) _submit();
              },
            ),
            const SizedBox(height: 22),

            BrandPrimaryButton(
              label: _tab == 0
                  ? Translations.get('send_otp', languageCode)
                  : (isLao ? 'ສ້າງບັນຊີດ້ວຍ OTP' : 'Continue with OTP'),
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 14),

            if (_tab == 0)
              _SecondaryButton(
                icon: Icons.bolt_rounded,
                label: Translations.get(
                  'login_with_pin_instead_⚡_faster',
                  languageCode,
                ),
                onTap: _isLoading
                    ? null
                    : () => context.push(AppRoutes.pinLogin),
              ),

            const SizedBox(height: 24),

            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: BrandFonts.body(
                    13,
                    color: BrandPalette.inkMuted,
                    weight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: _tab == 0
                          ? (isLao ? 'ຍັງບໍ່ມີບັນຊີ? ' : 'New here? ')
                          : (isLao ? 'ມີບັນຊີແລ້ວ? ' : 'Have an account? '),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = _tab == 0 ? 1 : 0),
                        child: Text(
                          _tab == 0
                              ? (isLao ? 'ສະໝັກ — ຟຣີ' : 'Sign up — free')
                              : (isLao ? 'ເຂົ້າສູ່ລະບົບ' : 'Sign in'),
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
            const SizedBox(height: 18),
            Center(
              child: Text(
                Translations.get(
                  'by_continuing_you_agree_to_our_terms_of_service_and_privacy_policy',
                  languageCode,
                ),
                style: BrandFonts.small(11, color: BrandPalette.inkMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
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

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: BrandPalette.cream,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: BrandPalette.border, width: 1),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: BrandPalette.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: BrandFonts.button(
                      14,
                      color: BrandPalette.ink,
                      weight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formats a Lao mobile number (without the +856 country code) as
/// "20 XXXX XXXX". A leading zero is stripped automatically so users
/// can type "020..." and still land on the canonical "20 ..." form.
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length > 10) digits = digits.substring(0, 10);

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 6) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
