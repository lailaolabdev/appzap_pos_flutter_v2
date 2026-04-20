import '../models/cart.dart';
import '../services/printer_service.dart';

/// Receipt printer utility
/// Can be used across different payment dialogs
class ReceiptPrinter {
  final PrinterService _printerService;
  final String? receiptHeader;
  final String? receiptFooter;
  final String? shopName;
  final String? logoUrl;
  final String paperWidth;

  ReceiptPrinter({
    required PrinterService printerService,
    this.receiptHeader,
    this.receiptFooter,
    this.shopName,
    this.logoUrl,
    this.paperWidth = '80 mm',
  }) : _printerService = printerService;

  /// Print receipt for a cart
  Future<bool> printCartReceipt({
    required Cart cart,
    required double totalAmount,
    String? orderId,
    String? tableNumber,
    String? serverName,
    String? orderType,
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

      // Print receipt — use receiptHeader > shopName > default
      final header =
          (receiptHeader?.isNotEmpty == true)
              ? receiptHeader!
              : (shopName?.isNotEmpty == true)
              ? shopName!
              : 'APPZAP POS';

      final success = await _printerService.printReceipt(
        header: header,
        orderId: receiptOrderId,
        tableNumber: tableNumber,
        serverName: serverName,
        items: items,
        total: totalAmount,
        footer:
            receiptFooter?.isNotEmpty == true
                ? receiptFooter!
                : 'Thank you for your visit!',
        orderType: orderType ?? 'Takeaway',
        paperWidth: paperWidth,
        logoUrl: logoUrl,
      );

      return success;
    } catch (e) {
      print('❌ Receipt print error: $e');
      rethrow;
    }
  }

  /// Print order ticket (kitchen ticket — no prices, just items + qty)
  Future<bool> printOrderTicket({
    required Cart cart,
    String? orderId,
    String? tableNumber,
    String? serverName,
  }) async {
    try {
      if (!_printerService.isConnected) {
        throw Exception('Printer not connected');
      }

      final now = DateTime.now();
      final receiptOrderId =
          orderId ?? now.millisecondsSinceEpoch.toString().substring(3);

      // Order ticket items — no price, just name + quantity
      final items =
          cart.items.map((item) {
            return {
              'name': item.productName,
              'quantity': item.quantity,
              'price': 0.0,
            };
          }).toList();

      final success = await _printerService.printReceipt(
        header: 'ORDER TICKET',
        orderId: receiptOrderId,
        tableNumber: tableNumber,
        serverName: serverName,
        items: items,
        total: 0,
        footer: '',
        paperWidth: paperWidth,
      );

      return success;
    } catch (e) {
      print('❌ Order ticket print error: $e');
      return false;
    }
  }

  /// Check if printer is connected
  bool get isConnected => _printerService.isConnected;
}
