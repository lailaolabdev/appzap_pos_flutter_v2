import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../../app/theme.dart';

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

/// Barcode scanner dialog
class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  bool _isProcessing = false;

  void _onScan(Code code) {
    if (_isProcessing) return;
    final value = code.text;
    if (value == null || value.isEmpty) return;

    setState(() => _isProcessing = true);
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Scan Barcode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scanner
            Expanded(
              child: ClipRRect(
                child: Stack(
                  children: [
                    ReaderWidget(
                      onScan: _onScan,
                      codeFormat: _posBarcodeFormats,
                      tryHarder: true,
                      tryInverted: true,
                      showFlashlight: true,
                      showToggleCamera: true,
                      showGallery: false,
                      showScannerOverlay: true,
                      scanDelay: const Duration(milliseconds: 500),
                      actionButtonsBackgroundColor: Colors.black54,
                    ),

                    // Overlay with scanning frame
                    Center(
                      child: IgnorePointer(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryOrange,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Instructions
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Position the barcode within the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show barcode scanner and return scanned code
Future<String?> showBarcodeScanner(BuildContext context) async {
  return await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const BarcodeScannerDialog(),
  );
}
