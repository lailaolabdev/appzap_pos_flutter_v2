import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

enum PrinterConnectionType { bluetooth, wifi, usb, sunmi }

class PrinterDevice {
  final String id;
  final String name;
  final String address;
  final PrinterConnectionType type;
  final bool isConnected;

  PrinterDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    this.isConnected = false,
  });

  PrinterDevice copyWith({
    String? id,
    String? name,
    String? address,
    PrinterConnectionType? type,
    bool? isConnected,
  }) {
    return PrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class PrinterService {
  BluetoothDevice? _bluetoothDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  Socket? _networkSocket;
  PrinterDevice? _connectedDevice;
  bool _sunmiConnected = false;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final bluetoothStatus = await Permission.bluetooth.request();
      final bluetoothConnectStatus =
          await Permission.bluetoothConnect.request();
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final locationStatus = await Permission.locationWhenInUse.request();

      return bluetoothStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          bluetoothScanStatus.isGranted &&
          locationStatus.isGranted;
    }
    return true;
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      if (Platform.isAndroid) {
        return await FlutterBluePlus.isOn;
      }
      return true;
    } catch (e) {
      print('Error checking Bluetooth status: $e');
      return false;
    }
  }

  Future<bool> enableBluetooth() async {
    try {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
        return true;
      }
      return true;
    } catch (e) {
      print('Error enabling Bluetooth: $e');
      return false;
    }
  }

  Future<List<PrinterDevice>> scanBluetoothDevices() async {
    try {
      final hasPermission = await requestBluetoothPermissions();
      if (!hasPermission) {
        throw Exception('Bluetooth permissions not granted');
      }

      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        final enabled = await enableBluetooth();
        if (!enabled) {
          throw Exception('Bluetooth is not enabled');
        }
      }

      final devices = <PrinterDevice>[];
      final foundDeviceIds = <String>{};

      final connectedDevices = FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        if (!foundDeviceIds.contains(device.remoteId.toString())) {
          foundDeviceIds.add(device.remoteId.toString());
          devices.add(_createPrinterDevice(device));
        }
      }

      final systemDevices = await FlutterBluePlus.systemDevices([]);
      for (var device in systemDevices) {
        if (!foundDeviceIds.contains(device.remoteId.toString())) {
          foundDeviceIds.add(device.remoteId.toString());
          devices.add(_createPrinterDevice(device));
        }
      }

      final scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final device = result.device;
          if (!foundDeviceIds.contains(device.remoteId.toString()) &&
              device.platformName.isNotEmpty) {
            foundDeviceIds.add(device.remoteId.toString());
            devices.add(_createPrinterDevice(device));
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 3),
        androidUsesFineLocation: true,
      );

      await Future.delayed(const Duration(seconds: 3));
      await scanSubscription.cancel();
      await FlutterBluePlus.stopScan();

      return devices;
    } catch (e) {
      print('Error scanning Bluetooth devices: $e');
      await FlutterBluePlus.stopScan();
      rethrow;
    }
  }

  PrinterDevice _createPrinterDevice(BluetoothDevice device) {
    return PrinterDevice(
      id: device.remoteId.toString(),
      name:
          device.platformName.isNotEmpty
              ? device.platformName
              : 'Unknown Device',
      address: device.remoteId.toString(),
      type: PrinterConnectionType.bluetooth,
      isConnected: device.isConnected,
    );
  }

  PrinterDevice _createSunmiDevice() {
    return PrinterDevice(
      id: 'sunmi_builtin',
      name: 'Sunmi Built-in Printer',
      address: 'BUILT-IN',
      type: PrinterConnectionType.sunmi,
      isConnected: true,
    );
  }

  Future<bool> connectBluetooth(PrinterDevice device) async {
    try {
      // Only disconnect Bluetooth/WiFi, NOT Sunmi
      if (_bluetoothDevice != null) {
        await _bluetoothDevice!.disconnect();
        _bluetoothDevice = null;
        _writeCharacteristic = null;
      }

      if (_networkSocket != null) {
        await _networkSocket!.close();
        _networkSocket = null;
      }

      final bluetoothDevice = BluetoothDevice.fromId(device.id);

      // Explicitly disable auto-connect and MTU request (use null/default)
      // Note: flutter_blue_plus 1.32.x connect() signature supports mtu: null
      await bluetoothDevice.connect(
        timeout: const Duration(seconds: 10),
        mtu: null,
        autoConnect: false,
      );

      // Request high MTU for faster transfer
      // Standard BLE MTU is 23 (20 payload). We try to request 512.
      if (Platform.isAndroid) {
        try {
          await bluetoothDevice.requestMtu(512);
        } catch (e) {
          print('Error requesting MTU: $e');
        }
      }

      final services = await bluetoothDevice.discoverServices();

      BluetoothCharacteristic? writeChar;

      final excludedServices = ['00001800', '00001801', '0000180a'];

      for (var service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();

        if (excludedServices.any((uuid) => serviceUuid.contains(uuid))) {
          continue;
        }

        for (var char in service.characteristics) {
          final charUuid = char.uuid.toString().toLowerCase();

          if (charUuid.contains('2a00') || charUuid.contains('2a01')) {
            continue;
          }

          if (char.properties.writeWithoutResponse || char.properties.write) {
            writeChar = char;
            break;
          }
        }
        if (writeChar != null) break;
      }

      if (writeChar == null) {
        throw Exception('No printer characteristic found');
      }

      _bluetoothDevice = bluetoothDevice;
      _writeCharacteristic = writeChar;

      // Only update connected device if Sunmi is NOT active
      if (!_sunmiConnected) {
        _connectedDevice = device.copyWith(isConnected: true);
      }

      _connectionStatusController.add(true);

      return true;
    } catch (e) {
      print('Error connecting to Bluetooth: $e');
      _connectionStatusController.add(false);
      return false;
    }
  }

  Future<List<PrinterDevice>> scanWiFiPrinters() async {
    return [];
  }

  Future<bool> connectWiFi(String ipAddress, {int port = 9100}) async {
    try {
      final trimmedIp = ipAddress.trim();

      if (!_isValidIpAddress(trimmedIp)) {
        throw Exception('Invalid IP address format');
      }

      // Only disconnect Bluetooth/WiFi, NOT Sunmi
      if (_bluetoothDevice != null) {
        await _bluetoothDevice!.disconnect();
        _bluetoothDevice = null;
        _writeCharacteristic = null;
      }

      if (_networkSocket != null) {
        await _networkSocket!.close();
        _networkSocket = null;
      }

      final socket = await Socket.connect(
        trimmedIp,
        port,
        timeout: const Duration(seconds: 5),
      );

      _networkSocket = socket;

      // Only update connected device if Sunmi is NOT active
      if (!_sunmiConnected) {
        _connectedDevice = PrinterDevice(
          id: ipAddress,
          name: 'Network Printer',
          address: '$ipAddress:$port',
          type: PrinterConnectionType.wifi,
          isConnected: true,
        );
      }

      _connectionStatusController.add(true);
      return true;
    } catch (e) {
      print('Error connecting to WiFi: $e');
      _connectionStatusController.add(false);
      rethrow;
    }
  }

  bool _isValidIpAddress(String ip) {
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  Future<bool> isSunmiDevice() async {
    try {
      final bool? bound = await SunmiPrinter.bindingPrinter();
      return bound == true;
    } catch (e) {
      print('Error checking Sunmi device: $e');
      return false;
    }
  }

  Future<void> _initializeSunmiPrinter({bool force = false}) async {
    if (_sunmiConnected && !force) {
      return;
    }

    print('[Sunmi V2] Attempting to bind printer service...');

    // Always attempt to bind
    final bool? bound = await SunmiPrinter.bindingPrinter();
    if (bound != true) {
      // If binding fails, it might already be bound or unavailable.
      // We log it but proceed to try initialization which is the critical step
      print(
        '[Sunmi V2] Binding check returned false/null, but proceeding to init...',
      );
    } else {
      print('[Sunmi V2] Printer service bound successfully');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    print('[Sunmi V2] Initializing printer...');
    try {
      await SunmiPrinter.initPrinter();
      print('[Sunmi V2] Printer initialized successfully');

      _sunmiConnected = true;
      _connectedDevice = _createSunmiDevice();
      _connectionStatusController.add(true);
      print('[Sunmi V2] Connection successful');
    } catch (e) {
      print('[Sunmi V2] Initialization failed: $e');
      // If init fails, we can't consider it connected
      _sunmiConnected = false;
      throw Exception('Failed to initialize Sunmi printer: $e');
    }
  }

  Future<bool> ensureSunmiConnected({bool force = false}) async {
    try {
      await _initializeSunmiPrinter(force: force);
      return true;
    } catch (e) {
      print('Error ensuring Sunmi connection: $e');
      return false;
    }
  }

  Future<bool> connectSunmi() async {
    try {
      await _initializeSunmiPrinter(force: true);
      return true;
    } catch (e) {
      print('Error connecting to Sunmi: $e');
      _connectionStatusController.add(false);
      return false;
    }
  }

  /// Connect external Bluetooth printer while keeping Sunmi device active
  Future<bool> connectBluetoothOnSunmi(PrinterDevice device) async {
    try {
      print('[Sunmi BT] Connecting to Bluetooth printer: ${device.name}');

      final bluetoothDevice = BluetoothDevice.fromId(device.id);
      await bluetoothDevice.connect(timeout: const Duration(seconds: 10));

      if (Platform.isAndroid) {
        try {
          await bluetoothDevice.requestMtu(512);
        } catch (e) {
          print('[Sunmi BT] Error requesting MTU: $e');
        }
      }

      final services = await bluetoothDevice.discoverServices();
      BluetoothCharacteristic? writeChar;
      final excludedServices = ['00001800', '00001801', '0000180a'];

      for (var service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();
        if (excludedServices.any((uuid) => serviceUuid.contains(uuid))) {
          continue;
        }

        for (var char in service.characteristics) {
          final charUuid = char.uuid.toString().toLowerCase();
          if (charUuid.contains('2a00') || charUuid.contains('2a01')) {
            continue;
          }

          if (char.properties.writeWithoutResponse || char.properties.write) {
            writeChar = char;
            break;
          }
        }
        if (writeChar != null) break;
      }

      if (writeChar == null) {
        throw Exception('No printer characteristic found');
      }

      // Store Bluetooth device but keep Sunmi active
      _bluetoothDevice = bluetoothDevice;
      _writeCharacteristic = writeChar;

      // Update connected device to Bluetooth (you can override or add dual mode)
      _connectedDevice = device.copyWith(isConnected: true);
      _connectionStatusController.add(true);

      print('[Sunmi BT] Bluetooth printer connected successfully');
      return true;
    } catch (e) {
      print('[Sunmi BT] Error connecting to Bluetooth: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_bluetoothDevice != null) {
        await _bluetoothDevice!.disconnect();
        _bluetoothDevice = null;
        _writeCharacteristic = null;
      }

      if (_networkSocket != null) {
        await _networkSocket!.close();
        _networkSocket = null;
      }

      _sunmiConnected = false;
      _connectedDevice = null;
      _connectionStatusController.add(false);
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  PrinterDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice?.isConnected ?? false;

  Future<bool> testPrint() async {
    try {
      // Prefer Sunmi SDK on Sunmi devices regardless of other connections
      final onSunmiDevice = await isSunmiDevice();
      if (onSunmiDevice) {
        final ready = await ensureSunmiConnected(force: true);
        if (ready) {
          return await _testPrintSunmi();
        }
      }

      if (_sunmiConnected ||
          _connectedDevice?.type == PrinterConnectionType.sunmi) {
        final ready = await ensureSunmiConnected();
        if (!ready) {
          throw Exception('Sunmi printer not ready');
        }
        return await _testPrintSunmi();
      }

      if (!isConnected) {
        // Attempt to auto-connect to Sunmi as a fallback
        print('Printer not connected. Attempting to auto-connect Sunmi...');
        final sunmiConnected = await ensureSunmiConnected();
        if (sunmiConnected) {
          return await _testPrintSunmi();
        }

        throw Exception('Printer not connected');
      }

      final bytes = await _renderReceiptImage(
        header: 'TEST PRINT',
        orderId: 'AppZap POS',
        tableNumber: '',
        serverName: 'Staff',
        dateStr: DateTime.now().toString().substring(0, 19),
        items: [],
        total: 0,
        footer: '',
      );

      return await _sendToPrinter(bytes);
    } catch (e) {
      print('Error test print: $e');
      return false;
    }
  }

  Future<bool> _testPrintSunmi() async {
    try {
      await SunmiPrinter.printText(
        'TEST PRINT',
        style: SunmiTextStyle(
          fontSize: 32,
          align: SunmiPrintAlign.CENTER,
          bold: true,
        ),
      );

      await SunmiPrinter.lineWrap(1);

      await SunmiPrinter.printText('AppZap POS');
      await SunmiPrinter.printText('Staff');
      await SunmiPrinter.printText(DateTime.now().toString().substring(0, 19));

      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.cutPaper();

      return true;
    } catch (e) {
      print('Error test print Sunmi: $e');
      return false;
    }
  }

  Future<bool> printReceipt({
    required String header,
    required List<Map<String, dynamic>> items,
    required double total,
    String? orderId,
    String? tableNumber,
    String? serverName,
    String? footer,
    String? orderType,
    String? paymentMethod,
    String? logoUrl,
    String paperWidth = '80 mm',
  }) async {
    try {
      // Prefer Sunmi SDK on Sunmi devices regardless of other connections
      final onSunmiDevice = await isSunmiDevice();
      if (onSunmiDevice) {
        final ready = await ensureSunmiConnected(force: true);
        if (ready) {
          return await _printReceiptSunmi(
            header: header,
            items: items,
            total: total,
            orderId: orderId ?? '',
            tableNumber: tableNumber ?? '',
            serverName: serverName ?? 'Staff',
            footer: footer ?? '',
            orderType: orderType ?? '',
            paymentMethod: paymentMethod ?? '',
            logoUrl: logoUrl,
          );
        }
      }

      if (!isConnected) {
        print(
          'Printer not connected. Attempting to auto-connect Sunmi/InnerPrinter...',
        );
        final sunmiConnected = await ensureSunmiConnected();
        if (!sunmiConnected) {
          throw Exception('Printer not connected');
        }
      }

      if (_sunmiConnected) {
        return await _printReceiptSunmi(
          header: header,
          items: items,
          total: total,
          orderId: orderId ?? '',
          tableNumber: tableNumber ?? '',
          serverName: serverName ?? 'Staff',
          footer: footer ?? '',
          orderType: orderType ?? '',
          paymentMethod: paymentMethod ?? '',
          logoUrl: logoUrl,
        );
      }

      final now = DateTime.now();
      final dateStr =
          'Jan ${now.day}, ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? "PM" : "AM"}';

      final bytes = await _renderReceiptImage(
        header: header,
        orderId: orderId ?? '',
        tableNumber: tableNumber ?? '',
        serverName: serverName ?? 'Staff',
        dateStr: dateStr,
        items: items,
        total: total,
        footer: footer ?? '',
        orderType: orderType ?? '',
        paymentMethod: paymentMethod ?? '',
        paperWidth: paperWidth,
      );

      return await _sendToPrinter(bytes);
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }

  Future<bool> _printReceiptSunmi({
    required String header,
    required List<Map<String, dynamic>> items,
    required double total,
    required String orderId,
    required String tableNumber,
    required String serverName,
    required String footer,
    String orderType = '',
    String paymentMethod = '',
    String? logoUrl,
  }) async {
    try {
      // TODO: Print logo image here when logoUrl is available

      // Header
      await SunmiPrinter.printText(
        header,
        style: SunmiTextStyle(
          fontSize: 36,
          align: SunmiPrintAlign.CENTER,
          bold: true,
        ),
      );

      // Order ID
      if (orderId.isNotEmpty) {
        await SunmiPrinter.printText(
          orderId,
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
        );
      }

      await SunmiPrinter.lineWrap(1);

      // Details
      if (tableNumber.isNotEmpty) {
        await SunmiPrinter.printText('ໂຕະ: $tableNumber');
      }

      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await SunmiPrinter.printText(
        'ວັນທີ: $dateStr',
        style: SunmiTextStyle(
          fontSize: 28,
          align: SunmiPrintAlign.LEFT,
          bold: true,
        ),
      );
      await SunmiPrinter.printText(
        'ພະນັກງານ: $serverName',
        style: SunmiTextStyle(
          fontSize: 28,
          align: SunmiPrintAlign.LEFT,
          bold: true,
        ),
      );
      if (orderType.isNotEmpty) {
        await SunmiPrinter.printText(
          'ປະເພດ: $orderType',
          style: SunmiTextStyle(
            fontSize: 28,
            align: SunmiPrintAlign.LEFT,
            bold: true,
          ),
        );
      }

      await SunmiPrinter.lineWrap(1);

      // Items table — using SunmiPrinter.printRow for proper columns
      if (items.isNotEmpty) {
        await SunmiPrinter.line();

        // Header row
        await SunmiPrinter.printRow(
          cols: [
            SunmiColumn(
              text: 'ລາຍການ',
              width: 2,
              style: SunmiTextStyle(
                bold: true,
                align: SunmiPrintAlign.LEFT,
                fontSize: 28,
              ),
            ),
            SunmiColumn(
              text: 'ຈຳນວນ',
              width: 1,
              style: SunmiTextStyle(
                bold: true,
                align: SunmiPrintAlign.CENTER,
                fontSize: 28,
              ),
            ),
            SunmiColumn(
              text: 'ລາຄາ',
              width: 1,
              style: SunmiTextStyle(
                bold: true,
                align: SunmiPrintAlign.RIGHT,
                fontSize: 28,
              ),
            ),
          ],
        );
        await SunmiPrinter.line();

        // Data rows
        for (var item in items) {
          final name = (item['name'] ?? '') as String;
          final quantity = item['quantity'] ?? 1;
          final price = item['price'] ?? 0.0;
          final itemTotal = _formatPrice(price * quantity);

          await SunmiPrinter.printRow(
            cols: [
              SunmiColumn(
                text: name,
                width: 2,
                style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
              ),
              SunmiColumn(
                text: 'x$quantity',
                width: 1,
                style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
              ),
              SunmiColumn(
                text: itemTotal,
                width: 1,
                style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
              ),
            ],
          );
        }

        await SunmiPrinter.line();
      }

      await SunmiPrinter.lineWrap(1);

      // Totals
      await SunmiPrinter.printText(
        'ລວມຍອດ: ${_formatPrice(total)} LAK',
        style: SunmiTextStyle(
          fontSize: 28,
          align: SunmiPrintAlign.RIGHT,
          bold: true,
        ),
      );

      // Payment method
      if (paymentMethod.isNotEmpty) {
        await SunmiPrinter.lineWrap(1);
        await SunmiPrinter.printText(
          '$paymentMethod: ${_formatPrice(total)} LAK',
          style: SunmiTextStyle(
            align: SunmiPrintAlign.RIGHT,
            bold: true,
            fontSize: 28,
          ),
        );
      }

      await SunmiPrinter.lineWrap(1);

      // Footer
      if (footer.isNotEmpty) {
        await SunmiPrinter.lineWrap(1);
        await SunmiPrinter.printText(footer);
      }

      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.cutPaper();

      return true;
    } catch (e) {
      print('Error printing receipt on Sunmi: $e');
      return false;
    }
  }

  Future<List<int>> _renderReceiptImage({
    required String header,
    required String orderId,
    required String tableNumber,
    required String serverName,
    required String dateStr,
    required List<Map<String, dynamic>> items,
    required double total,
    required String footer,
    String orderType = '',
    String paymentMethod = '',
    String paperWidth = '80 mm',
  }) async {
    try {
      // 1:1 pixel rendering — no scaling for maximum sharpness
      final w = paperWidth == '58 mm' ? 384 : 576;
      final pad = 24.0; // bigger padding so nothing gets cut off
      final cw = w - pad * 2;

      // Sizes — tall rows for readable text
      final rowH = 44.0;
      final hdrRowH = 46.0;
      final gap = 12.0;

      // Estimate height
      var estH = 30.0;
      estH += 50; // header
      if (orderId.isNotEmpty) estH += 36;
      estH += gap;
      if (tableNumber.isNotEmpty) estH += 32;
      estH += 32 * 2; // date + server
      if (orderType.isNotEmpty) estH += 32; // type
      estH += gap * 2;
      if (items.isNotEmpty) estH += hdrRowH + items.length * rowH + gap;
      estH += 40 * 2 + gap; // totals
      estH += 32 + gap; // exchange rate
      estH += 30; // bottom

      // Use generous height for white background — will crop to actual content later
      final maxH = estH * 3;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), maxH),
        Paint()..color = Colors.white,
      );

      var y = 16.0;

      // ── Helpers ──
      ui.Paragraph mkP(
        String text,
        double fs, {
        FontWeight fw = FontWeight.w700,
        TextAlign align = TextAlign.left,
        double? maxW,
      }) {
        final b =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: align,
                  fontSize: fs,
                  fontWeight: fw,
                  height: 1.25,
                ),
              )
              ..pushStyle(
                ui.TextStyle(color: Colors.black, fontSize: fs, fontWeight: fw),
              )
              ..addText(text);
        return b.build()..layout(ui.ParagraphConstraints(width: maxW ?? cw));
      }

      void centered(String text, double fs, {FontWeight fw = FontWeight.w800}) {
        final p = mkP(text, fs, fw: fw, align: TextAlign.center);
        canvas.drawParagraph(p, Offset(pad, y));
        y += p.height + 4;
      }

      void leftRight(
        String l,
        String r,
        double fs, {
        FontWeight fw = FontWeight.w700,
      }) {
        final lp = mkP(l, fs, fw: fw);
        final rp = mkP(r, fs, fw: fw, align: TextAlign.right);
        canvas.drawParagraph(lp, Offset(pad, y));
        canvas.drawParagraph(rp, Offset(pad, y));
        y += lp.height + 4;
      }

      void dottedLine() {
        final dp =
            Paint()
              ..color = Colors.black
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round;
        for (double x = pad; x < w - pad; x += 6) {
          canvas.drawCircle(Offset(x, y), 1, dp);
        }
        y += 8;
      }

      // ─── Header ───
      if (header.isNotEmpty) {
        centered(header, 28, fw: FontWeight.w900);
      }
      if (orderId.isNotEmpty) {
        centered(orderId, 20, fw: FontWeight.w700);
      }
      y += gap;

      // ─── Details ───
      if (tableNumber.isNotEmpty) {
        final p = mkP('Table: $tableNumber', 20, fw: FontWeight.w600);
        canvas.drawParagraph(p, Offset(pad, y));
        y += p.height + 3;
      }
      var p = mkP('Date: $dateStr', 20, fw: FontWeight.w600);
      canvas.drawParagraph(p, Offset(pad, y));
      y += p.height + 3;
      p = mkP('Employee: $serverName', 20, fw: FontWeight.w600);
      canvas.drawParagraph(p, Offset(pad, y));
      y += p.height + 3;
      if (orderType.isNotEmpty) {
        p = mkP('Type: $orderType', 20, fw: FontWeight.w600);
        canvas.drawParagraph(p, Offset(pad, y));
        y += p.height + 3;
      }
      y += gap;

      dottedLine();
      y += 4;

      // ─── Items Table ───
      if (items.isNotEmpty) {
        final c1 = cw * 0.08;
        final c2 = cw * 0.47;
        final c3 = cw * 0.13;
        final c4 = cw * 0.32;
        final fs = 20.0;
        final borderP =
            Paint()
              ..color = Colors.black
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke;
        final thinP =
            Paint()
              ..color = Colors.black
              ..strokeWidth = 1;

        final tableTop = y;

        // Header bg
        canvas.drawRect(
          Rect.fromLTWH(pad, y, cw, hdrRowH),
          Paint()..color = Colors.grey.shade300,
        );

        void cell(
          String text,
          double x,
          double colW,
          double cy, {
          TextAlign align = TextAlign.center,
          FontWeight fw = FontWeight.w900,
        }) {
          final cp = mkP(text, fs, fw: fw, align: align, maxW: colW - 6);
          canvas.drawParagraph(
            cp,
            Offset(x + 3, cy + (hdrRowH - cp.height) / 2),
          );
        }

        cell('ລ/ດ', pad, c1, y);
        cell('ລາຍການ', pad + c1, c2, y);
        cell('ຈຳນວນ', pad + c1 + c2, c3, y);
        cell('ລາຄາ', pad + c1 + c2 + c3, c4, y, align: TextAlign.right);
        y += hdrRowH;

        canvas.drawLine(Offset(pad, y), Offset(pad + cw, y), borderP);

        // Data rows
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final name = (item['name'] ?? '').toString();
          final qty = item['quantity'] ?? 1;
          final price = (item['price'] ?? 0.0) as num;
          final subtotal = qty * price.toDouble();

          void dataCell(
            String text,
            double x,
            double colW, {
            TextAlign align = TextAlign.center,
            FontWeight fw = FontWeight.w600,
          }) {
            final cp = mkP(text, fs, fw: fw, align: align, maxW: colW - 6);
            canvas.drawParagraph(cp, Offset(x + 3, y + (rowH - cp.height) / 2));
          }

          dataCell('${i + 1}', pad, c1);
          dataCell(name, pad + c1, c2, align: TextAlign.left);
          dataCell('$qty', pad + c1 + c2, c3);
          dataCell(
            _formatPrice(subtotal),
            pad + c1 + c2 + c3,
            c4,
            align: TextAlign.right,
            fw: FontWeight.w700,
          );
          y += rowH;

          if (i < items.length - 1) {
            canvas.drawLine(Offset(pad, y), Offset(pad + cw, y), thinP);
          }
        }

        // Table border + vertical lines
        final tableBottom = y;
        canvas.drawRect(
          Rect.fromLTWH(pad, tableTop, cw, tableBottom - tableTop),
          borderP,
        );
        canvas.drawLine(
          Offset(pad + c1, tableTop),
          Offset(pad + c1, tableBottom),
          thinP,
        );
        canvas.drawLine(
          Offset(pad + c1 + c2, tableTop),
          Offset(pad + c1 + c2, tableBottom),
          thinP,
        );
        canvas.drawLine(
          Offset(pad + c1 + c2 + c3, tableTop),
          Offset(pad + c1 + c2 + c3, tableBottom),
          thinP,
        );

        y += gap;
      }

      // ─── Totals ───
      dottedLine();
      y += 2;
      leftRight(
        'ຍອດລວມ (LAK):',
        '${_formatPrice(total)} ₭',
        28,
        fw: FontWeight.w900,
      );
      if (paymentMethod.isNotEmpty) {
        leftRight(
          '$paymentMethod:',
          '${_formatPrice(total)} ₭',
          18,
          fw: FontWeight.w700,
        );
      }
      y += gap;
      // ─── Convert to ESC/POS ───
      final contentH = y.ceil();
      final picture = recorder.endRecording();
      // Render full canvas (white bg covers everything)
      final uiImage = await picture.toImage(w, (maxH).ceil());
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      var decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) return [];

      // Crop to actual content height — removes any excess white/black area
      decodedImage = img.copyCrop(
        decodedImage,
        x: 0,
        y: 0,
        width: w,
        height: contentH,
      );

      final bwImage = _applySharpContrast(img.grayscale(decodedImage));
      final escPosBytes = _imageToEscPosBitmap(bwImage);

      List<int> bytes = [];
      bytes.addAll([0x1B, 0x40]); // init printer
      bytes.addAll([
        0x1B,
        0x33,
        24,
      ]); // set line spacing to 24 dots (match band height)
      bytes.addAll(escPosBytes);
      bytes.addAll([0x1B, 0x32]); // restore default line spacing
      bytes.addAll([0x0A, 0x0A, 0x0A]); // feed
      bytes.addAll([0x1D, 0x56, 0x00]); // cut

      return bytes;
    } catch (e) {
      print('Error rendering receipt: $e');
      return [];
    }
  }

  img.Image _applySharpContrast(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = pixel.r.toInt();
        final newGray = gray < 128 ? 0 : 255;
        image.setPixelRgb(x, y, newGray, newGray, newGray);
      }
    }
    return image;
  }

  List<int> _imageToEscPosBitmap(img.Image image) {
    List<int> bytes = [];
    final width = image.width;
    final height = image.height;

    for (int y = 0; y < height; y += 24) {
      bytes.addAll([0x1B, 0x2A, 33]);
      bytes.addAll([width & 0xFF, (width >> 8) & 0xFF]);

      for (int x = 0; x < width; x++) {
        List<int> column = [0, 0, 0];

        for (int k = 0; k < 24; k++) {
          final py = y + k;
          if (py < height) {
            final pixel = image.getPixel(x, py);
            final gray =
                (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).toInt();

            if (gray < 128) {
              final byteIndex = k ~/ 8;
              final bitIndex = 7 - (k % 8);
              column[byteIndex] |= (1 << bitIndex);
            }
          }
        }

        bytes.addAll(column);
      }

      bytes.add(0x0A);
    }

    return bytes;
  }

  Future<bool> _sendToPrinter(List<int> bytes) async {
    try {
      if (_bluetoothDevice != null && _writeCharacteristic != null) {
        // Check if characteristic supports write without response
        final canWriteWithoutResponse =
            _writeCharacteristic!.properties.writeWithoutResponse;

        // Get current MTU (default is 23, which means 20 bytes payload)
        // If we successfully requested a larger MTU (e.g. 512), this will be higher.
        int mtu = 23;
        try {
          mtu = _bluetoothDevice!.mtuNow;
        } catch (e) {
          print('Error reading MTU: $e');
        }

        // Calculate safe chunk size (MTU - 3 bytes overhead)
        // If write without response is supported, we can sometimes go higher, but safe is MTU-3.
        // If write WITH response (our case), we MUST respect MTU-3.
        final safeChunkSize = (mtu > 3) ? mtu - 3 : 20;

        // If we can write without response, we might force a larger chunk if MTU is small but the device handles it.
        // But usually sticking to MTU is safest.
        // For the user's Sunmi V2, we know it requires WITH response, so we depend on MTU.
        final chunkSize = canWriteWithoutResponse ? 200 : safeChunkSize;

        print(
          'Sending to printer: MTU=$mtu, ChunkSize=$chunkSize, Mode=${canWriteWithoutResponse ? "NoResponse" : "WithResponse"}',
        );

        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);

          await _writeCharacteristic!.write(
            chunk,
            withoutResponse: canWriteWithoutResponse,
          );

          // Small delay to prevent UI thread freezing and buffer overflow
          // If with response, we need to wait for the ack, but a small delay helps stability.
          await Future.delayed(
            Duration(milliseconds: canWriteWithoutResponse ? 5 : 2),
          );
        }
        return true;
      } else if (_networkSocket != null) {
        _networkSocket!.add(bytes);
        await _networkSocket!.flush();
        return true;
      } else {
        throw Exception('No printer connection');
      }
    } catch (e) {
      print('Error sending to printer: $e');
      return false;
    }
  }

  /// Pad 3 columns into a fixed-width row for receipt printing (32 char width)
  /// Format 3-column row with simple fixed spacing
  /// Uses enough spaces between columns to keep them visually separated
  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = formatted;
    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }
    return parts.join(',');
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}

final printerServiceProvider = Provider<PrinterService>((ref) {
  final service = PrinterService();
  ref.onDispose(() => service.dispose());
  return service;
});
