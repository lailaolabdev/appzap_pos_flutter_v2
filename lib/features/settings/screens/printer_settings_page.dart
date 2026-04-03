import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/services/printer_service.dart';
import '../providers/settings_provider.dart';

// ═══════════════════════════════════════════════════════════════════
// Printers List Page
// ═══════════════════════════════════════════════════════════════════

class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  ConsumerState<PrinterSettingsPage> createState() =>
      _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage> {
  final Set<String> _selectedIds = {};

  bool get _isSelectMode => _selectedIds.isNotEmpty;

  void _exitSelection() => setState(() => _selectedIds.clear());

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final lang = ref.read(localizationProvider).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(Translations.get('delete', lang)),
            content: Text(Translations.get('delete_printer_confirm', lang)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(Translations.get('cancel', lang)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: Text(
                  Translations.get('delete', lang),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).deletePrinters(_selectedIds);
      setState(() => _selectedIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final lang = ref.watch(localizationProvider).languageCode;
    final printers = settings.printers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar:
          _isSelectMode
              ? AppBar(
                backgroundColor: AppTheme.primaryOrangeDark,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _exitSelection,
                ),
                title: Text(
                  '${_selectedIds.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: _deleteSelected,
                  ),
                ],
              )
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  Translations.get('printers', lang),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      body:
          printers.isEmpty
              ? _buildEmptyState(lang)
              : _buildPrinterList(printers, lang),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreatePrinter(),
        backgroundColor: AppTheme.primaryOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryOrangeBackground,
            ),
            child: const Icon(
              Icons.print,
              size: 56,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            Translations.get('no_printers_yet', lang),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              Translations.get('connect_printers_hint', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterList(List<SavedPrinter> printers, String lang) {
    return ListView.separated(
      itemCount: printers.length,
      separatorBuilder:
          (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final printer = printers[i];
        final isSelected = _selectedIds.contains(printer.id);

        return InkWell(
          onTap:
              _isSelectMode
                  ? () => _toggleSelection(printer.id)
                  : () => _openCreatePrinter(printer: printer),
          onLongPress: () => _toggleSelection(printer.id),
          child: Container(
            color:
                isSelected
                    ? AppTheme.primaryOrange.withValues(alpha: 0.12)
                    : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected
                            ? AppTheme.primaryOrangeDark
                            : Colors.grey.shade100,
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                          : Icon(
                            _getInterfaceIcon(printer.connectionType),
                            color: Colors.grey.shade500,
                            size: 24,
                          ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getInterfaceLabel(printer.connectionType),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isSelectMode)
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getInterfaceIcon(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.sunmi:
        return Icons.phone_android;
      case PrinterConnectionType.wifi:
        return Icons.wifi;
      default:
        return Icons.print;
    }
  }

  String _getInterfaceLabel(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.bluetooth:
        return 'Bluetooth';
      case PrinterConnectionType.sunmi:
        return 'Sunmi';
      case PrinterConnectionType.wifi:
        return 'Ethernet / WiFi';
      default:
        return 'Other';
    }
  }

  void _openCreatePrinter({SavedPrinter? printer}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePrinterPage(existingPrinter: printer),
      ),
    ).then((_) {
      // Refresh when coming back
      if (mounted) setState(() {});
    });
  }
}

// ═══════════════════════════════════════════════════════════════════
// Create / Edit Printer Page (Loyverse-style)
// ═══════════════════════════════════════════════════════════════════

class CreatePrinterPage extends ConsumerStatefulWidget {
  final SavedPrinter? existingPrinter;
  const CreatePrinterPage({super.key, this.existingPrinter});

  @override
  ConsumerState<CreatePrinterPage> createState() => _CreatePrinterPageState();
}

class _CreatePrinterPageState extends ConsumerState<CreatePrinterPage> {
  late TextEditingController _nameController;
  late TextEditingController _ipController;

  // Printer model
  String _selectedModel = 'Other model';
  static const _printerModels = [
    'Sunmi',
    'Star mPOP (Bluetooth)',
    'Star mC-Print3',
    'Epson TM-T20II (Ethernet)',
    'Epson TM-T88V (Ethernet)',
    'Epson TM-m30',
    'XPrinter XP-Q800',
    'GP-58130IIC',
    'GP-U80300I',
    'GP-L80250I',
    'Other model',
    'Kitchen display',
  ];

  // Interface
  String _selectedInterface = 'Ethernet';
  static const _interfaces = ['Ethernet', 'Bluetooth', 'Sunmi'];

  // Paper width
  String _paperWidth = '80 mm';
  static const _paperWidths = ['58 mm', '80 mm'];

  // Bluetooth
  PrinterDevice? _selectedBluetoothDevice;
  bool _isScanning = false;

  // Toggles
  bool _printReceipts = false;
  bool _printOrders = false;

  // State
  bool _isTesting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existingPrinter;
    _nameController = TextEditingController(text: s?.name ?? '');
    _ipController = TextEditingController(text: s?.address ?? '');
    _printReceipts = s?.enableReceiptPrinting ?? false;
    _printOrders = s?.printOrders ?? false;

    if (s != null && s.name.isNotEmpty) {
      _selectedModel = s.model;
      _paperWidth = s.paperWidth;
      switch (s.connectionType) {
        case PrinterConnectionType.sunmi:
          _selectedInterface = 'Sunmi';
          break;
        case PrinterConnectionType.bluetooth:
          _selectedInterface = 'Bluetooth';
          break;
        case PrinterConnectionType.wifi:
          _selectedInterface = 'Ethernet';
          break;
        default:
          _selectedInterface = 'Ethernet';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  PrinterConnectionType get _connectionType {
    switch (_selectedInterface) {
      case 'Bluetooth':
        return PrinterConnectionType.bluetooth;
      case 'Sunmi':
        return PrinterConnectionType.sunmi;
      default:
        return PrinterConnectionType.wifi;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localizationProvider).languageCode;
    final isEditing = widget.existingPrinter != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing
              ? Translations.get('edit_printer', lang)
              : Translations.get('create_printer', lang),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor:
                    _isSaving ? AppTheme.neutral200 : AppTheme.primaryOrange,
                foregroundColor: _isSaving ? AppTheme.neutral400 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                Translations.get('save', lang),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Basic Info Card ───
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      children: [
                        // Name
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: Translations.get('name', lang),
                            labelStyle: TextStyle(color: Colors.grey.shade500),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Printer Model
                        _buildDropdown(
                          label: Translations.get('printer_model', lang),
                          value: _selectedModel,
                          items: _printerModels,
                          onChanged: (v) {
                            setState(() {
                              _selectedModel = v!;
                              if (v == 'Sunmi') {
                                _selectedInterface = 'Sunmi';
                              } else if (v.contains('Bluetooth')) {
                                _selectedInterface = 'Bluetooth';
                              } else if (v.contains('Ethernet')) {
                                _selectedInterface = 'Ethernet';
                              }
                              if (_nameController.text.isEmpty &&
                                  v != 'Other model') {
                                _nameController.text = v;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Interface
                        _buildDropdown(
                          label: 'Interface',
                          value: _selectedInterface,
                          items: _interfaces,
                          onChanged: (v) {
                            setState(() {
                              _selectedInterface = v!;
                              _selectedBluetoothDevice = null;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // ─── Connection fields based on interface ───
                        if (_selectedInterface == 'Ethernet')
                          _buildIpField(lang),

                        if (_selectedInterface == 'Bluetooth')
                          _buildBluetoothField(lang),

                        if (_selectedInterface == 'Sunmi')
                          _buildSunmiField(lang),

                        const SizedBox(height: 20),

                        // Paper Width
                        _buildDropdown(
                          label: 'Paper width',
                          value: _paperWidth,
                          items: _paperWidths,
                          onChanged: (v) => setState(() => _paperWidth = v!),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─── Advanced Settings ───
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Text(
                            'Advanced settings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Divider(color: Colors.grey.shade200),
                        _toggle(
                          Translations.get('print_receipts_bills', lang),
                          _printReceipts,
                          (v) => setState(() => _printReceipts = v),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        _toggle(
                          Translations.get('print_orders', lang),
                          _printOrders,
                          (v) => setState(() => _printOrders = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Print Test Button (bottom) ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: _isTesting ? null : _testPrint,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isTesting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryOrange,
                        ),
                      )
                    else
                      const Icon(
                        Icons.print,
                        size: 20,
                        color: AppTheme.primaryOrange,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      Translations.get('print_test', lang).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dropdown Builder ───
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.primaryOrange.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryOrange),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ─── IP Address Field ───
  Widget _buildIpField(String lang) {
    return TextField(
      controller: _ipController,
      style: const TextStyle(fontSize: 16),
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: Translations.get('ip_address', lang),
        hintText: '192.168.1.100',
        labelStyle: TextStyle(color: Colors.grey.shade500),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryOrange),
        ),
      ),
    );
  }

  // ─── Bluetooth Field ───
  Widget _buildBluetoothField(String lang) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.get('bluetooth', lang),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedBluetoothDevice?.name ?? '---',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      _selectedBluetoothDevice != null
                          ? Colors.black
                          : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade300),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _isScanning ? null : _scanBluetooth,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryOrange,
            side: const BorderSide(color: AppTheme.primaryOrange),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child:
              _isScanning
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryOrange,
                    ),
                  )
                  : Text(
                    Translations.get('search', lang).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
        ),
      ],
    );
  }

  // ─── Sunmi Field ───
  Widget _buildSunmiField(String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrangeBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.print, color: AppTheme.primaryOrange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.get('sunmi_built_in_printer', lang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrangeDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Translations.get('sunmi_ready_message', lang),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      value: value,
      activeTrackColor: AppTheme.primaryOrange,
      onChanged: onChanged,
    );
  }

  // ─── Bluetooth Scan ───
  Future<void> _scanBluetooth() async {
    setState(() => _isScanning = true);

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final devices = await printerService.scanBluetoothDevices();

      if (!mounted) return;

      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.get(
                'no_devices_found',
                ref.read(localizationProvider).languageCode,
              ),
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
        setState(() => _isScanning = false);
        return;
      }

      // Show device picker dialog
      final selected = await showDialog<PrinterDevice>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get(
                          'bluetooth',
                          ref.read(localizationProvider).languageCode,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Translations.get(
                          'scanning',
                          ref.read(localizationProvider).languageCode,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (_, i) {
                    final device = devices[i];
                    return ListTile(
                      title: Text(
                        device.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      onTap: () => Navigator.pop(ctx, device),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    Translations.get(
                      'cancel',
                      ref.read(localizationProvider).languageCode,
                    ).toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryOrange),
                  ),
                ),
              ],
            ),
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedBluetoothDevice = selected;
          _ipController.text = selected.address;
          if (_nameController.text.isEmpty) {
            _nameController.text = selected.name;
          }
        });

        // Try to connect immediately
        _connectBluetooth(selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bluetooth scan failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }

    if (mounted) setState(() => _isScanning = false);
  }

  // ─── Connect Bluetooth ───
  Future<void> _connectBluetooth(PrinterDevice device) async {
    final lang = ref.read(localizationProvider).languageCode;

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      final success = await printerService.connectBluetooth(device);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Translations.get('connected', lang)} - ${device.name}',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Translations.get('not_connected', lang)} - ${device.name}',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Translations.get('not_connected', lang)}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ─── Test Print ───
  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    final lang = ref.read(localizationProvider).languageCode;

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;

      // Connect first if not connected
      if (_connectionType == PrinterConnectionType.sunmi) {
        await printerService.connectSunmi();
      } else if (_connectionType == PrinterConnectionType.wifi &&
          _ipController.text.isNotEmpty) {
        final parts = _ipController.text.split(':');
        final ip = parts[0];
        final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 9100 : 9100;
        await printerService.connectWiFi(ip, port: port);
      } else if (_connectionType == PrinterConnectionType.bluetooth &&
          _selectedBluetoothDevice != null) {
        await printerService.connectBluetooth(_selectedBluetoothDevice!);
      }

      final result = await printerService.testPrint();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result
                  ? Translations.get('success', lang)
                  : Translations.get('error', lang),
            ),
            backgroundColor: result ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Translations.get('error', lang)}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }

    if (mounted) setState(() => _isTesting = false);
  }

  // ─── Save ───
  Future<void> _save() async {
    final name = _nameController.text.trim();
    final lang = ref.read(localizationProvider).languageCode;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.get('name_is_required', lang)),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final printerService = ref.read(settingsProvider.notifier).printerService;
      bool connected = false;

      // Connect based on interface
      if (_connectionType == PrinterConnectionType.sunmi) {
        connected = await printerService.connectSunmi();
      } else if (_connectionType == PrinterConnectionType.wifi &&
          _ipController.text.isNotEmpty) {
        final parts = _ipController.text.split(':');
        final ip = parts[0];
        final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 9100 : 9100;
        connected = await printerService.connectWiFi(ip, port: port);
      } else if (_connectionType == PrinterConnectionType.bluetooth &&
          _selectedBluetoothDevice != null) {
        connected = await printerService.connectBluetooth(
          _selectedBluetoothDevice!,
        );
      }

      final printer = SavedPrinter(
        id:
            widget.existingPrinter?.id ??
            'printer_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        address: _ipController.text,
        connectionType: _connectionType,
        enableReceiptPrinting: _printReceipts,
        printOrders: _printOrders,
        paperWidth: _paperWidth,
        model: _selectedModel,
      );

      await ref.read(settingsProvider.notifier).addOrUpdatePrinter(printer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              connected
                  ? '${Translations.get('saved_successfully', lang)} - ${Translations.get('connected', lang)}'
                  : '${Translations.get('saved_successfully', lang)} - ${Translations.get('not_connected', lang)}',
            ),
            backgroundColor: connected ? AppTheme.success : AppTheme.warning,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Translations.get('error', lang)}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
