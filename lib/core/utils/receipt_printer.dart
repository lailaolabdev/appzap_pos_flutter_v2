import '../models/cart.dart';
import '../services/printer_service.dart';

/// Receipt printer utility
/// Can be used across different payment dialogs
class ReceiptPrinter {
  final PrinterService _printerService;
  final String? receiptHeader;
  final String? receiptFooter;

  ReceiptPrinter({
    required PrinterService printerService,
    this.receiptHeader,
    this.receiptFooter,
  }) : _printerService = printerService;

  /// Print receipt for a cart
  Future<bool> printCartReceipt({
    required Cart cart,
    required double totalAmount,
    String? orderId,
    String? tableNumber,
    String? serverName,
  }) async {
    try {
      // Check if printer is connected
      if (!_printerService.isConnected) {
        throw Exception('Printer not connected');
      }

      // Generate order ID if not provided
      final now = DateTime.now();
      final receiptOrderId =
          orderId ?? now.millisecondsSinceEpoch.toString().substring(3);

      // Prepare items list
      final items =
          cart.items.map((item) {
            return {
              'name': item.productName,
              'quantity': item.quantity,
              'price': item.unitPrice,
            };
          }).toList();

      // Print receipt
      final success = await _printerService.printReceipt(
        header:
            receiptHeader?.isNotEmpty == true
                ? receiptHeader!
                : 'APPZAP V2 PROD',
        orderId: receiptOrderId,
        tableNumber: tableNumber,
        serverName: serverName,
        items: items,
        total: totalAmount,
        footer:
            receiptFooter?.isNotEmpty == true
                ? receiptFooter!
                : 'Thank you for your visit!',
      );

      return success;
    } catch (e) {
      print('❌ Receipt print error: $e');
      rethrow;
    }
  }

  /// Check if printer is connected
  bool get isConnected => _printerService.isConnected;
}
