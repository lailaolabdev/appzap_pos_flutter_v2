import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _restaurantIdController.dispose();
    super.dispose();
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
      return error.message;
    }
    return Translations.get('registration_failed_please_try_again', code);
  }

  String _pinsMismatchLabel(String code) =>
      code == 'lo' ? 'ລະຫັດ PIN ບໍ່ກົງກັນ' : 'PINs do not match';

  Future<void> _handleRegister() async {
    final code = ref.read(localizationProvider).languageCode;
    if (_pinController.text != _confirmPinController.text) {
      setState(() => _pinError = _pinsMismatchLabel(code));
      return;
    }
    final pinError = Validators.pin(_pinController.text);
    if (pinError != null) {
      setState(() => _pinError = pinError);
      return;
    }
    setState(() {
      _pinError = null;
      _registrationError = null;
      _isLoading = true;
    });
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _registrationError = _getErrorMessage(e, code);
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    final code = ref.read(localizationProvider).languageCode;
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_restaurantIdController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: BrandPalette.primary,
            content: Text(
              Translations.get(
                'please_enter_your_store_restaurant_id',
                code,
              ),
              style: BrandFonts.body(14, color: BrandPalette.paper),
            ),
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
    final code = ref.watch(localizationProvider).languageCode;
    final isLao = code == 'lo';

    final hero = HeroContent(
      badge: isLao ? 'ສ້າງບັນຊີ' : 'Set up your kitchen',
      headline: isLao
          ? 'ເຮັດໃຫ້\nຮ້ານຂອງທ່ານ\nພ້ອມແລ້ວ.'
          : 'Get your\nrestaurant set\nup in minutes.',
      subline: isLao
          ? 'ສາມຂັ້ນຕອນສັ້ນໆ — ຊື່, ລະຫັດຮ້ານ, ແລ້ວສ້າງລະຫັດ PIN ສຳລັບເຂົ້າສູ່ລະບົບໄວ.'
          : 'Three short steps — your name, your store ID, then a PIN for fast daily sign-ins.',
      features: isLao
          ? const [
              'ບໍ່ມີຄ່າເລີ່ມຕົ້ນ ໃຊ້ໄດ້ທັນທີ',
              'ນຳເຂົ້າເມນູ ແລະ ສາງເບື້ອງຫຼັງ',
              'ສະຫຼັບລະຫວ່າງສາຂາໃນຄຣິກດຽວ',
            ]
          : const [
              'Free to start, ready in seconds',
              'Import menus & inventory later',
              'Switch between branches in one tap',
            ],
    );

    return AuthShell(
      hero: hero,
      topRight: _LangPill(),
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _BackChip(onTap: _previousStep),
              const SizedBox(width: 14),
              Expanded(
                child: _StepProgress(
                  step: _currentStep,
                  total: 3,
                  isLao: isLao,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_currentStep),
              child: _buildCurrentStep(code, isLao),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(String code, bool isLao) {
    switch (_currentStep) {
      case 0:
        return _stepWrapper(
          eyebrow: isLao ? 'ຂັ້ນຕອນ 1 ຈາກ 3' : 'Step 1 of 3',
          title: isLao ? 'ເຈົ້າຊື່ຫຍັງ?' : 'What\'s your name?',
          subtitle: isLao
              ? 'ຊື່ນີ້ຈະປະກົດຢູ່ໃບຮັບເງິນທຸກໃບ.'
              : 'It will appear on every receipt you print.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandField(
                  label: Translations.get('full_name', code),
                  hint: Translations.get('enter_your_full_name', code),
                  controller: _nameController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.name,
                  autofocus: true,
                ),
                const SizedBox(height: 24),
                BrandPrimaryButton(
                  label: Translations.get('continue', code),
                  onPressed: _isLoading ? null : _nextStep,
                ),
                const SizedBox(height: 16),
                _PhoneFootnote(phone: widget.phone, isLao: isLao),
              ],
            ),
          ),
        );
      case 1:
        return _stepWrapper(
          eyebrow: isLao ? 'ຂັ້ນຕອນ 2 ຈາກ 3' : 'Step 2 of 3',
          title: isLao ? 'ຮ້ານໃດ?' : 'Which kitchen?',
          subtitle: isLao
              ? 'ຖາມຜູ້ຈັດການຂອງທ່ານສຳລັບລະຫັດຮ້ານ.'
              : 'Ask your manager for the store ID — it\'s a short code.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BrandField(
                label: Translations.get('store_restaurant_id', code),
                hint: Translations.get('enter_store_id', code),
                controller: _restaurantIdController,
                enabled: !_isLoading,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              BrandPrimaryButton(
                label: Translations.get('continue', code),
                onPressed: _isLoading ? null : _nextStep,
              ),
              const SizedBox(height: 16),
              _PhoneFootnote(phone: widget.phone, isLao: isLao),
            ],
          ),
        );
      case 2:
        return _stepWrapper(
          eyebrow: isLao ? 'ຂັ້ນຕອນ 3 ຈາກ 3' : 'Step 3 of 3',
          title: isLao ? 'ສ້າງລະຫັດ PIN' : 'Set a quick PIN',
          subtitle: isLao
              ? 'ໃຊ້ສຳລັບເຂົ້າສູ່ລະບົບໄວ ໃນຄາບເຮັດວຽກຕໍ່ໄປ.'
              : 'You\'ll punch this in for fast sign-ins between shifts.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PinBlock(
                label: Translations.get('enter_pin', code),
                controller: _pinController,
                enabled: !_isLoading,
                onChanged: (_) {
                  if (_pinError != null) setState(() => _pinError = null);
                },
              ),
              const SizedBox(height: 18),
              _PinBlock(
                label: Translations.get('confirm_pin', code),
                controller: _confirmPinController,
                enabled: !_isLoading,
                onChanged: (_) {
                  if (_pinError != null) setState(() => _pinError = null);
                },
              ),
              if (_pinError != null || _registrationError != null) ...[
                const SizedBox(height: 18),
                ErrorBanner(
                  key: ValueKey(_pinError ?? _registrationError),
                  message: _registrationError ?? _pinError!,
                  title: _registrationError != null
                      ? Translations.get('registration_failed', code)
                      : Translations.get('invalid_pin', code),
                  onDismiss: () => setState(() {
                    _pinError = null;
                    _registrationError = null;
                  }),
                  onRetry: _registrationError != null
                      ? () => setState(() => _registrationError = null)
                      : null,
                ),
              ],
              const SizedBox(height: 24),
              BrandPrimaryButton(
                label: Translations.get('create_account', code),
                onPressed: _isLoading ? null : _handleRegister,
                isLoading: _isLoading,
                trailingIcon: Icons.east_rounded,
              ),
              const SizedBox(height: 16),
              _PhoneFootnote(phone: widget.phone, isLao: isLao),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepWrapper({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: AppZapMark(size: 56)),
        const SizedBox(height: 18),
        Center(
          child: Text(
            eyebrow,
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
          title,
          textAlign: TextAlign.center,
          style: BrandFonts.display(
            26,
            weight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: BrandFonts.body(
            14,
            color: BrandPalette.inkMuted,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int step;
  final int total;
  final bool isLao;
  const _StepProgress({
    required this.step,
    required this.total,
    required this.isLao,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isOn = i <= step;
        final isCurrent = i == step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              height: 6,
              decoration: BoxDecoration(
                color: isOn ? BrandPalette.primary : BrandPalette.border,
                borderRadius: BorderRadius.circular(40),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: BrandPalette.primary.withValues(alpha: 0.40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
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

class _PhoneFootnote extends StatelessWidget {
  final String phone;
  final bool isLao;
  const _PhoneFootnote({required this.phone, required this.isLao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BrandPalette.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BrandPalette.border, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 18,
            color: BrandPalette.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: BrandFonts.body(
                  12.5,
                  color: BrandPalette.inkMuted,
                  weight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: isLao ? 'ຢືນຢັນເບີ ' : 'Verified for ',
                  ),
                  TextSpan(
                    text: '+856 ${Validators.formatPhone(phone)}',
                    style: BrandFonts.body(
                      12.5,
                      color: BrandPalette.ink,
                      weight: FontWeight.w700,
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

class _PinBlock extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _PinBlock({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BrandFonts.body(
            13,
            color: BrandPalette.ink,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        PinCodeTextField(
          appContext: context,
          controller: controller,
          length: 4,
          keyboardType: TextInputType.number,
          obscureText: true,
          obscuringCharacter: '●',
          animationType: AnimationType.fade,
          enabled: enabled,
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
            borderWidth: 1,
            activeBorderWidth: 1.6,
            selectedBorderWidth: 1.6,
            inactiveBorderWidth: 1,
          ),
          enableActiveFill: true,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
