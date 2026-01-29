import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../widgets/printer_settings_card.dart';

class PrinterConfigurationPage extends ConsumerStatefulWidget {
  const PrinterConfigurationPage({super.key});

  @override
  ConsumerState<PrinterConfigurationPage> createState() =>
      _PrinterConfigurationPageState();
}

class _PrinterConfigurationPageState
    extends ConsumerState<PrinterConfigurationPage> {
  @override
  Widget build(BuildContext context) {
    final localization = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          Translations.get('printer_configuration', localization.languageCode),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get(
                        'configure_your_printer',
                        localization.languageCode,
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const PrinterSettingsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
