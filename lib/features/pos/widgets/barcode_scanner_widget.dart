import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

const int _posBarcodeFormats =
    Format.ean13 |
    Format.ean8 |
    Format.code128 |
    Format.code39 |
    Format.code93 |
    Format.codabar |
    Format.upca |
    Format.upce |
    Format.qrCode;

/// Barcode Scanner Widget
class BarcodeScannerWidget extends ConsumerStatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const BarcodeScannerWidget({super.key, required this.onBarcodeScanned});

  @override
  ConsumerState<BarcodeScannerWidget> createState() =>
      _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends ConsumerState<BarcodeScannerWidget> {
  bool isScanned = false;

  void _onScan(Code code) {
    if (isScanned) return;
    final value = code.text;
    if (value == null || value.isEmpty) return;

    setState(() {
      isScanned = true;
    });

    widget.onBarcodeScanned(value);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final localization = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translations.get('scan_barcode', localization.languageCode),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: ReaderWidget(
              onScan: _onScan,
              codeFormat: _posBarcodeFormats,
              tryHarder: true,
              tryInverted: true,
              showFlashlight: true,
              showToggleCamera: false,
              showGallery: false,
              showScannerOverlay: true,
              scanDelay: const Duration(milliseconds: 500),
              actionButtonsBackgroundColor: Colors.black54,
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
                      Translations.get(
                        'point_camera_barcode',
                        localization.languageCode,
                      ),
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
                      Translations.get(
                        'barcode_visible_well_lit',
                        localization.languageCode,
                      ),
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
