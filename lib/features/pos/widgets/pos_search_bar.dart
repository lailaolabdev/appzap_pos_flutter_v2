import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';

/// Search bar with barcode scanner for POS
class POSSearchBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onBarcodeScan;

  const POSSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onBarcodeScan,
  });

  @override
  ConsumerState<POSSearchBar> createState() => _POSSearchBarState();
}

class _POSSearchBarState extends ConsumerState<POSSearchBar> {
  bool _isScanning = false;

  void _showScanner() {
    setState(() => _isScanning = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _BarcodeScannerSheet(
            onBarcodeScanned: (barcode) {
              Navigator.pop(context);
              widget.onBarcodeScan(barcode);
            },
          ),
    ).whenComplete(() {
      setState(() => _isScanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localizationProvider).languageCode;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: Translations.get(
                  'search_products_or_scan_barcode',
                  languageCode,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    widget.controller.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            widget.controller.clear();
                            widget.onSearch('');
                          },
                        )
                        : null,
                filled: true,
                fillColor: AppTheme.neutral50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: widget.onSearch,
            ),
          ),
          const SizedBox(width: 12),

          // Barcode Scanner Button
          Material(
            color:
                _isScanning
                    ? AppTheme.primaryOrange
                    : AppTheme.primaryOrangeBackground,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _showScanner,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(
                  Icons.qr_code_scanner,
                  color: _isScanning ? Colors.white : AppTheme.primaryOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barcode scanner bottom sheet
class _BarcodeScannerSheet extends ConsumerStatefulWidget {
  final ValueChanged<String> onBarcodeScanned;

  const _BarcodeScannerSheet({required this.onBarcodeScanned});

  @override
  ConsumerState<_BarcodeScannerSheet> createState() =>
      _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends ConsumerState<_BarcodeScannerSheet> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _hasScanned = true;
      widget.onBarcodeScanned(barcode!.rawValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localizationProvider).languageCode;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  Translations.get('scan_barcode', languageCode),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scanner
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

                // Scan overlay
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryOrange, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                // Corner decorations
                Positioned(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomPaint(painter: _ScannerOverlayPainter()),
                  ),
                ),
              ],
            ),
          ),

          // Hint
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              Translations.get('position_barcode_frame', languageCode),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),

          // Flash toggle
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: IconButton(
              onPressed: () => _scannerController.toggleTorch(),
              icon: ValueListenableBuilder(
                valueListenable: _scannerController,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.white,
                    size: 32,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay corners
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppTheme.primaryOrange
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const radius = 12.0;

    // Top-left corner
    final tlPath =
        Path()
          ..moveTo(0, cornerLength)
          ..lineTo(0, radius)
          ..quadraticBezierTo(0, 0, radius, 0)
          ..lineTo(cornerLength, 0);
    canvas.drawPath(tlPath, paint);

    // Top-right corner
    final trPath =
        Path()
          ..moveTo(size.width - cornerLength, 0)
          ..lineTo(size.width - radius, 0)
          ..quadraticBezierTo(size.width, 0, size.width, radius)
          ..lineTo(size.width, cornerLength);
    canvas.drawPath(trPath, paint);

    // Bottom-left corner
    final blPath =
        Path()
          ..moveTo(0, size.height - cornerLength)
          ..lineTo(0, size.height - radius)
          ..quadraticBezierTo(0, size.height, radius, size.height)
          ..lineTo(cornerLength, size.height);
    canvas.drawPath(blPath, paint);

    // Bottom-right corner
    final brPath =
        Path()
          ..moveTo(size.width - cornerLength, size.height)
          ..lineTo(size.width - radius, size.height)
          ..quadraticBezierTo(
            size.width,
            size.height,
            size.width,
            size.height - radius,
          )
          ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(brPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
