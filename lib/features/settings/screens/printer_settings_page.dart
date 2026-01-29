import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/printer_settings_card.dart';
import '../widgets/receipt_settings_card.dart';

class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  ConsumerState<PrinterSettingsPage> createState() =>
      _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final localization = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(Translations.get('printer_settings', localization.languageCode)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: Translations.get('printer_config', localization.languageCode),
              icon: const Icon(Icons.settings),
            ),
            Tab(
              text: Translations.get('receipt_config', localization.languageCode),
              icon: const Icon(Icons.receipt),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Connection Status Card (shown always at top)
          if (!settingsState.isLoading)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      settingsState.isPrinterConnected
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color:
                          settingsState.isPrinterConnected
                              ? AppTheme.success
                              : AppTheme.error,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settingsState.isPrinterConnected
                                ? Translations.get('printer_connected', localization.languageCode)
                                : Translations.get('printer_disconnected', localization.languageCode),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settingsState.printerName.isNotEmpty
                                ? settingsState.printerName
                                : Translations.get('no_printer_configured', localization.languageCode),
                            style: TextStyle(color: AppTheme.neutral600),
                          ),
                        ],
                      ),
                    ),
                    if (settingsState.isPrinterConnected)
                      ElevatedButton(
                        onPressed:
                            () =>
                                ref
                                    .read(settingsProvider.notifier)
                                    .printTestReceipt(),
                        child: Text(Translations.get('test_print', localization.languageCode)),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child:
                settingsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        // Printer Configuration Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Translations.get('configure_your_printer', localization.languageCode),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  const PrinterSettingsCard(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Receipt Configuration Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Translations.get('configure_your_receipt', localization.languageCode),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  const ReceiptSettingsCard(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
