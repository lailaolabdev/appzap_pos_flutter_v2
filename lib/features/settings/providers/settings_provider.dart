import '../../../core/services/storage_service.dart';
import '../../../core/services/printer_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings state model
class SettingsState {
  final String printerName;
  final String printerAddress;
  final PrinterConnectionType printerConnectionType;
  final bool isPrinterConnected;
  final bool enableReceiptPrinting;
  final bool enableBarcodePrinting;
  final String receiptHeader;
  final String receiptFooter;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.printerName = '',
    this.printerAddress = '',
    this.printerConnectionType = PrinterConnectionType.wifi,
    this.isPrinterConnected = false,
    this.enableReceiptPrinting = true,
    this.enableBarcodePrinting = false,
    this.receiptHeader = '',
    this.receiptFooter = 'Thank you for your business!',
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    String? printerName,
    String? printerAddress,
    PrinterConnectionType? printerConnectionType,
    bool? isPrinterConnected,
    bool? enableReceiptPrinting,
    bool? enableBarcodePrinting,
    String? receiptHeader,
    String? receiptFooter,
    bool? isLoading,
    String? error,
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
      receiptFooter: receiptFooter ?? this.receiptFooter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storageService;
  final PrinterService _printerService;

  SettingsNotifier(this._storageService, this._printerService)
    : super(const SettingsState()) {
    _loadSettings();
    _listenToConnectionStatus();
  }

  /// Listen to printer connection status
  void _listenToConnectionStatus() {
    _printerService.connectionStatus.listen((isConnected) {
      state = state.copyWith(isPrinterConnected: isConnected);
    });
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final printerName = await _storageService.read('printer_name') ?? '';
      final printerAddress =
          await _storageService.read('printer_address') ?? '';
      final printerTypeStr = await _storageService.read(
        'printer_connection_type',
      );

      // Auto-detect Sunmi device if no printer is configured
      var printerConnectionType = PrinterConnectionType.wifi;
      if (printerTypeStr == null) {
        final isSunmi = await _printerService.isSunmiDevice();
        if (isSunmi) {
          printerConnectionType = PrinterConnectionType.sunmi;
          // Auto-save Sunmi defaults
          await savePrinterSettings(
            printerName: 'Sunmi Built-in Printer',
            printerAddress: 'BUILT-IN',
            connectionType: PrinterConnectionType.sunmi,
            enableReceiptPrinting: true,
            enableBarcodePrinting: false,
            receiptHeader: '',
            receiptFooter: 'Thank you for your business!',
          );
        }
      } else {
        printerConnectionType = PrinterConnectionType.values.firstWhere(
          (type) => type.name == printerTypeStr,
          orElse: () => PrinterConnectionType.wifi,
        );
      }

      final enableReceiptPrintingStr = await _storageService.read(
        'enable_receipt_printing',
      );
      final enableReceiptPrinting = enableReceiptPrintingStr == 'true';
      final enableBarcodePrintingStr = await _storageService.read(
        'enable_barcode_printing',
      );
      final enableBarcodePrinting = enableBarcodePrintingStr == 'true';
      final receiptHeader = await _storageService.read('receipt_header') ?? '';
      final receiptFooter =
          await _storageService.read('receipt_footer') ??
          'Thank you for your business!';

      state = state.copyWith(
        printerName: printerName,
        printerAddress: printerAddress,
        printerConnectionType: printerConnectionType,
        enableReceiptPrinting: enableReceiptPrinting,
        enableBarcodePrinting: enableBarcodePrinting,
        receiptHeader: receiptHeader,
        receiptFooter: receiptFooter,
        isLoading: false,
      );

      // Auto-connect based on saved type
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

      // Check if printer is already connected (e.g. from previous session if service stayed alive)
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

  /// Save printer settings
  Future<void> savePrinterSettings({
    required String printerName,
    required String printerAddress,
    required PrinterConnectionType connectionType,
    required bool enableReceiptPrinting,
    required bool enableBarcodePrinting,
    required String receiptHeader,
    required String receiptFooter,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _storageService.write('printer_name', printerName);
      await _storageService.write('printer_address', printerAddress);
      await _storageService.write(
        'printer_connection_type',
        connectionType.name,
      );
      await _storageService.write(
        'enable_receipt_printing',
        enableReceiptPrinting.toString(),
      );
      await _storageService.write(
        'enable_barcode_printing',
        enableBarcodePrinting.toString(),
      );
      await _storageService.write('receipt_header', receiptHeader);
      await _storageService.write('receipt_footer', receiptFooter);

      state = state.copyWith(
        printerName: printerName,
        printerAddress: printerAddress,
        printerConnectionType: connectionType,
        enableReceiptPrinting: enableReceiptPrinting,
        enableBarcodePrinting: enableBarcodePrinting,
        receiptHeader: receiptHeader,
        receiptFooter: receiptFooter,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save settings: $e',
      );
    }
  }

  /// Test printer connection
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

  /// Print test receipt
  Future<void> printTestReceipt() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (!_printerService.isConnected) {
        throw Exception('Printer not connected');
      }

      final result = await _printerService.testPrint();

      if (!result) {
        throw Exception('Print test failed');
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Print test failed: $e');
    }
  }

  /// Get printer service for external use
  PrinterService get printerService => _printerService;
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final storageService = ref.watch(storageServiceProvider);
    final printerService = ref.watch(printerServiceProvider);
    return SettingsNotifier(storageService, printerService);
  },
);
