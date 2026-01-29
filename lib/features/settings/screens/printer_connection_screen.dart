import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/services/printer_service.dart';
import '../providers/settings_provider.dart';

class PrinterConnectionScreen extends ConsumerStatefulWidget {
  const PrinterConnectionScreen({super.key});

  @override
  ConsumerState<PrinterConnectionScreen> createState() =>
      _PrinterConnectionScreenState();
}

class _PrinterConnectionScreenState
    extends ConsumerState<PrinterConnectionScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  List<PrinterDevice> _bluetoothDevices = [];
  List<PrinterDevice> _wifiDevices = [];
  bool _isScanning = false;
  String? _connectingDeviceId; // Track which device is currently connecting
  String? _errorMessage;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '9100',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _scanBluetoothDevices() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final devices = await printerService.scanBluetoothDevices();
      setState(() {
        _bluetoothDevices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isScanning = false;
      });
    }
  }

  Future<void> _connectBluetooth(PrinterDevice device) async {
    setState(() {
      _connectingDeviceId = device.id; // Set loading for this specific device
      _errorMessage = null;
    });

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final success = await printerService.connectBluetooth(device);

      if (success) {
        // Save to settings
        await ref
            .read(settingsProvider.notifier)
            .savePrinterSettings(
              printerName: device.name,
              printerAddress: device.address,
              connectionType: PrinterConnectionType.bluetooth,
              enableReceiptPrinting:
                  ref.read(settingsProvider).enableReceiptPrinting,
              enableBarcodePrinting:
                  ref.read(settingsProvider).enableBarcodePrinting,
              receiptHeader: ref.read(settingsProvider).receiptHeader,
              receiptFooter: ref.read(settingsProvider).receiptFooter,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to Bluetooth printer'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to printer';
          _connectingDeviceId = null; // Clear loading state
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _connectingDeviceId = null; // Clear loading state
      });
    } finally {
      setState(() {
        if (_connectingDeviceId == device.id) {
          _connectingDeviceId = null; // Clear loading state for this device
        }
      });
    }
  }

  Future<void> _connectWiFi() async {
    final ip = _ipController.text.trim();
    final portStr = _portController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter IP address';
      });
      return;
    }

    final port = int.tryParse(portStr) ?? 9100;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final success = await printerService.connectWiFi(ip, port: port);

      if (success) {
        // Save to settings
        await ref
            .read(settingsProvider.notifier)
            .savePrinterSettings(
              printerName: 'Network Printer',
              printerAddress: '$ip:$port',
              connectionType: PrinterConnectionType.wifi,
              enableReceiptPrinting:
                  ref.read(settingsProvider).enableReceiptPrinting,
              enableBarcodePrinting:
                  ref.read(settingsProvider).enableBarcodePrinting,
              receiptHeader: ref.read(settingsProvider).receiptHeader,
              receiptFooter: ref.read(settingsProvider).receiptFooter,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to WiFi printer'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to printer';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final localization = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translations.get('connect_printer', localization.languageCode),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: Translations.get('bluetooth', localization.languageCode),
              icon: const Icon(Icons.bluetooth),
            ),
            Tab(
              text: Translations.get('wifi', localization.languageCode),
              icon: const Icon(Icons.wifi),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.error.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBluetoothTab(localization),
                _buildWiFiTab(localization),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothTab(LocalizationState localization) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.get(
                  'pair_bluetooth_first',
                  localization.languageCode,
                ),
                style: const TextStyle(color: AppTheme.neutral600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanBluetoothDevices,
                  icon:
                      _isScanning
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.bluetooth_searching),
                  label: Text(
                    _isScanning
                        ? Translations.get(
                          'scanning',
                          localization.languageCode,
                        )
                        : Translations.get(
                          'scan_for_devices',
                          localization.languageCode,
                        ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _bluetoothDevices.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 64,
                          color: AppTheme.neutral300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Translations.get(
                            'no_devices_found',
                            localization.languageCode,
                          ),
                          style: TextStyle(
                            color: AppTheme.neutral500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Translations.get(
                            'tap_scan_to_start',
                            localization.languageCode,
                          ),
                          style: TextStyle(
                            color: AppTheme.neutral400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _bluetoothDevices.length,
                    itemBuilder: (context, index) {
                      final device = _bluetoothDevices[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.info,
                          child: Icon(Icons.print, color: Colors.white),
                        ),
                        title: Text(
                          device.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(device.address),
                        trailing: ElevatedButton(
                          onPressed:
                              _connectingDeviceId == device.id
                                  ? null
                                  : () => _connectBluetooth(device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                          ),
                          child:
                              _connectingDeviceId == device.id
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text('Connect'),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildWiFiTab(LocalizationState localization) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translations.get('enter_ip_address', localization.languageCode),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            Translations.get(
              'find_info_in_settings',
              localization.languageCode,
            ),
            style: TextStyle(color: AppTheme.neutral600),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: Translations.get(
                        'ip_address',
                        localization.languageCode,
                      ),
                      hintText: Translations.get(
                        'ip_hint',
                        localization.languageCode,
                      ),
                      prefixIcon: Icon(Icons.router),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: Translations.get(
                        'port',
                        localization.languageCode,
                      ),
                      hintText: Translations.get(
                        'port_hint',
                        localization.languageCode,
                      ),
                      prefixIcon: Icon(Icons.settings_ethernet),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _connectWiFi,
                      icon:
                          _isScanning
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.wifi),
                      label: Text(
                        _isScanning ? 'Connecting...' : 'Connect to Printer',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: AppTheme.info.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.info),
                      const SizedBox(width: 8),
                      Text(
                        Translations.get(
                          'connection_tips',
                          localization.languageCode,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Translations.get(
                      'same_wifi_network',
                      localization.languageCode,
                    ),
                    style: const TextStyle(color: AppTheme.neutral700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Translations.get(
                      'default_port_9100',
                      localization.languageCode,
                    ),
                    style: const TextStyle(color: AppTheme.neutral700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Translations.get('check_manual', localization.languageCode),
                    style: const TextStyle(color: AppTheme.neutral700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Translations.get(
                      'dkt_e830_tips',
                      localization.languageCode,
                    ),
                    style: const TextStyle(color: AppTheme.neutral700),
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
