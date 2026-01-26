import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

enum PrinterConnectionType { bluetooth, wifi, usb }

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

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Request Bluetooth permissions
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

  /// Check if Bluetooth is enabled
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

  /// Enable Bluetooth
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

  /// Scan for Bluetooth devices
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

      print('=== Starting Bluetooth Scan ===');

      // Get connected devices
      final connectedDevices = FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        if (!foundDeviceIds.contains(device.remoteId.toString())) {
          foundDeviceIds.add(device.remoteId.toString());
          devices.add(_createPrinterDevice(device));
        }
      }

      // Get paired devices
      final systemDevices = await FlutterBluePlus.systemDevices([]);
      for (var device in systemDevices) {
        if (!foundDeviceIds.contains(device.remoteId.toString())) {
          foundDeviceIds.add(device.remoteId.toString());
          devices.add(_createPrinterDevice(device));
        }
      }

      // Quick scan for new devices (3 seconds)
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

      print('Found ${devices.length} devices');
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

  /// Connect to Bluetooth printer
  Future<bool> connectBluetooth(PrinterDevice device) async {
    try {
      await disconnect();

      final bluetoothDevice = BluetoothDevice.fromId(device.id);
      await bluetoothDevice.connect(timeout: const Duration(seconds: 10));

      final services = await bluetoothDevice.discoverServices();

      print('=== Discovered Services ===');
      BluetoothCharacteristic? writeChar;

      // Skip standard GATT services
      final excludedServices = [
        '00001800', // Generic Access
        '00001801', // Generic Attribute
        '0000180a', // Device Information
      ];

      for (var service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();
        print('Service: $serviceUuid');

        if (excludedServices.any((uuid) => serviceUuid.contains(uuid))) {
          continue;
        }

        for (var char in service.characteristics) {
          final charUuid = char.uuid.toString().toLowerCase();
          print(
            '  Char: $charUuid (W:${char.properties.write}, WNR:${char.properties.writeWithoutResponse})',
          );

          // Skip device name/info characteristics
          if (charUuid.contains('2a00') || charUuid.contains('2a01')) {
            continue;
          }

          if (char.properties.writeWithoutResponse || char.properties.write) {
            writeChar = char;
            print('  ✓ Using this characteristic for printing');
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
      _connectedDevice = device.copyWith(isConnected: true);
      _connectionStatusController.add(true);

      print('Connected to Bluetooth printer');
      return true;
    } catch (e) {
      print('Error connecting to Bluetooth: $e');
      _connectionStatusController.add(false);
      return false;
    }
  }

  /// Scan WiFi printers
  Future<List<PrinterDevice>> scanWiFiPrinters() async {
    return [];
  }

  /// Connect to WiFi printer
  Future<bool> connectWiFi(String ipAddress, {int port = 9100}) async {
    try {
      final trimmedIp = ipAddress.trim();

      if (!_isValidIpAddress(trimmedIp)) {
        throw Exception('Invalid IP address format');
      }

      await disconnect();

      final socket = await Socket.connect(
        trimmedIp,
        port,
        timeout: const Duration(seconds: 5),
      );

      _networkSocket = socket;
      _connectedDevice = PrinterDevice(
        id: ipAddress,
        name: 'Network Printer',
        address: '$ipAddress:$port',
        type: PrinterConnectionType.wifi,
        isConnected: true,
      );
      _connectionStatusController.add(true);
      print('Connected to WiFi printer');
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

  /// Disconnect
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

      _connectedDevice = null;
      _connectionStatusController.add(false);
      print('Disconnected from printer');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  PrinterDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice?.isConnected ?? false;

  /// Test print
  Future<bool> testPrint() async {
    try {
      if (!isConnected) {
        throw Exception('Printer not connected');
      }

      final isWiFi = _connectedDevice?.type == PrinterConnectionType.wifi;

      String content =
          'TEST PRINT\n\n'
          'AppZap POS System\n\n'
          'Printer: ${_connectedDevice?.name}\n'
          'Type: ${isWiFi ? "WIFI (80mm)" : "BLUETOOTH (58mm)"}\n\n'
          'Connection Successful!\n'
          '${DateTime.now().toString().substring(0, 19)}';

      final bytes = await _convertTextToImageBytes(
        content,
        width: isWiFi ? 576 : 512, // 58mm = 512px FULL width
      );

      return await _sendToPrinter(bytes);
    } catch (e) {
      print('Error test print: $e');
      return false;
    }
  }

  /// Print receipt
  Future<bool> printReceipt({
    required String header,
    required List<Map<String, dynamic>> items,
    required double total,
    String? orderId,
    String? tableNumber,
    String? serverName,
    String? footer,
  }) async {
    try {
      if (!isConnected) {
        throw Exception('Printer not connected');
      }

      final isWiFi = _connectedDevice?.type == PrinterConnectionType.wifi;

      final receiptText = _buildReceiptText(
        header: header,
        items: items,
        total: total,
        orderId: orderId,
        tableNumber: tableNumber,
        serverName: serverName,
        footer: footer,
        isWiFi: isWiFi,
      );

      final bytes = await _convertTextToImageBytes(
        receiptText,
        width: isWiFi ? 576 : 512, // 58mm = 512px FULL width
      );

      return await _sendToPrinter(bytes);
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }

  String _buildReceiptText({
    required String header,
    required List<Map<String, dynamic>> items,
    required double total,
    String? orderId,
    String? tableNumber,
    String? serverName,
    String? footer,
    required bool isWiFi,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}, '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${now.hour >= 12 ? "PM" : "AM"}';

    // Header
    if (header.isNotEmpty) {
      buffer.writeln(_centerText(header, isWiFi ? 48 : 32));
      buffer.writeln();
    }

    // Order ID
    if (orderId != null && orderId.isNotEmpty) {
      buffer.writeln(_centerText(orderId, isWiFi ? 48 : 32));
      buffer.writeln();
    }

    // Date and details
    buffer.writeln(dateStr);
    if (tableNumber != null && tableNumber.isNotEmpty) {
      buffer.writeln('Table: $tableNumber');
    }
    if (serverName != null && serverName.isNotEmpty) {
      buffer.writeln('Server: $serverName');
    }
    buffer.writeln();

    // Items table
    if (isWiFi) {
      // 80mm format - Simple dashed lines
      buffer.writeln('========================================');
      buffer.writeln('No  Product              Qty      Price');
      buffer.writeln('========================================');

      int itemNo = 1;
      for (final item in items) {
        final name = (item['name'] ?? '').toString();
        final qty = item['quantity'] ?? 1;
        final price = item['price'] ?? 0.0;
        final subtotal = qty * price;

        final no = itemNo.toString().padLeft(2);
        final product =
            name.length > 20 ? name.substring(0, 20) : _padRight(name, 20);
        final qtyText = 'x$qty'.padLeft(3);
        final priceText = _formatPrice(subtotal).padLeft(10);

        buffer.writeln('$no  $product  $qtyText  $priceText');
        itemNo++;
      }

      buffer.writeln('========================================');
    } else {
      // 58mm format - Simple clean format
      buffer.writeln('================================');
      buffer.writeln('No Product          Qty   Price');
      buffer.writeln('================================');

      int itemNo = 1;
      for (final item in items) {
        final name = (item['name'] ?? '').toString();
        final qty = item['quantity'] ?? 1;
        final price = item['price'] ?? 0.0;
        final subtotal = qty * price;

        final no = itemNo.toString().padLeft(2);
        final product =
            name.length > 15 ? name.substring(0, 15) : _padRight(name, 15);
        final qtyText = 'x$qty'.padLeft(3);
        final priceText = _formatPrice(subtotal).padLeft(7);

        buffer.writeln('$no $product $qtyText $priceText');
        itemNo++;
      }

      buffer.writeln('================================');
    }

    buffer.writeln();

    // Totals
    buffer.writeln('Amount:');
    final lakTotal = _formatPrice(total).padLeft(isWiFi ? 20 : 15);
    buffer.writeln('(LAK):$lakTotal');

    final usd = total / 23000;
    final usdTotal = usd.toStringAsFixed(2).padLeft(isWiFi ? 20 : 15);
    buffer.writeln('(USD):$usdTotal');
    buffer.writeln();

    // Exchange rate
    buffer.writeln(_centerText('Exchange Rate:', isWiFi ? 48 : 32));
    buffer.writeln(_centerText('USD 1 = LAK 23,000', isWiFi ? 48 : 32));
    buffer.writeln();

    // Footer
    if (footer != null && footer.isNotEmpty) {
      buffer.writeln(_centerText(footer, isWiFi ? 48 : 32));
    }

    return buffer.toString();
  }

  String _centerText(String text, int width) {
    if (text.length >= width) return text;
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Convert text to image bytes (ESC/POS bitmap)
  Future<List<int>> _convertTextToImageBytes(
    String text, {
    int width = 384,
  }) async {
    try {
      print('Converting text to image (width: $width)...');

      // Render text as image
      final image = await _renderTextToImage(text, width: width);
      if (image == null) {
        print('Failed to render text to image');
        return [];
      }

      print('Image rendered: ${image.width}x${image.height}');

      // Convert to ESC/POS bitmap
      final escPosBytes = _imageToEscPosBitmap(image);

      print('ESC/POS bytes generated: ${escPosBytes.length}');

      // Add init, feed and cut
      List<int> bytes = [];
      bytes.addAll([0x1B, 0x40]); // Init
      bytes.addAll(escPosBytes);
      bytes.addAll([0x0A, 0x0A, 0x0A]); // Feed
      bytes.addAll([0x1D, 0x56, 0x00]); // Cut

      return bytes;
    } catch (e) {
      print('Error converting text to image: $e');
      return [];
    }
  }

  /// Render text to image
  Future<img.Image?> _renderTextToImage(String text, {int width = 384}) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final lines = text.split('\n');
      final lineHeight = 20.0;
      final totalHeight = (lines.length * lineHeight + 40).toDouble();

      // White background
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), totalHeight),
        bgPaint,
      );

      // Draw text with LARGER font for better readability
      final textStyle = TextStyle(
        color: Colors.black,
        fontSize: width > 500 ? 22 : 20, // Much larger font
        fontFamily: 'Roboto',
        height: 1.2,
        fontWeight: FontWeight.w500,
      );

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: width.toDouble() - 20);
      textPainter.paint(canvas, const Offset(10, 20));

      // Convert to image
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(width, totalHeight.toInt());
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Decode
      final decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) return null;

      return img.grayscale(decodedImage);
    } catch (e) {
      print('Error rendering text: $e');
      return null;
    }
  }

  /// Convert image to ESC/POS bitmap
  List<int> _imageToEscPosBitmap(img.Image image) {
    List<int> bytes = [];

    final width = image.width;
    final height = image.height;

    // Process in 24-dot bands
    for (int y = 0; y < height; y += 24) {
      bytes.addAll([0x1B, 0x2A, 33]); // ESC * 33
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

  /// Send to printer (optimized)
  Future<bool> _sendToPrinter(List<int> bytes) async {
    try {
      print('Sending ${bytes.length} bytes to printer...');

      if (_bluetoothDevice != null && _writeCharacteristic != null) {
        // Bluetooth - use smaller chunks (BLE MTU limit is ~237 bytes)
        // Use 200 bytes to be safe
        const chunkSize = 200;
        int totalChunks = (bytes.length / chunkSize).ceil();

        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);

          int currentChunk = (i / chunkSize).floor() + 1;
          if (currentChunk % 20 == 0) {
            print('Progress: $currentChunk/$totalChunks chunks sent...');
          }

          await _writeCharacteristic!.write(chunk, withoutResponse: true);
          // Small delay to prevent buffer overflow
          await Future.delayed(const Duration(milliseconds: 5));
        }
        print('✓ Bluetooth print complete ($totalChunks chunks)');
        return true;
      } else if (_networkSocket != null) {
        // WiFi - send all at once
        _networkSocket!.add(bytes);
        await _networkSocket!.flush();
        print('✓ WiFi print complete');
        return true;
      } else {
        throw Exception('No printer connection');
      }
    } catch (e) {
      print('✗ Error sending to printer: $e');
      return false;
    }
  }

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

  String _padRight(String text, int width) {
    if (text.length >= width) return text;
    return text + (' ' * (width - text.length));
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
