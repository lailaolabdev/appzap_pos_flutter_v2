import 'dart:convert';

import '../../../core/services/printer_api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/printer_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A saved printer entry
class SavedPrinter {
  final String id;
  final String name;
  final String address;
  final PrinterConnectionType connectionType;
  final bool enableReceiptPrinting;
  final bool enableBarcodePrinting;
  final bool printOrders;
  final bool autoPrintReceipt;
  final String paperWidth;
  final String model;

  const SavedPrinter({
    required this.id,
    required this.name,
    this.address = '',
    this.connectionType = PrinterConnectionType.wifi,
    this.enableReceiptPrinting = false,
    this.enableBarcodePrinting = false,
    this.printOrders = false,
    this.autoPrintReceipt = false,
    this.paperWidth = '80 mm',
    this.model = 'Other model',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'connectionType': connectionType.name,
    'enableReceiptPrinting': enableReceiptPrinting,
    'enableBarcodePrinting': enableBarcodePrinting,
    'printOrders': printOrders,
    'autoPrintReceipt': autoPrintReceipt,
    'paperWidth': paperWidth,
    'model': model,
  };

  factory SavedPrinter.fromJson(Map<String, dynamic> json) => SavedPrinter(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    connectionType: PrinterConnectionType.values.firstWhere(
      (t) => t.name == json['connectionType'],
      orElse: () => PrinterConnectionType.wifi,
    ),
    enableReceiptPrinting: json['enableReceiptPrinting'] as bool? ?? false,
    enableBarcodePrinting: json['enableBarcodePrinting'] as bool? ?? false,
    printOrders: json['printOrders'] as bool? ?? false,
    autoPrintReceipt: json['autoPrintReceipt'] as bool? ?? false,
    paperWidth: json['paperWidth'] as String? ?? '80 mm',
    model: json['model'] as String? ?? 'Other model',
  );

  SavedPrinter copyWith({
    String? name,
    String? address,
    PrinterConnectionType? connectionType,
    bool? enableReceiptPrinting,
    bool? enableBarcodePrinting,
    bool? printOrders,
    bool? autoPrintReceipt,
    String? paperWidth,
    String? model,
  }) => SavedPrinter(
    id: id,
    name: name ?? this.name,
    address: address ?? this.address,
    connectionType: connectionType ?? this.connectionType,
    enableReceiptPrinting: enableReceiptPrinting ?? this.enableReceiptPrinting,
    enableBarcodePrinting: enableBarcodePrinting ?? this.enableBarcodePrinting,
    printOrders: printOrders ?? this.printOrders,
    autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
    paperWidth: paperWidth ?? this.paperWidth,
    model: model ?? this.model,
  );
}

/// Settings state model
class SettingsState {
  // Legacy single-printer fields (kept for backward compat)
  final String printerName;
  final String printerAddress;
  final PrinterConnectionType printerConnectionType;
  final bool isPrinterConnected;
  final bool enableReceiptPrinting;
  final bool enableBarcodePrinting;
  final String receiptHeader;
  final bool isLoading;
  final String? error;

  // Multi-printer
  final List<SavedPrinter> printers;
  final Set<String> connectedPrinterIds;

  const SettingsState({
    this.printerName = '',
    this.printerAddress = '',
    this.printerConnectionType = PrinterConnectionType.wifi,
    this.isPrinterConnected = false,
    this.enableReceiptPrinting = true,
    this.enableBarcodePrinting = false,
    this.receiptHeader = '',
    this.isLoading = false,
    this.error,
    this.printers = const [],
    this.connectedPrinterIds = const {},
  });

  SettingsState copyWith({
    String? printerName,
    String? printerAddress,
    PrinterConnectionType? printerConnectionType,
    bool? isPrinterConnected,
    bool? enableReceiptPrinting,
    bool? enableBarcodePrinting,
    String? receiptHeader,
    bool? isLoading,
    String? error,
    List<SavedPrinter>? printers,
    Set<String>? connectedPrinterIds,
  }) {
    return SettingsState(
      printerName: printerName ?? this.printerName,
      printerAddress: printerAddress ?? this.printerAddress,
      printerConnectionType:
          printerConnectionType ?? this.printerConnectionType,
      isPrinterConnected: isPrinterConnected ?? this.isPrinterConnected,
      enableReceiptPrinting:
          enableReceiptPrinting ?? this.enableReceiptPrinting,
      enableBarcodePrinting:
          enableBarcodePrinting ?? this.enableBarcodePrinting,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      printers: printers ?? this.printers,
      connectedPrinterIds: connectedPrinterIds ?? this.connectedPrinterIds,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storageService;
  final PrinterService _printerService;
  final PrinterApiService _printerApiService;
  String? _branchId;

  SettingsNotifier(
    this._storageService,
    this._printerService,
    this._printerApiService,
  ) : super(const SettingsState()) {
    _loadSettings();
    _listenToConnectionStatus();
  }

  /// Set the branch ID for API calls
  void setBranchId(String? branchId) {
    _branchId = branchId;
  }

  void _listenToConnectionStatus() {
    _printerService.connectionStatus.listen((isConnected) {
      state = state.copyWith(isPrinterConnected: isConnected);
    });
  }

  Future<void> _loadSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final reads = await Future.wait([
        _storageService.read('printer_name'),
        _storageService.read('printer_address'),
        _storageService.read('printer_connection_type'),
        _storageService.read('enable_receipt_printing'),
        _storageService.read('enable_barcode_printing'),
        _storageService.read('receipt_header'),
        _storageService.read('receipt_footer'),
        _storageService.read('saved_printers'),
      ]);

      final printerName = reads[0] ?? '';
      final printerAddress = reads[1] ?? '';
      final printerTypeStr = reads[2];
      final enableReceiptPrinting = reads[3] == 'true';
      final enableBarcodePrinting = reads[4] == 'true';
      final receiptHeader = reads[5] ?? '';
      final savedPrintersJson = reads[7];

      // Load multi-printer list
      var printers = <SavedPrinter>[];
      if (savedPrintersJson != null && savedPrintersJson.isNotEmpty) {
        try {
          final list = jsonDecode(savedPrintersJson) as List;
          printers =
              list
                  .map((e) => SavedPrinter.fromJson(e as Map<String, dynamic>))
                  .toList();
        } catch (_) {}
      }

      // Migrate: if old single-printer exists but no multi-printer list
      if (printers.isEmpty && printerName.isNotEmpty) {
        var connType = PrinterConnectionType.wifi;
        if (printerTypeStr != null) {
          connType = PrinterConnectionType.values.firstWhere(
            (t) => t.name == printerTypeStr,
            orElse: () => PrinterConnectionType.wifi,
          );
        }
        printers = [
          SavedPrinter(
            id: 'migrated_${DateTime.now().millisecondsSinceEpoch}',
            name: printerName,
            address: printerAddress,
            connectionType: connType,
            enableReceiptPrinting: enableReceiptPrinting,
          ),
        ];
        await _savePrintersList(printers);
      }

      // Auto-detect Sunmi
      var printerConnectionType = PrinterConnectionType.wifi;
      if (printerTypeStr == null && printers.isEmpty) {
        final isSunmi = await _printerService.isSunmiDevice();
        if (isSunmi) {
          printerConnectionType = PrinterConnectionType.sunmi;
          final sunmiPrinter = SavedPrinter(
            id: 'sunmi_builtin',
            name: 'Sunmi Built-in Printer',
            address: 'BUILT-IN',
            connectionType: PrinterConnectionType.sunmi,
            enableReceiptPrinting: true,
            model: 'Sunmi',
          );
          printers = [sunmiPrinter];
          await _savePrintersList(printers);
          await savePrinterSettings(
            printerName: sunmiPrinter.name,
            printerAddress: sunmiPrinter.address,
            connectionType: PrinterConnectionType.sunmi,
            enableReceiptPrinting: true,
            enableBarcodePrinting: false,
            receiptHeader: '',
          );
        }
      } else if (printerTypeStr != null) {
        printerConnectionType = PrinterConnectionType.values.firstWhere(
          (type) => type.name == printerTypeStr,
          orElse: () => PrinterConnectionType.wifi,
        );
      }

      state = state.copyWith(
        printerName: printerName,
        printerAddress: printerAddress,
        printerConnectionType: printerConnectionType,
        enableReceiptPrinting: enableReceiptPrinting,
        enableBarcodePrinting: enableBarcodePrinting,
        receiptHeader: receiptHeader,
        printers: printers,
        isLoading: false,
      );

      // Auto-connect
      if (printerConnectionType == PrinterConnectionType.sunmi) {
        final connected = await _printerService.connectSunmi();
        if (connected) {
          state = state.copyWith(isPrinterConnected: true);
        }
      } else if (printerConnectionType == PrinterConnectionType.wifi &&
          printerAddress.isNotEmpty &&
          printerAddress.contains(':')) {
        try {
          final parts = printerAddress.split(':');
          if (parts.length == 2) {
            final ip = parts[0];
            final port = int.tryParse(parts[1]) ?? 9100;
            final connected = await _printerService.connectWiFi(ip, port: port);
            if (connected) {
              state = state.copyWith(isPrinterConnected: true);
            }
          }
        } catch (e) {
          print('Error auto-connecting to WiFi printer: $e');
        }
      }

      if (_printerService.isConnected) {
        state = state.copyWith(isPrinterConnected: true);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      );
    }
  }

  /// Save the multi-printer list to storage
  Future<void> _savePrintersList(List<SavedPrinter> printers) async {
    final json = jsonEncode(printers.map((p) => p.toJson()).toList());
    await _storageService.write('saved_printers', json);
  }

  /// Add or update a printer
  Future<void> addOrUpdatePrinter(SavedPrinter printer) async {
    final list = List<SavedPrinter>.from(state.printers);
    final idx = list.indexWhere((p) => p.id == printer.id);
    if (idx >= 0) {
      list[idx] = printer;
    } else {
      list.add(printer);
    }
    await _savePrintersList(list);

    // Also set as active printer (legacy fields)
    await savePrinterSettings(
      printerName: printer.name,
      printerAddress: printer.address,
      connectionType: printer.connectionType,
      enableReceiptPrinting: printer.enableReceiptPrinting,
      enableBarcodePrinting: printer.enableBarcodePrinting,
      receiptHeader: state.receiptHeader,
    );

    state = state.copyWith(printers: list);
  }

  /// Delete a printer by id
  Future<void> deletePrinter(String id) async {
    final list = List<SavedPrinter>.from(state.printers);
    list.removeWhere((p) => p.id == id);
    await _savePrintersList(list);

    // If we deleted the active printer, clear legacy fields
    if (list.isEmpty) {
      await savePrinterSettings(
        printerName: '',
        printerAddress: '',
        connectionType: PrinterConnectionType.wifi,
        enableReceiptPrinting: false,
        enableBarcodePrinting: false,
        receiptHeader: state.receiptHeader,
      );
    } else {
      // Set first remaining as active
      final first = list.first;
      await savePrinterSettings(
        printerName: first.name,
        printerAddress: first.address,
        connectionType: first.connectionType,
        enableReceiptPrinting: first.enableReceiptPrinting,
        enableBarcodePrinting: first.enableBarcodePrinting,
        receiptHeader: state.receiptHeader,
      );
    }

    state = state.copyWith(printers: list);
  }

  /// Delete multiple printers
  Future<void> deletePrinters(Set<String> ids) async {
    for (final id in ids) {
      await deletePrinter(id);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Backend API Sync
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch printers from backend and merge with local
  Future<void> syncPrintersFromBackend() async {
    if (_branchId == null || _branchId!.isEmpty) return;

    try {
      final remotePrinters = await _printerApiService.getPrinters(_branchId!);
      final synced = <SavedPrinter>[];

      for (final remote in remotePrinters) {
        synced.add(_mapRemoteToLocal(remote));
      }

      if (synced.isNotEmpty) {
        await _savePrintersList(synced);
        state = state.copyWith(printers: synced);

        // Set first printer as active
        final first = synced.first;
        await savePrinterSettings(
          printerName: first.name,
          printerAddress: first.address,
          connectionType: first.connectionType,
          enableReceiptPrinting: first.enableReceiptPrinting,
          enableBarcodePrinting: first.enableBarcodePrinting,
          receiptHeader: state.receiptHeader,
        );
      }
    } catch (e) {
      print('Sync printers from backend failed: $e');
    }
  }

  /// Save a printer to backend and local
  Future<void> savePrinterToBackend(SavedPrinter printer) async {
    if (_branchId == null || _branchId!.isEmpty) {
      // No branch — save locally only
      await addOrUpdatePrinter(printer);
      return;
    }

    try {
      final data = _mapLocalToRemote(printer);

      Map<String, dynamic> result;
      if (printer.id.startsWith('printer_') || printer.id.startsWith('migrated_') || printer.id.startsWith('sunmi_')) {
        // Local-only printer — create on backend
        result = await _printerApiService.createPrinter(_branchId!, data);
      } else {
        // Existing backend printer — update
        result = await _printerApiService.updatePrinter(_branchId!, printer.id, data);
      }

      // Get the backend ID
      final backendId = result['_id']?.toString() ?? result['id']?.toString() ?? printer.id;
      final updatedPrinter = SavedPrinter(
        id: backendId,
        name: printer.name,
        address: printer.address,
        connectionType: printer.connectionType,
        enableReceiptPrinting: printer.enableReceiptPrinting,
        enableBarcodePrinting: printer.enableBarcodePrinting,
        printOrders: printer.printOrders,
        autoPrintReceipt: printer.autoPrintReceipt,
        paperWidth: printer.paperWidth,
        model: printer.model,
      );

      await addOrUpdatePrinter(updatedPrinter);
    } catch (e) {
      // Fallback: save locally
      print('Backend save failed, saving locally: $e');
      await addOrUpdatePrinter(printer);
    }
  }

  /// Delete a printer from backend and local
  Future<void> deletePrinterFromBackend(String printerId) async {
    if (_branchId != null &&
        _branchId!.isNotEmpty &&
        !printerId.startsWith('printer_') &&
        !printerId.startsWith('migrated_') &&
        !printerId.startsWith('sunmi_')) {
      try {
        await _printerApiService.deletePrinter(_branchId!, printerId);
      } catch (e) {
        print('Backend delete failed: $e');
      }
    }
    await deletePrinter(printerId);
  }

  /// Map backend printer JSON to local SavedPrinter
  SavedPrinter _mapRemoteToLocal(Map<String, dynamic> remote) {
    final id = remote['_id']?.toString() ?? remote['id']?.toString() ?? '';
    final name = remote['name']?.toString() ?? '';
    final connType = remote['connectionType']?.toString() ?? 'network';
    final paperSize = remote['paperSize'] as Map<String, dynamic>?;
    final printSettings = remote['printSettings'] as Map<String, dynamic>?;
    final networkSettings = remote['networkSettings'] as Map<String, dynamic>?;
    final bluetoothSettings = remote['bluetoothSettings'] as Map<String, dynamic>?;

    // Determine address
    String address = '';
    PrinterConnectionType connectionType;
    switch (connType) {
      case 'bluetooth':
        connectionType = PrinterConnectionType.bluetooth;
        address = bluetoothSettings?['macAddress']?.toString() ?? '';
        break;
      case 'usb':
        connectionType = PrinterConnectionType.sunmi;
        address = 'BUILT-IN';
        break;
      default:
        connectionType = PrinterConnectionType.wifi;
        final ip = networkSettings?['ipAddress']?.toString() ?? '';
        final port = networkSettings?['port']?.toString() ?? '9100';
        address = ip.isNotEmpty ? '$ip:$port' : '';
    }

    return SavedPrinter(
      id: id,
      name: name,
      address: address,
      connectionType: connectionType,
      enableReceiptPrinting: remote['type'] == 'receipt' || remote['defaultPrinter'] == true,
      printOrders: remote['type'] == 'kitchen',
      autoPrintReceipt: printSettings?['copies'] != null && (printSettings?['copies'] as num? ?? 0) > 0,
      paperWidth: paperSize?['preset']?.toString() == '58mm' ? '58 mm' : '80 mm',
      model: remote['model']?.toString() ?? 'Other model',
    );
  }

  /// Map local SavedPrinter to backend API format
  Map<String, dynamic> _mapLocalToRemote(SavedPrinter printer) {
    final data = <String, dynamic>{
      'name': printer.name,
      'type': printer.printOrders ? 'kitchen' : 'receipt',
      'model': printer.model,
      'enabled': true,
      'defaultPrinter': printer.enableReceiptPrinting,
      'paperSize': {
        'preset': printer.paperWidth == '58 mm' ? '58mm' : '80mm',
        'width': printer.paperWidth == '58 mm' ? 58 : 80,
        'unit': 'mm',
      },
      'printSettings': {
        'copies': printer.autoPrintReceipt ? 1 : 0,
        'cutPaper': true,
        'cutType': 'full',
      },
    };

    switch (printer.connectionType) {
      case PrinterConnectionType.wifi:
        data['connectionType'] = 'network';
        final parts = printer.address.split(':');
        data['networkSettings'] = {
          'ipAddress': parts.isNotEmpty ? parts[0] : '',
          'port': parts.length > 1 ? int.tryParse(parts[1]) ?? 9100 : 9100,
          'timeout': 5000,
          'retryAttempts': 3,
        };
        break;
      case PrinterConnectionType.bluetooth:
        data['connectionType'] = 'bluetooth';
        data['bluetoothSettings'] = {
          'macAddress': printer.address,
          'deviceName': printer.name,
        };
        break;
      case PrinterConnectionType.sunmi:
        data['connectionType'] = 'usb';
        data['usbSettings'] = {
          'portName': 'BUILT-IN',
        };
        break;
      default:
        data['connectionType'] = 'network';
    }

    return data;
  }

  /// Save printer settings (legacy single-printer)
  Future<void> savePrinterSettings({
    required String printerName,
    required String printerAddress,
    required PrinterConnectionType connectionType,
    required bool enableReceiptPrinting,
    required bool enableBarcodePrinting,
    required String receiptHeader,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await Future.wait([
        _storageService.write('printer_name', printerName),
        _storageService.write('printer_address', printerAddress),
        _storageService.write('printer_connection_type', connectionType.name),
        _storageService.write(
          'enable_receipt_printing',
          enableReceiptPrinting.toString(),
        ),
        _storageService.write(
          'enable_barcode_printing',
          enableBarcodePrinting.toString(),
        ),
        _storageService.write('receipt_header', receiptHeader),
      ]);

      state = state.copyWith(
        printerName: printerName,
        printerAddress: printerAddress,
        printerConnectionType: connectionType,
        enableReceiptPrinting: enableReceiptPrinting,
        enableBarcodePrinting: enableBarcodePrinting,
        receiptHeader: receiptHeader,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save settings: $e',
      );
    }
  }

  Future<void> testPrinterConnection() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _printerService.testPrint();
      state = state.copyWith(
        isPrinterConnected: result,
        isLoading: false,
        error: result ? null : 'Test print failed',
      );
    } catch (e) {
      state = state.copyWith(
        isPrinterConnected: false,
        isLoading: false,
        error: 'Connection test failed: $e',
      );
    }
  }

  Future<void> printTestReceipt() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      if (!_printerService.isConnected) {
        throw Exception('Printer not connected');
      }
      final result = await _printerService.testPrint();
      if (!result) throw Exception('Print test failed');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Print test failed: $e');
    }
  }

  PrinterService get printerService => _printerService;
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final storageService = ref.watch(storageServiceProvider);
    final printerService = ref.watch(printerServiceProvider);
    final printerApiService = ref.watch(printerApiServiceProvider);
    return SettingsNotifier(storageService, printerService, printerApiService);
  },
);
