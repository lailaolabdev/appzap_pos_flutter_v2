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

  Future<bool> connectBluetooth(PrinterDevice device) async {
    try {
      await disconnect();

      final bluetoothDevice = BluetoothDevice.fromId(device.id);
      await bluetoothDevice.connect(timeout: const Duration(seconds: 10));

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
      _connectedDevice = device.copyWith(isConnected: true);
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
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  PrinterDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice?.isConnected ?? false;

  Future<bool> testPrint() async {
    try {
      if (!isConnected) {
        throw Exception('Printer not connected');
      }

      final isWiFi = _connectedDevice?.type == PrinterConnectionType.wifi;

      final bytes = await _renderReceiptImage(
        header: 'TEST PRINT',
        orderId: 'AppZap POS',
        tableNumber: '',
        serverName: 'Staff',
        dateStr: DateTime.now().toString().substring(0, 19),
        items: [],
        total: 0,
        footer: '',
        isWiFi: isWiFi,
      );

      return await _sendToPrinter(bytes);
    } catch (e) {
      print('Error test print: $e');
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
  }) async {
    try {
      if (!isConnected) {
        throw Exception('Printer not connected');
      }

      final isWiFi = _connectedDevice?.type == PrinterConnectionType.wifi;
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
        isWiFi: isWiFi,
      );

      return await _sendToPrinter(bytes);
    } catch (e) {
      print('Error printing receipt: $e');
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
    required bool isWiFi,
  }) async {
    try {
      final width = isWiFi ? 576 : 512;
      final renderWidth = width * 3;

      final baseHeight = 500;
      final itemHeight = items.isEmpty ? 100 : items.length * 90;
      final renderHeight = (baseHeight + itemHeight) * 3;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, renderWidth.toDouble(), renderHeight.toDouble()),
        bgPaint,
      );

      double currentY = 60.0;
      final padding = 30.0;
      final contentWidth = renderWidth - (padding * 2);

      void drawText(
        String text,
        double y, {
        double fontSize = 48.0,
        FontWeight fontWeight = FontWeight.w600,
        TextAlign align = TextAlign.left,
      }) {
        final paragraphBuilder =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: align,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  height: 1.15,
                ),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  letterSpacing: 1.5,
                ),
              )
              ..addText(text);

        final paragraph =
            paragraphBuilder.build()
              ..layout(ui.ParagraphConstraints(width: contentWidth));

        final xPos =
            align == TextAlign.center
                ? padding + (contentWidth - paragraph.width) / 2
                : padding;
        canvas.drawParagraph(paragraph, Offset(xPos, y));
      }

      // Header
      if (header.isNotEmpty) {
        drawText(
          header,
          currentY,
          fontSize: 60,
          fontWeight: FontWeight.w800,
          align: TextAlign.center,
        );
        currentY += 90;
      }

      if (orderId.isNotEmpty) {
        drawText(
          orderId,
          currentY,
          fontSize: 48,
          fontWeight: FontWeight.w600,
          align: TextAlign.center,
        );
        currentY += 70;
      }

      currentY += 10;

      if (tableNumber.isNotEmpty) {
        drawText(
          'Table: $tableNumber',
          currentY,
          fontSize: 42,
          fontWeight: FontWeight.w500,
        );
        currentY += 55;
      }

      drawText(
        'Date: $dateStr',
        currentY,
        fontSize: 42,
        fontWeight: FontWeight.w500,
      );
      currentY += 55;

      drawText(
        'Server: $serverName',
        currentY,
        fontSize: 42,
        fontWeight: FontWeight.w500,
      );
      currentY += 65;

      // Dotted separator
      final dotPaint =
          Paint()
            ..color = Colors.grey.shade700
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round;

      for (double x = padding; x < renderWidth - padding; x += 24) {
        canvas.drawCircle(Offset(x, currentY), 2, dotPaint);
      }
      currentY += 50;

      // Items table - FIXED WITH 4 COLUMNS
      if (items.isNotEmpty) {
        final tableTop = currentY;
        final tableWidth = contentWidth;
        final rowHeight = 90.0;
        final headerHeight = 80.0;
        final tableHeight = headerHeight + (items.length * rowHeight);

        final borderPaint =
            Paint()
              ..color = Colors.black
              ..strokeWidth = 5
              ..style = PaintingStyle.stroke;

        final tableRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(padding, tableTop, tableWidth, tableHeight),
          const Radius.circular(20),
        );
        canvas.drawRRect(tableRect, borderPaint);

        final headerBgPaint = Paint()..color = Colors.grey.shade200;

        final headerPath =
            Path()..addRRect(
              RRect.fromRectAndCorners(
                Rect.fromLTWH(
                  padding + 5,
                  tableTop + 5,
                  tableWidth - 10,
                  headerHeight - 5,
                ),
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
              ),
            );
        canvas.drawPath(headerPath, headerBgPaint);

        // Column widths for 4 columns - ADJUSTED
        final col1Width = tableWidth * 0.08; // ລ/ດ (No)
        final col2Width = tableWidth * 0.30; // ລາຍການ (Product)
        final col3Width = tableWidth * 0.10; // ຈຳນວນ (Qty)
        final col4Width = tableWidth * 0.15; // ລາຄາ (Price) - INCREASED

        // Vertical lines
        final colLinePaint =
            Paint()
              ..color = Colors.grey.shade600
              ..strokeWidth = 3;

        canvas.drawLine(
          Offset(padding + col1Width, tableTop + 5),
          Offset(padding + col1Width, tableTop + tableHeight - 5),
          colLinePaint,
        );

        canvas.drawLine(
          Offset(padding + col1Width + col2Width, tableTop + 5),
          Offset(padding + col1Width + col2Width, tableTop + tableHeight - 5),
          colLinePaint,
        );

        canvas.drawLine(
          Offset(padding + col1Width + col2Width + col3Width, tableTop + 5),
          Offset(
            padding + col1Width + col2Width + col3Width,
            tableTop + tableHeight - 5,
          ),
          colLinePaint,
        );

        // Header text
        final headerY = tableTop + 24;

        // ລ/ດ header
        final noHeader =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: TextAlign.center,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: Colors.black,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..addText('ລ/ດ');
        final noPara =
            noHeader.build()..layout(ui.ParagraphConstraints(width: col1Width));
        canvas.drawParagraph(noPara, Offset(padding, headerY));

        // ລາຍການ header
        final productHeader =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: TextAlign.center,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: Colors.black,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..addText('ລາຍການ');
        final productPara =
            productHeader.build()
              ..layout(ui.ParagraphConstraints(width: col2Width));
        canvas.drawParagraph(productPara, Offset(padding + col1Width, headerY));

        // ຈຳນວນ header
        final qtyHeader =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: TextAlign.center,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: Colors.black,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..addText('ຈຳນວນ');
        final qtyPara =
            qtyHeader.build()
              ..layout(ui.ParagraphConstraints(width: col3Width));
        canvas.drawParagraph(
          qtyPara,
          Offset(padding + col1Width + col2Width, headerY),
        );

        // ລາຄາ header
        final priceHeader =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: TextAlign.center,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: Colors.black,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..addText('ລາຄາ');
        final pricePara =
            priceHeader.build()
              ..layout(ui.ParagraphConstraints(width: col4Width));
        canvas.drawParagraph(
          pricePara,
          Offset(padding + col1Width + col2Width + col3Width, headerY),
        );

        // Horizontal line after header
        final headerLinePaint =
            Paint()
              ..color = Colors.black
              ..strokeWidth = 4;
        canvas.drawLine(
          Offset(padding + 5, tableTop + headerHeight),
          Offset(padding + tableWidth - 5, tableTop + headerHeight),
          headerLinePaint,
        );

        // Draw items
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final name = (item['name'] ?? '').toString();
          final qty = item['quantity'] ?? 1;
          final price = item['price'] ?? 0.0;
          final subtotal = qty * price;

          final rowY = tableTop + headerHeight + (i * rowHeight) + 28;

          // Row number
          final noBuilder =
              ui.ParagraphBuilder(
                  ui.ParagraphStyle(
                    textAlign: TextAlign.center,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                )
                ..pushStyle(
                  ui.TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                )
                ..addText('${i + 1}');
          final noItemPara =
              noBuilder.build()
                ..layout(ui.ParagraphConstraints(width: col1Width));
          canvas.drawParagraph(noItemPara, Offset(padding, rowY));

          // Product name
          final productBuilder =
              ui.ParagraphBuilder(
                  ui.ParagraphStyle(
                    textAlign: TextAlign.left,
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                  ),
                )
                ..pushStyle(
                  ui.TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                )
                ..addText(name);
          final productItemPara =
              productBuilder.build()
                ..layout(ui.ParagraphConstraints(width: col2Width - 20));
          canvas.drawParagraph(
            productItemPara,
            Offset(padding + col1Width + 10, rowY),
          );

          // Quantity
          final qtyBuilder =
              ui.ParagraphBuilder(
                  ui.ParagraphStyle(
                    textAlign: TextAlign.center,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                )
                ..pushStyle(
                  ui.TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                )
                ..addText('$qty');
          final qtyItemPara =
              qtyBuilder.build()
                ..layout(ui.ParagraphConstraints(width: col3Width));
          canvas.drawParagraph(
            qtyItemPara,
            Offset(padding + col1Width + col2Width, rowY),
          );

          // Price - Right aligned in column
          final priceBuilder =
              ui.ParagraphBuilder(
                  ui.ParagraphStyle(
                    textAlign: TextAlign.right,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                )
                ..pushStyle(
                  ui.TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                )
                ..addText(_formatPrice(subtotal));
          final priceItemPara =
              priceBuilder.build()
                ..layout(ui.ParagraphConstraints(width: col4Width - 30));
          canvas.drawParagraph(
            priceItemPara,
            Offset(padding + col1Width + col2Width + col3Width + 15, rowY),
          );

          // Row separator
          if (i < items.length - 1) {
            final rowLinePaint =
                Paint()
                  ..color = Colors.grey.shade400
                  ..strokeWidth = 2;
            canvas.drawLine(
              Offset(
                padding + 5,
                tableTop + headerHeight + ((i + 1) * rowHeight),
              ),
              Offset(
                padding + tableWidth - 5,
                tableTop + headerHeight + ((i + 1) * rowHeight),
              ),
              rowLinePaint,
            );
          }
        }

        currentY = tableTop + tableHeight + 60;
      }

      // Totals section
      drawText('ຮວມ:', currentY, fontSize: 46, fontWeight: FontWeight.w700);

      final totalBuilder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.right,
                fontSize: 46,
                fontWeight: FontWeight.w700,
              ),
            )
            ..pushStyle(
              ui.TextStyle(
                color: Colors.black,
                fontSize: 46,
                fontWeight: FontWeight.w700,
              ),
            )
            ..addText(_formatPrice(total));
      final totalPara =
          totalBuilder.build()
            ..layout(ui.ParagraphConstraints(width: contentWidth));
      canvas.drawParagraph(totalPara, Offset(padding, currentY));
      currentY += 65;

      currentY += 10;

      drawText(
        'ຍອດລວມ (LAK):',
        currentY,
        fontSize: 44,
        fontWeight: FontWeight.w600,
      );
      final lakBuilder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.right,
                fontSize: 44,
                fontWeight: FontWeight.w600,
              ),
            )
            ..pushStyle(
              ui.TextStyle(
                color: Colors.black,
                fontSize: 44,
                fontWeight: FontWeight.w600,
              ),
            )
            ..addText(_formatPrice(total));
      final lakPara =
          lakBuilder.build()
            ..layout(ui.ParagraphConstraints(width: contentWidth));
      canvas.drawParagraph(lakPara, Offset(padding, currentY));
      currentY += 60;

      final usd = total / 23000;
      drawText(
        'ຍອດລວມ (USD):',
        currentY,
        fontSize: 44,
        fontWeight: FontWeight.w600,
      );
      final usdBuilder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.right,
                fontSize: 44,
                fontWeight: FontWeight.w600,
              ),
            )
            ..pushStyle(
              ui.TextStyle(
                color: Colors.black,
                fontSize: 44,
                fontWeight: FontWeight.w600,
              ),
            )
            ..addText(usd.toStringAsFixed(2));
      final usdPara =
          usdBuilder.build()
            ..layout(ui.ParagraphConstraints(width: contentWidth));
      canvas.drawParagraph(usdPara, Offset(padding, currentY));
      currentY += 75;

      // Dotted separator
      for (double x = padding; x < renderWidth - padding; x += 24) {
        canvas.drawCircle(Offset(x, currentY), 2, dotPaint);
      }
      currentY += 50;

      // Exchange rate box
      final boxWidth = contentWidth * 0.85;
      final boxHeight = 90.0;
      final boxX = padding + (contentWidth - boxWidth) / 2;

      final exchangeBoxPaint =
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4;

      final exchangeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, currentY, boxWidth, boxHeight),
        const Radius.circular(16),
      );
      canvas.drawRRect(exchangeRRect, exchangeBoxPaint);

      final exchangeText =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.center,
                fontSize: 38,
                fontWeight: FontWeight.w600,
              ),
            )
            ..pushStyle(
              ui.TextStyle(
                color: Colors.black,
                fontSize: 38,
                fontWeight: FontWeight.w600,
              ),
            )
            ..addText('ອັດຕາແລກປ່ຽນ = USD 1 = 23,000');
      final exchangePara =
          exchangeText.build()
            ..layout(ui.ParagraphConstraints(width: boxWidth - 30));
      canvas.drawParagraph(exchangePara, Offset(boxX + 15, currentY + 26));
      currentY += boxHeight + 50;

      if (footer.isNotEmpty) {
        drawText(
          footer,
          currentY,
          fontSize: 42,
          fontWeight: FontWeight.w500,
          align: TextAlign.center,
        );
        currentY += 65;
      }

      drawText(
        'Thank you for your visit!',
        currentY,
        fontSize: 44,
        fontWeight: FontWeight.w700,
        align: TextAlign.center,
      );

      // Convert to image
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(renderWidth, renderHeight);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      var decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) return [];

      decodedImage = img.copyResize(
        decodedImage,
        width: width,
        interpolation: img.Interpolation.cubic,
      );

      final grayscaleImage = img.grayscale(decodedImage);
      final finalImage = _applySharpContrast(grayscaleImage);

      final escPosBytes = _imageToEscPosBitmap(finalImage);

      List<int> bytes = [];
      bytes.addAll([0x1B, 0x40]);
      bytes.addAll(escPosBytes);
      bytes.addAll([0x0A, 0x0A, 0x0A]);
      bytes.addAll([0x1D, 0x56, 0x00]);

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
        final newGray = gray < 220 ? 0 : 255;
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
        const chunkSize = 200;
        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          await _writeCharacteristic!.write(chunk, withoutResponse: true);
          await Future.delayed(const Duration(milliseconds: 5));
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
