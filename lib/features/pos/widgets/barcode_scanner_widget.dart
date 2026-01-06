import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme.dart';

/// Barcode Scanner Widget
class BarcodeScannerWidget extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const BarcodeScannerWidget({super.key, required this.onBarcodeScanned});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  late MobileScannerController controller;
  bool isScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (isScanned) return; // Prevent multiple scans

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        isScanned = true;
      });

      final barcode = barcodes.first.rawValue!;

      // Haptic feedback
      // HapticFeedback.lightImpact();

      // Call the callback
      widget.onBarcodeScanned(barcode);

      // Close the scanner after successful scan
      Navigator.of(context).pop(barcode);
    }
  }

  void _toggleFlash() {
    controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleFlash,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // Scanner view
                MobileScanner(
                  controller: controller,
                  onDetect: _onBarcodeDetected,
                ),

                // Overlay with scanning frame
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: AppTheme.primaryOrange,
                      borderRadius: 12,
                      borderLength: 30,
                      borderWidth: 4,
                      cutOutSize: 250,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: MediaQuery.of(context).size.height < 700 ? 32 : 48,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height < 700 ? 8 : 16,
                  ),
                  Flexible(
                    child: Text(
                      'Point the camera at a barcode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize:
                            MediaQuery.of(context).size.height < 700 ? 14 : 16,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height < 700 ? 4 : 8,
                  ),
                  Flexible(
                    child: Text(
                      'Make sure the barcode is clearly visible and well-lit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                        fontSize:
                            MediaQuery.of(context).size.height < 700 ? 12 : 14,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
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

/// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path outerPath = Path()..addRect(rect);
    Path cutOutRect =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: rect.center,
              width: cutOutSize,
              height: cutOutSize,
            ),
            Radius.circular(borderRadius),
          ),
        );
    return Path.combine(PathOperation.difference, outerPath, cutOutRect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderLength = this.borderLength;
    final borderWidth = this.borderWidth;
    final borderRadius = this.borderRadius;
    final cutOutSize = this.cutOutSize;

    final backgroundPaint =
        Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Draw overlay
    canvas.drawPath(getOuterPath(rect), backgroundPaint);

    // Draw border corners
    final path =
        Path()
          // Top left
          ..moveTo(cutOutRect.left, cutOutRect.top + borderRadius)
          ..quadraticBezierTo(
            cutOutRect.left,
            cutOutRect.top,
            cutOutRect.left + borderRadius,
            cutOutRect.top,
          )
          ..lineTo(cutOutRect.left + borderLength, cutOutRect.top)
          // Top right
          ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
          ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
          ..quadraticBezierTo(
            cutOutRect.right,
            cutOutRect.top,
            cutOutRect.right,
            cutOutRect.top + borderRadius,
          )
          ..lineTo(cutOutRect.right, cutOutRect.top + borderLength)
          // Bottom right
          ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
          ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
          ..quadraticBezierTo(
            cutOutRect.right,
            cutOutRect.bottom,
            cutOutRect.right - borderRadius,
            cutOutRect.bottom,
          )
          ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom)
          // Bottom left
          ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
          ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
          ..quadraticBezierTo(
            cutOutRect.left,
            cutOutRect.bottom,
            cutOutRect.left,
            cutOutRect.bottom - borderRadius,
          )
          ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
