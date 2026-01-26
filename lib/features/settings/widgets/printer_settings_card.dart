import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/services/printer_service.dart';
import '../providers/settings_provider.dart';
import '../screens/printer_connection_screen.dart';

class PrinterSettingsCard extends ConsumerStatefulWidget {
  const PrinterSettingsCard({super.key});

  @override
  ConsumerState<PrinterSettingsCard> createState() =>
      _PrinterSettingsCardState();
}

class _PrinterSettingsCardState extends ConsumerState<PrinterSettingsCard> {
  final _formKey = GlobalKey<FormState>();
  final _printerNameController = TextEditingController();
  bool _enableReceiptPrinting = true;
  bool _enableBarcodePrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    final settings = ref.read(settingsProvider);
    _printerNameController.text = settings.printerName;
    setState(() {
      _enableReceiptPrinting = settings.enableReceiptPrinting;
      _enableBarcodePrinting = settings.enableBarcodePrinting;
    });
  }

  @override
  void dispose() {
    _printerNameController.dispose();
    super.dispose();
  }

  Future<void> _savePrinterSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .savePrinterSettings(
          printerName: _printerNameController.text,
          printerAddress: settings.printerAddress,
          connectionType: settings.printerConnectionType,
          enableReceiptPrinting: _enableReceiptPrinting,
          enableBarcodePrinting: _enableBarcodePrinting,
          receiptHeader: settings.receiptHeader,
          receiptFooter: settings.receiptFooter,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer settings saved successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _navigateToConnectionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrinterConnectionScreen()),
    );
  }

  Future<void> _disconnectPrinter() async {
    final printerService = ref.read(settingsProvider.notifier).printerService;
    await printerService.disconnect();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer disconnected'),
          backgroundColor: AppTheme.info,
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
                'Printer Configuration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Connection Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      settingsState.isPrinterConnected
                          ? AppTheme.success.withOpacity(0.1)
                          : AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        settingsState.isPrinterConnected
                            ? AppTheme.success
                            : AppTheme.neutral300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          settingsState.isPrinterConnected
                              ? Icons.check_circle
                              : Icons.print_disabled,
                          color:
                              settingsState.isPrinterConnected
                                  ? AppTheme.success
                                  : AppTheme.neutral500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          settingsState.isPrinterConnected
                              ? 'Connected'
                              : 'Not Connected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                settingsState.isPrinterConnected
                                    ? AppTheme.success
                                    : AppTheme.neutral700,
                          ),
                        ),
                      ],
                    ),
                    if (settingsState.isPrinterConnected) ...[
                      const SizedBox(height: 8),
                      Text('Name: ${settingsState.printerName}'),
                      Text('Address: ${settingsState.printerAddress}'),
                      Text(
                        'Type: ${settingsState.printerConnectionType.name.toUpperCase()}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Connect Button
              if (!settingsState.isPrinterConnected)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToConnectionScreen,
                    icon: const Icon(Icons.add_link),
                    label: const Text('Connect Printer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

              // Disconnect Button
              if (settingsState.isPrinterConnected)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _disconnectPrinter,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect Printer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Printer Name
              TextFormField(
                controller: _printerNameController,
                decoration: const InputDecoration(
                  labelText: 'Printer Name',
                  hintText: 'e.g., Kitchen Printer, Receipt Printer',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a printer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Enable Receipt Printing
              SwitchListTile(
                title: const Text('Enable Receipt Printing'),
                subtitle: const Text(
                  'Print receipts automatically after checkout',
                ),
                value: _enableReceiptPrinting,
                onChanged: (value) {
                  setState(() {
                    _enableReceiptPrinting = value;
                  });
                },
              ),

              // Enable Barcode Printing
              SwitchListTile(
                title: const Text('Enable Barcode Printing'),
                subtitle: const Text('Print barcodes on receipts'),
                value: _enableBarcodePrinting,
                onChanged: (value) {
                  setState(() {
                    _enableBarcodePrinting = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      settingsState.isLoading ? null : _savePrinterSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    padding: const EdgeInsets.all(16),
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
                          : const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
