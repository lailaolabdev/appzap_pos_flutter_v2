import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/cart.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_printer.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/payment_provider.dart';

class CashPaymentDialog extends ConsumerStatefulWidget {
  final double totalAmount;
  final Cart cart;

  const CashPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.cart,
  });

  @override
  ConsumerState<CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends ConsumerState<CashPaymentDialog> {
  final _tenderedController = TextEditingController();
  double _tenderedAmount = 0;
  bool _isProcessing = false;
  String? _errorMessage;
  String _selectedMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _tenderedAmount = widget.totalAmount;
    _tenderedController.text = widget.totalAmount.toInt().toString();
  }

  @override
  void dispose() {
    _tenderedController.dispose();
    super.dispose();
  }

  double get _change => _tenderedAmount - widget.totalAmount;

  bool get _canComplete {
    if (_selectedMethod != 'cash') return true;
    double amount = _tenderedAmount;
    if (amount == 0 && _tenderedController.text.isNotEmpty) {
      amount = double.tryParse(_tenderedController.text) ?? 0;
    }
    return amount >= widget.totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalAmount;
    final lang = ref.watch(localizationProvider).languageCode;
    ref.watch(paymentProvider);

    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
          ),
          title: Text(
            Translations.get('checkout', lang),
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Payment Method Options
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPaymentOption(
                              icon: Icons.attach_money,
                              label: Translations.get('cash', lang),
                              value: 'cash',
                              iconColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPaymentOption(
                              icon: Icons.wallet,
                              label: Translations.get('transfer', lang),
                              value: 'transfer',
                              iconColor: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPaymentOption(
                              icon: Icons.qr_code_scanner,
                              label: 'Bank QR',
                              value: 'bankQR',
                              iconColor: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPaymentOption(
                              icon: Icons.card_giftcard,
                              label: 'Points',
                              value: 'points',
                              iconColor: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount input (shows total by default, user can change)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _tenderedController,
                          autofocus: false,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                _canComplete
                                    ? AppTheme.primaryOrange
                                    : Colors.black,
                          ),
                          decoration: _amountInputDecoration(total),
                          onChanged:
                              (v) => setState(
                                () => _tenderedAmount = double.tryParse(v) ?? 0,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${Translations.get('change', lang)} :',
                                  style: const TextStyle(
                                    color: AppTheme.neutral700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.formatLAKWithSymbol(_change),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _canComplete
                                        ? AppTheme.success
                                        : AppTheme.error,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isProcessing ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          Translations.get('cancel', lang),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pay + Print
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            (_canComplete && !_isProcessing)
                                ? _processPayment
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          disabledBackgroundColor: AppTheme.neutral300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isProcessing
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  Translations.get('pay', lang),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.3,
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

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap:
          _isProcessing ? null : () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFFFF6B00).withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xFFFF6B00) : iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    double finalAmount = _tenderedAmount;
    if (_selectedMethod == 'cash') {
      if (finalAmount == 0 && _tenderedController.text.isNotEmpty) {
        finalAmount = double.tryParse(_tenderedController.text) ?? 0;
      }
    } else {
      finalAmount = widget.totalAmount;
    }

    final paymentNotifier = ref.read(paymentProvider.notifier);
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Run print and payment at the same time — don't wait for print to finish
      final printFuture = _printReceipt().catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.warning,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });

      final paymentFuture = paymentNotifier.processCashPayment(
        total: widget.totalAmount,
        tendered: finalAmount,
        cart: widget.cart,
      );

      // Wait for both — payment result matters, print doesn't block
      final results = await Future.wait([printFuture, paymentFuture]);
      final success = results[1] as bool;

      if (success && mounted) {
        Navigator.pop(context, {
          'success': true,
          'tendered': finalAmount,
          'change': finalAmount - widget.totalAmount,
          'method': _selectedMethod,
        });
      } else if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  InputDecoration _amountInputDecoration(double total) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primaryOrange),
    );
    return InputDecoration(
      hintText: CurrencyFormatter.formatLAKWithSymbol(total),
      hintStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
      ),
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 8),
        child: Text(
          '₭',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryOrange,
          ),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _printReceipt() async {
    final printerService = ref.read(settingsProvider.notifier).printerService;
    final settings = ref.read(settingsProvider);

    // Check if printing is enabled
    if (!settings.enableReceiptPrinting) return;

    // Check if printer is configured
    if (settings.printerName.isEmpty) {
      throw Exception('No printer configured');
    }

    // Try to connect if not connected
    if (!printerService.isConnected) {
      final isSunmi = await printerService.isSunmiDevice();
      if (isSunmi) {
        final connected = await printerService.ensureSunmiConnected();
        if (!connected) {
          await printerService.ensureSunmiConnected(force: true);
        }
      }
      // If still not connected after trying, fail
      if (!printerService.isConnected) {
        throw Exception('Printer not connected');
      }
    }

    final receiptPrinter = ReceiptPrinter(
      printerService: printerService,
      receiptHeader: settings.receiptHeader,
      receiptFooter: settings.receiptFooter,
    );

    final success = await receiptPrinter.printCartReceipt(
      cart: widget.cart,
      totalAmount: widget.totalAmount,
    );
    if (!success) throw Exception('Failed to print receipt');
  }
}
