import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
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
      _isScanning = true;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Printer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bluetooth', icon: Icon(Icons.bluetooth)),
            Tab(text: 'WiFi', icon: Icon(Icons.wifi)),
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
              children: [_buildBluetoothTab(), _buildWiFiTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pair your Bluetooth printer in your device settings first, then scan for devices.',
                style: TextStyle(color: AppTheme.neutral600),
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
                  label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
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
                          'No devices found',
                          style: TextStyle(
                            color: AppTheme.neutral500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Scan for Devices" to start',
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
                              _isScanning
                                  ? null
                                  : () => _connectBluetooth(device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                          ),
                          child: const Text('Connect'),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildWiFiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your printer\'s IP address and port',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can find this information in your printer\'s network settings or configuration page.',
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
                    decoration: const InputDecoration(
                      labelText: 'IP Address',
                      hintText: '192.168.1.100',
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
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '9100',
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
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.info),
                      SizedBox(width: 8),
                      Text(
                        'Connection Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Make sure your printer and device are on the same WiFi network',
                    style: TextStyle(color: AppTheme.neutral700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Default port for thermal printers is usually 9100',
                    style: TextStyle(color: AppTheme.neutral700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Check your printer\'s manual for network configuration',
                    style: TextStyle(color: AppTheme.neutral700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• For DKT-E830: Access printer settings via web interface',
                    style: TextStyle(color: AppTheme.neutral700),
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
