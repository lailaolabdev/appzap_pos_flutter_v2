import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme.dart';

/// Barcode scanner dialog
class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        setState(() => _isProcessing = true);
        Navigator.pop(context, code);
      }
    }
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
                    MobileScanner(controller: controller, onDetect: _onDetect),

                    // Overlay with scanning frame
                    Center(
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

                    // Instructions
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
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
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Toggle flash
                  IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, MobileScannerState state, child) {
                        return Icon(
                          state.torchState == TorchState.off
                              ? Icons.flash_off
                              : Icons.flash_on,
                          color: Colors.white,
                          size: 28,
                        );
                      },
                    ),
                    onPressed: () => controller.toggleTorch(),
                  ),

                  const SizedBox(width: 32),

                  // Switch camera
                  IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, MobileScannerState state, child) {
                        return const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                          size: 28,
                        );
                      },
                    ),
                    onPressed: () => controller.switchCamera(),
                  ),
                ],
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
