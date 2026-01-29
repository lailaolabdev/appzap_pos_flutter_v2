import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/translations.dart';
import '../../core/providers/localization_provider.dart';

class AppText extends ConsumerWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.translationKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = ref.watch(localizationProvider);
    final text = Translations.get(translationKey, localization.languageCode);

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// Helper function for use in ConsumerWidget/ConsumerStatefulWidget
String translateText(String key, WidgetRef ref) {
  final localization = ref.watch(localizationProvider);
  return Translations.get(key, localization.languageCode);
}
