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
  String? _connectingDeviceId;
  String? _errorMessage;
  bool _isSunmiDevice = false;
  bool _isCheckingSunmi = false;
  bool _isSunmiConnecting = false;
  bool _isSunmiTesting = false;
  bool _isSunmiConnected = false;
  String? _sunmiStatusMessage;
  bool _sunmiStatusIsError = false;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '9100',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
    _checkSunmiDevice();
  }

  Future<void> _checkSunmiDevice() async {
    setState(() {
      _isCheckingSunmi = true;
    });

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final isSunmi = await printerService.isSunmiDevice();
      bool ready = false;
      if (isSunmi) {
        ready = await printerService.ensureSunmiConnected();
      }
      if (mounted) {
        setState(() {
          _isSunmiDevice = isSunmi;
          _isSunmiConnected = ready;
          _isCheckingSunmi = false;
          _sunmiStatusMessage =
              isSunmi
                  ? (ready
                      ? 'Sunmi printer ready'
                      : 'Sunmi printer not ready yet')
                  : null;
          _sunmiStatusIsError = isSunmi && !ready;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSunmiDevice = false;
          _isCheckingSunmi = false;
          _sunmiStatusMessage = 'Sunmi service unavailable: ${e.toString()}';
          _sunmiStatusIsError = true;
        });
      }
    }
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
      _connectingDeviceId = device.id;
      _errorMessage = null;
    });

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final success = await printerService.connectBluetooth(device);

      if (success) {
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
          _connectingDeviceId = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _connectingDeviceId = null;
      });
    } finally {
      setState(() {
        if (_connectingDeviceId == device.id) {
          _connectingDeviceId = null;
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
      if (mounted) {
        setState(() {
          _isSunmiConnecting = false;
        });
      }
    }
  }

  Future<void> _printSunmiTest() async {
    setState(() {
      _isSunmiTesting = true;
      _sunmiStatusMessage = null;
      _sunmiStatusIsError = false;
    });

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final ready = await printerService.ensureSunmiConnected();
      if (!ready) {
        throw Exception('Sunmi printer not ready');
      }

      final success = await printerService.testPrint();
      if (!success) {
        throw Exception('Failed to print test receipt');
      }

      setState(() {
        _sunmiStatusMessage = 'Test print completed';
        _sunmiStatusIsError = false;
      });
    } catch (e) {
      setState(() {
        _sunmiStatusMessage = 'Test print failed: ${e.toString()}';
        _sunmiStatusIsError = true;
      });
    } finally {
      setState(() {
        _isSunmiTesting = false;
      });
    }
  }

  Future<void> _connectSunmi() async {
    setState(() {
      _isSunmiConnecting = true;
      _errorMessage = null;
      _sunmiStatusMessage = null;
      _sunmiStatusIsError = false;
    });

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final success = await printerService.connectSunmi();

      if (success) {
        await ref
            .read(settingsProvider.notifier)
            .savePrinterSettings(
              printerName: 'Sunmi Built-in Printer',
              printerAddress: 'BUILT-IN',
              connectionType: PrinterConnectionType.sunmi,
              enableReceiptPrinting:
                  ref.read(settingsProvider).enableReceiptPrinting,
              enableBarcodePrinting:
                  ref.read(settingsProvider).enableBarcodePrinting,
              receiptHeader: ref.read(settingsProvider).receiptHeader,
              receiptFooter: ref.read(settingsProvider).receiptFooter,
            );

        final ready = await printerService.ensureSunmiConnected();
        if (mounted) {
          setState(() {
            _isSunmiConnected = ready;
            _sunmiStatusMessage =
                ready
                    ? 'Sunmi printer ready'
                    : 'Sunmi initialized with warnings';
            _sunmiStatusIsError = !ready;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ready
                    ? 'Connected to Sunmi printer'
                    : 'Sunmi connected (check logs)',
              ),
              backgroundColor: ready ? AppTheme.success : AppTheme.warning,
            ),
          );
          if (ready) {
            Navigator.pop(context);
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to Sunmi printer';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSunmiConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            Tab(text: 'Sunmi', icon: const Icon(Icons.print)),
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
                _buildSunmiTab(localization),
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

  Widget _buildSunmiTab(LocalizationState localization) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isCheckingSunmi)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (!_isSunmiDevice)
            Card(
              color: AppTheme.warning.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Not a Sunmi Device',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This device does not appear to be a Sunmi device with a built-in printer. Please use Bluetooth or WiFi connection instead.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.neutral700),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              'Sunmi Built-in Printer',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to the Sunmi device\'s built-in thermal printer.',
              style: TextStyle(color: AppTheme.neutral600),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.print, size: 80, color: AppTheme.primaryOrange),
                    const SizedBox(height: 16),
                    Text(
                      'Sunmi Device Detected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This device has a built-in printer ready to use.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.neutral600),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSunmiConnecting ? null : _connectSunmi,
                        icon:
                            _isSunmiConnecting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.link),
                        label: Text(
                          _isSunmiConnecting
                              ? 'Connecting...'
                              : 'Connect to Sunmi Printer',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  backgroundColor:
                      _isSunmiConnected
                          ? AppTheme.success.withOpacity(0.2)
                          : AppTheme.warning.withOpacity(0.2),
                  label: Text(
                    _isSunmiConnected ? 'Connected' : 'Not Ready',
                    style: TextStyle(
                      color:
                          _isSunmiConnected
                              ? AppTheme.success
                              : AppTheme.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isSunmiConnected
                      ? 'Sunmi printer is ready'
                      : 'Reconnect to enable printing',
                  style: TextStyle(color: AppTheme.neutral600),
                ),
              ],
            ),
            if (_sunmiStatusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _sunmiStatusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      _sunmiStatusIsError ? AppTheme.error : AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_isSunmiConnected && !_isSunmiTesting)
                        ? _printSunmiTest
                        : null,
                icon:
                    _isSunmiTesting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.receipt_long),
                label: Text(
                  _isSunmiTesting ? 'Printing...' : 'Print Test Receipt',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.all(16),
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
                          'Sunmi Printer Info',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• No additional setup required',
                      style: const TextStyle(color: AppTheme.neutral700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Built-in thermal printer',
                      style: const TextStyle(color: AppTheme.neutral700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Faster printing performance',
                      style: const TextStyle(color: AppTheme.neutral700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Optimized for Sunmi devices',
                      style: const TextStyle(color: AppTheme.neutral700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
