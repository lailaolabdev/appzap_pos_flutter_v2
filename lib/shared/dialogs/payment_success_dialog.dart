import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/models/cart.dart';
import '../../core/services/print_service.dart';
import '../../core/utils/currency_formatter.dart';

/// Payment success dialog with print option
class PaymentSuccessDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String paymentMethod;
  final double totalAmount;
  final Cart cart;
  final double? tenderedAmount;
  final double? changeAmount;

  const PaymentSuccessDialog({
    super.key,
    required this.orderId,
    required this.paymentMethod,
    required this.totalAmount,
    required this.cart,
    this.tenderedAmount,
    this.changeAmount,
  });

  @override
  ConsumerState<PaymentSuccessDialog> createState() =>
      _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends ConsumerState<PaymentSuccessDialog> {
  bool _isPrinting = false;

  Future<void> _printReceipt() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final printService = ref.read(printServiceProvider);

      final success = await printService.printReceiptFromCart(
        cart: widget.cart,
        orderId: widget.orderId,
        paymentMethod: widget.paymentMethod,
        tenderedAmount: widget.tenderedAmount ?? widget.totalAmount,
        changeAmount: widget.changeAmount ?? 0,
        restaurantName: 'AppZap Restaurant', // TODO: Get from settings
        branchName: 'Main Branch', // TODO: Get from auth provider
        address: 'Vientiane, Laos', // TODO: Get from settings
        phone: '+856 20 12345678', // TODO: Get from settings
        taxId: 'TAX123456', // TODO: Get from settings
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt printed successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to print receipt'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 48,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Order ID
            Text(
              'Order #${widget.orderId}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
            ),

            const SizedBox(height: 24),

            // Payment details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.neutral50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Payment Method',
                    widget.paymentMethod.toUpperCase(),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Total Amount',
                    CurrencyFormatter.format(widget.totalAmount),
                  ),
                  if (widget.tenderedAmount != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Tendered',
                      CurrencyFormatter.format(widget.tenderedAmount!),
                    ),
                  ],
                  if (widget.changeAmount != null && widget.changeAmount! > 0) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Change',
                      CurrencyFormatter.format(widget.changeAmount!),
                      isHighlighted: true,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPrinting ? null : _printReceipt,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print),
                    label: Text(_isPrinting ? 'Printing...' : 'Print Receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isHighlighted ? AppTheme.success : AppTheme.neutral600,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? AppTheme.success : Colors.black,
          ),
        ),
      ],
    );
  }
}

