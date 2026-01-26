import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
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
        const SnackBar(
          content: Text('Receipt settings saved successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Receipt Customization',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Receipt Header
              TextFormField(
                controller: _receiptHeaderController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Receipt Header',
                  hintText: 'Restaurant Name\nAddress\nPhone Number',
                  border: OutlineInputBorder(),
                  helperText: 'Text to appear at the top of receipts',
                ),
              ),
              const SizedBox(height: 16),

              // Receipt Footer
              TextFormField(
                controller: _receiptFooterController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Receipt Footer',
                  hintText: 'Thank you for your business!\nVisit us again!',
                  border: OutlineInputBorder(),
                  helperText: 'Text to appear at the bottom of receipts',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a receipt footer';
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
                      const Text(
                        'Receipt Preview',
                        style: TextStyle(
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
                            const Text(
                              'Order #12345\nDate: Jan 6, 2026 10:30 AM',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Item 1        \$10.00\nItem 2        \$15.00\n-------------------\nTotal         \$25.00',
                              style: TextStyle(
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
                          : const Text('Save Receipt Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
