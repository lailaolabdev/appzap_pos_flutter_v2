import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../providers/settings_provider.dart';

class ReceiptSettingsCard extends ConsumerStatefulWidget {
  const ReceiptSettingsCard({super.key});

  @override
  ConsumerState<ReceiptSettingsCard> createState() =>
      _ReceiptSettingsCardState();
}

class _ReceiptSettingsCardState extends ConsumerState<ReceiptSettingsCard> {
  final _formKey = GlobalKey<FormState>();
  final _receiptHeaderController = TextEditingController();
  final _receiptFooterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    final settings = ref.read(settingsProvider);
    _receiptHeaderController.text = settings.receiptHeader;
    _receiptFooterController.text = settings.receiptFooter;
  }

  @override
  void dispose() {
    _receiptHeaderController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  Future<void> _saveReceiptSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final currentSettings = ref.read(settingsProvider);
    final localization = ref.read(localizationProvider);

    await ref
        .read(settingsProvider.notifier)
        .savePrinterSettings(
          printerName: currentSettings.printerName,
          printerAddress: currentSettings.printerAddress,
          connectionType: currentSettings.printerConnectionType,
          enableReceiptPrinting: currentSettings.enableReceiptPrinting,
          enableBarcodePrinting: currentSettings.enableBarcodePrinting,
          receiptHeader: _receiptHeaderController.text,
          receiptFooter: _receiptFooterController.text,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.get(
              'receipt_settings_saved',
              localization.languageCode,
            ),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final localization = ref.watch(localizationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.get(
                  'receipt_customization',
                  localization.languageCode,
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Receipt Header
              TextFormField(
                controller: _receiptHeaderController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: Translations.get(
                    'receipt_header',
                    localization.languageCode,
                  ),
                  hintText: Translations.get(
                    'receipt_header_hint',
                    localization.languageCode,
                  ),
                  border: const OutlineInputBorder(),
                  helperText: Translations.get(
                    'receipt_header_helper',
                    localization.languageCode,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Receipt Footer
              TextFormField(
                controller: _receiptFooterController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: Translations.get(
                    'receipt_footer',
                    localization.languageCode,
                  ),
                  hintText: Translations.get(
                    'receipt_footer_hint',
                    localization.languageCode,
                  ),
                  border: const OutlineInputBorder(),
                  helperText: Translations.get(
                    'receipt_footer_helper',
                    localization.languageCode,
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return Translations.get(
                      'receipt_footer_required',
                      localization.languageCode,
                    );
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Preview Card
              Card(
                color: AppTheme.neutral100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get(
                          'receipt_preview',
                          localization.languageCode,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.neutral300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Header
                            if (_receiptHeaderController.text.isNotEmpty) ...[
                              Text(
                                _receiptHeaderController.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Divider(),
                            ],

                            // Sample content
                            Text(
                              Translations.get(
                                'receipt_sample_date',
                                localization.languageCode,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Translations.get(
                                'receipt_sample_items',
                                localization.languageCode,
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),

                            // Footer
                            if (_receiptFooterController.text.isNotEmpty) ...[
                              const Divider(),
                              Text(
                                _receiptFooterController.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      settingsState.isLoading ? null : _saveReceiptSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                  ),
                  child:
                      settingsState.isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            Translations.get(
                              'save_receipt_settings',
                              localization.languageCode,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
