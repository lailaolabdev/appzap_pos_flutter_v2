import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:google_fonts/google_fonts.dart';

/// Clean brand palette — vivid orange primary, soft cream surfaces,
/// thin neutral borders. Mirrors the AppZap web POS look.
class BrandPalette {
  BrandPalette._();

  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryDeep = Color(0xFFE85A00);
  static const Color primarySoft = Color(0xFFFFB47A);

  static const Color cream = Color(0xFFFFF6EC);
  static const Color creamDeep = Color(0xFFFFE8D2);
  static const Color paper = Color(0xFFFFFFFF);

  static const Color ink = Color(0xFF1B140D);
  static const Color inkSoft = Color(0xFF52473D);
  static const Color inkMuted = Color(0xFF8A7E72);

  static const Color border = Color(0xFFEFE6DA);
  static const Color borderSoft = Color(0xFFF5EFE5);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
}

/// Type system: Plus Jakarta Sans for Latin/UI, Noto Sans Lao Looped
/// for Lao glyphs (closest to Phetsarath aesthetic in Google Fonts).
class BrandFonts {
  BrandFonts._();

  static String get _laoLooped =>
      GoogleFonts.notoSansLaoLooped().fontFamily!;
  static String get _laoSans => GoogleFonts.notoSansLao().fontFamily!;

  static TextStyle display(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w700,
    double height = 1.15,
    double letterSpacing = -0.4,
  }) =>
      GoogleFonts.plusJakartaSans(
        textStyle: TextStyle(
          fontSize: size,
          height: height,
          letterSpacing: letterSpacing,
          color: color ?? BrandPalette.ink,
          fontWeight: weight,
          fontFamilyFallback: [_laoLooped, _laoSans],
        ),
      );

  static TextStyle body(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.plusJakartaSans(
        textStyle: TextStyle(
          fontSize: size,
          height: height,
          letterSpacing: letterSpacing,
          color: color ?? BrandPalette.inkSoft,
          fontWeight: weight,
          fontFamilyFallback: [_laoLooped, _laoSans],
        ),
      );

  static TextStyle button(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) =>
      GoogleFonts.plusJakartaSans(
        textStyle: TextStyle(
          fontSize: size,
          letterSpacing: 0.1,
          color: color ?? BrandPalette.paper,
          fontWeight: weight,
          fontFamilyFallback: [_laoLooped, _laoSans],
        ),
      );

  static TextStyle small(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.2,
  }) =>
      GoogleFonts.plusJakartaSans(
        textStyle: TextStyle(
          fontSize: size,
          letterSpacing: letterSpacing,
          color: color ?? BrandPalette.inkMuted,
          fontWeight: weight,
          fontFamilyFallback: [_laoLooped, _laoSans],
        ),
      );
}

/// Responsive auth shell.
/// Wide (>= 980px): orange hero panel on the left, white form on the right.
/// Narrow: condensed orange band on top, form fills the rest.
class AuthShell extends StatelessWidget {
  final Widget form;
  final HeroContent hero;
  final Widget? topRight;

  const AuthShell({
    super.key,
    required this.form,
    required this.hero,
    this.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.paper,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _BrandPanel(content: hero, compact: false),
                ),
                Expanded(
                  flex: 1,
                  child: _FormPane(topRight: topRight, child: form),
                ),
              ],
            );
          }
          return Column(
            children: [
              _BrandPanel(content: hero, compact: true),
              Expanded(
                child: _FormPane(topRight: topRight, child: form),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Content shown inside the orange hero panel.
class HeroContent {
  final String badge;
  final String headline;
  final String subline;
  final List<String> features;

  const HeroContent({
    required this.badge,
    required this.headline,
    required this.subline,
    required this.features,
  });
}

class _BrandPanel extends StatelessWidget {
  final HeroContent content;
  final bool compact;
  const _BrandPanel({required this.content, required this.compact});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        height: compact ? null : double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BrandPalette.primary, BrandPalette.primaryDeep],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _FoodDoodles(compact: compact)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 24 : 56,
                compact ? 24 : 56,
                compact ? 24 : 56,
                compact ? 24 : 40,
              ),
              child: compact
                  ? _CompactHero(content: content)
                  : _FullHero(content: content),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactHero extends StatelessWidget {
  final HeroContent content;
  const _CompactHero({required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _AppZapMark(size: 38, onColor: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AppZap POS',
                style: BrandFonts.display(
                  18,
                  color: BrandPalette.paper,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content.badge,
                style: BrandFonts.small(
                  11,
                  color: BrandPalette.paper.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullHero extends StatelessWidget {
  final HeroContent content;
  const _FullHero({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: BrandPalette.paper.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: BrandPalette.paper.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: BrandPalette.paper,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'V2',
                      style: BrandFonts.small(
                        10.5,
                        color: BrandPalette.primary,
                        weight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    content.badge,
                    style: BrandFonts.small(
                      12,
                      color: BrandPalette.paper,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              content.headline,
              style: BrandFonts.display(
                42,
                color: BrandPalette.paper,
                weight: FontWeight.w800,
                height: 1.18,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                content.subline,
                style: BrandFonts.body(
                  15,
                  color: BrandPalette.paper.withValues(alpha: 0.92),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ...content.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FeatureRow(text: f),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: BrandPalette.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BrandPalette.success,
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'All systems operational',
              style: BrandFonts.small(
                12,
                color: BrandPalette.paper.withValues(alpha: 0.85),
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: BrandPalette.paper.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            border: Border.all(
              color: BrandPalette.paper.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: BrandPalette.paper,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: BrandFonts.body(
              14.5,
              color: BrandPalette.paper.withValues(alpha: 0.95),
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hand-drawn food / drink stickers tiled across the hero panel —
/// uses the project's sticker-3.png pattern (dense food doodles)
/// as the main backdrop, with smaller sticker accents floated above.
class _FoodDoodles extends StatelessWidget {
  final bool compact;
  const _FoodDoodles({required this.compact});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Main tiled food-doodle pattern.
          Positioned.fill(
            child: Opacity(
              opacity: compact ? 0.35 : 0.45,
              child: Image.asset(
                'assets/stickers/sticker-3.png',
                repeat: ImageRepeat.repeat,
                color: BrandPalette.paper.withValues(alpha: 0.95),
                colorBlendMode: BlendMode.srcIn,
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
          if (!compact) ...[
            // Big bowl accent in the lower-right.
            Positioned(
              right: -20,
              bottom: 60,
              child: Opacity(
                opacity: 0.55,
                child: Image.asset(
                  'assets/stickers/sticker-1.png',
                  width: 180,
                  color: BrandPalette.paper.withValues(alpha: 0.85),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            // Small motion lines top-right.
            Positioned(
              top: 80,
              right: 40,
              child: Opacity(
                opacity: 0.45,
                child: Image.asset(
                  'assets/stickers/sticker-2.png',
                  width: 110,
                  color: BrandPalette.paper.withValues(alpha: 0.80),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            // Squiggle arrows centre-left.
            Positioned(
              left: 30,
              top: 200,
              child: Opacity(
                opacity: 0.40,
                child: Image.asset(
                  'assets/stickers/sticker-7.png',
                  width: 130,
                  color: BrandPalette.paper.withValues(alpha: 0.75),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// White right-hand pane that hosts the form.
class _FormPane extends StatelessWidget {
  final Widget child;
  final Widget? topRight;
  const _FormPane({required this.child, this.topRight});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 480;
          final pad = isWide ? 48.0 : 22.0;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 18, pad, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    if (topRight != null) topRight!,
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: child,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
                child: Row(
                  children: [
                    Text(
                      '© ${DateTime.now().year} AppZap',
                      style: BrandFonts.small(
                        11,
                        color: BrandPalette.inkMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: BrandPalette.inkMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'v1.0.0',
                      style: BrandFonts.small(
                        11,
                        color: BrandPalette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// AppZap brand mark — uses the project's logo asset, optionally
/// rendered in white when placed on the orange brand panel.
class AppZapMark extends StatelessWidget {
  final double size;
  final bool onColor;
  const AppZapMark({super.key, this.size = 56, this.onColor = false});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
    if (onColor) {
      // Knock out the original colour so the logo reads as a solid
      // white silhouette on the orange hero.
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          BrandPalette.paper,
          BlendMode.srcIn,
        ),
        child: image,
      );
    }
    return image;
  }
}

class _AppZapMark extends StatelessWidget {
  final double size;
  final bool onColor;
  const _AppZapMark({required this.size, required this.onColor});

  @override
  Widget build(BuildContext context) =>
      AppZapMark(size: size, onColor: onColor);
}

/// Pill-style segmented switcher — used for Login / Register and OTP / PIN.
class BrandSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;

  const BrandSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: BrandPalette.cream,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: BrandPalette.border, width: 1),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isOn = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isOn ? BrandPalette.paper : Colors.transparent,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: isOn
                      ? [
                          BoxShadow(
                            color: BrandPalette.ink.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: BrandFonts.button(
                    14,
                    color: isOn ? BrandPalette.primary : BrandPalette.inkMuted,
                    weight: isOn ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Rounded language pill: ລາວ | EN.
class LangSwitch extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const LangSwitch({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BrandPalette.cream,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: BrandPalette.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langChip('lo', 'ລາວ'),
          _langChip('en', 'EN'),
        ],
      ),
    );
  }

  Widget _langChip(String code, String label) {
    final isOn = current == code;
    return GestureDetector(
      onTap: () => onChanged(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isOn
              ? const LinearGradient(
                  colors: [BrandPalette.primary, BrandPalette.primaryDeep],
                )
              : null,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          label,
          style: BrandFonts.button(
            12,
            color: isOn ? BrandPalette.paper : BrandPalette.inkSoft,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Soft cream-filled input with rounded corners and focus ring.
class BrandField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final String? prefixText;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool obscureText;

  const BrandField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.prefix,
    this.suffix,
    this.prefixText,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.obscureText = false,
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          enabled: enabled,
          autofocus: autofocus,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          style: BrandFonts.body(
            15.5,
            color: BrandPalette.ink,
            weight: FontWeight.w600,
          ),
          cursorColor: BrandPalette.primary,
          cursorWidth: 1.6,
          decoration: InputDecoration(
            isDense: false,
            filled: true,
            fillColor: BrandPalette.cream,
            hintText: hint,
            hintStyle: BrandFonts.body(
              15,
              color: BrandPalette.inkMuted,
              weight: FontWeight.w400,
            ),
            prefixIcon: prefix,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 64,
              minHeight: 24,
            ),
            prefixText: prefixText,
            prefixStyle: BrandFonts.body(
              15.5,
              color: BrandPalette.ink,
              weight: FontWeight.w600,
            ),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: _border(BrandPalette.border, 1),
            enabledBorder: _border(BrandPalette.border, 1),
            focusedBorder: _border(BrandPalette.primary, 1.6),
            errorBorder: _border(BrandPalette.danger, 1),
            focusedErrorBorder: _border(BrandPalette.danger, 1.6),
            errorStyle: BrandFonts.small(12, color: BrandPalette.danger),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Dedicated phone-number field with a fixed +856 prefix tab.
/// Designed to be very tappable and easy to read — no nested cards,
/// no flag noise; just a single rounded surface with a thin divider
/// between the country code and the input area.
class BrandPhoneField extends StatefulWidget {
  final String label;
  final String hint;
  final String helper;
  final String countryCode;
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  const BrandPhoneField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '20 1234 5678',
    this.helper = '',
    this.countryCode = '+856',
    this.enabled = true,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<BrandPhoneField> createState() => _BrandPhoneFieldState();
}

class _BrandPhoneFieldState extends State<BrandPhoneField> {
  final FocusNode _focus = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focus.hasFocus;
    final hasError = _errorText != null;
    final borderColor = hasError
        ? BrandPalette.danger
        : isFocused
            ? BrandPalette.primary
            : BrandPalette.border;
    final borderWidth = (isFocused || hasError) ? 1.6 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: BrandFonts.body(
            13,
            color: BrandPalette.ink,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: BrandPalette.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: BrandPalette.primary.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Text(
                    widget.countryCode,
                    style: BrandFonts.body(
                      16,
                      color: BrandPalette.ink,
                      weight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  color: BrandPalette.border,
                ),
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.phone,
                    inputFormatters: widget.inputFormatters,
                    textInputAction:
                        widget.textInputAction ?? TextInputAction.done,
                    onFieldSubmitted: (_) => widget.onSubmitted?.call(),
                    style: BrandFonts.body(
                      18,
                      color: BrandPalette.ink,
                      weight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                    cursorColor: BrandPalette.primary,
                    cursorWidth: 1.8,
                    decoration: InputDecoration(
                      isDense: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      hintText: widget.hint,
                      hintStyle: BrandFonts.body(
                        18,
                        color: BrandPalette.inkMuted.withValues(alpha: 0.55),
                        weight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                      // We render error text below ourselves, so suppress the
                      // built-in error UI from the form field.
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                    validator: (value) {
                      final result = widget.validator?.call(value);
                      // Sync our local error state for border colouring.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        if (_errorText != result) {
                          setState(() => _errorText = result);
                        }
                      });
                      return result;
                    },
                    onChanged: (v) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                      widget.onChanged?.call(v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: BrandPalette.danger,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _errorText!,
                  style: BrandFonts.small(
                    12,
                    color: BrandPalette.danger,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helper.isNotEmpty) ...[
          const SizedBox(height: 10),
          HelperHint(message: widget.helper),
        ],
      ],
    );
  }
}

/// Pill-shaped primary action button.
class BrandPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;

  const BrandPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [BrandPalette.primary, BrandPalette.primaryDeep],
                )
              : LinearGradient(
                  colors: [
                    BrandPalette.primary.withValues(alpha: 0.45),
                    BrandPalette.primaryDeep.withValues(alpha: 0.45),
                  ],
                ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: BrandPalette.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(40),
            splashColor: BrandPalette.paper.withValues(alpha: 0.18),
            highlightColor: BrandPalette.paper.withValues(alpha: 0.08),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          BrandPalette.paper,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: BrandFonts.button(
                            15.5,
                            color: BrandPalette.paper,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 10),
                          Icon(
                            trailingIcon,
                            size: 18,
                            color: BrandPalette.paper,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle helper line shown beneath the form (green dot + message).
class HelperHint extends StatelessWidget {
  final String message;
  final Color dotColor;
  const HelperHint({
    super.key,
    required this.message,
    this.dotColor = BrandPalette.success,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: Text(
            message,
            style: BrandFonts.small(
              12.5,
              color: BrandPalette.inkSoft,
              weight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
