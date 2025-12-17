import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cart.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

final printServiceProvider = Provider<PrintService>((ref) {
  return PrintService();
});

/// Service for printing receipts
class PrintService {
  /// Print receipt from cart (for cash drawer scenarios)
  Future<bool> printReceiptFromCart({
    required Cart cart,
    required String orderId,
    required String paymentMethod,
    required double tenderedAmount,
    required double changeAmount,
    String? restaurantName,
    String? branchName,
    String? address,
    String? phone,
    String? taxId,
  }) async {
    try {
      final pdf = await _generateCartReceiptPdf(
        cart: cart,
        orderId: orderId,
        paymentMethod: paymentMethod,
        tenderedAmount: tenderedAmount,
        changeAmount: changeAmount,
        restaurantName: restaurantName ?? 'AppZap POS',
        branchName: branchName,
        address: address,
        phone: phone,
        taxId: taxId,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate receipt PDF from Cart (for quick printing)
  Future<pw.Document> _generateCartReceiptPdf({
    required Cart cart,
    required String orderId,
    required String paymentMethod,
    required double tenderedAmount,
    required double changeAmount,
    required String restaurantName,
    String? branchName,
    String? address,
    String? phone,
    String? taxId,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      restaurantName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (branchName != null)
                      pw.Text(
                        branchName,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    if (address != null)
                      pw.Text(
                        address,
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    if (phone != null)
                      pw.Text(
                        'Tel: $phone',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (taxId != null)
                      pw.Text(
                        'Tax ID: $taxId',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Order details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order #:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    orderId,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    DateFormatter.formatDateTime(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Items
              pw.Text(
                'ITEMS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              // Item list
              ...cart.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              item.productName,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            CurrencyFormatter.format(item.subtotal),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '  ${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    CurrencyFormatter.format(cart.subtotal),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              if (cart.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      '-${CurrencyFormatter.format(cart.discountAmount)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              if (cart.totalTax > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      CurrencyFormatter.format(cart.totalTax),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(cart.total),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Payment details
              pw.Text(
                'PAYMENT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Method:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    paymentMethod.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              if (paymentMethod.toLowerCase() == 'cash')
                pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Tendered:', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          CurrencyFormatter.format(tenderedAmount),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Change:', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          CurrencyFormatter.format(changeAmount),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your business!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Please come again',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'Powered by AppZap POS',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
