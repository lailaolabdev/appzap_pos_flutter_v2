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

/// Payment method tabs
enum PaymentMethod { cash, transfer, bankQR, points }

/// Redesigned payment dialog with tabbed payment methods
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
  PaymentMethod _selectedMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _tenderedController.dispose();
    super.dispose();
  }

  void _setQuickAmount(double amount) {
    setState(() {
      _tenderedAmount = amount;
      _tenderedController.text = amount.toInt().toString();
    });
  }

  double get _change => _tenderedAmount - widget.totalAmount;
  bool get _canComplete {
    if (_selectedMethod != PaymentMethod.cash) return true;
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            Translations.get('payment_method', lang),
            style: const TextStyle(
              color: AppTheme.neutral900,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.neutral600),
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ─── Payment Method Tabs ───
              _buildPaymentTabs(lang),

              const Divider(height: 1, color: AppTheme.neutral200),

              // ─── Content Area ───
              Expanded(
                child:
                    _selectedMethod == PaymentMethod.cash
                        ? _buildCashContent(total, lang)
                        : _buildOtherMethodContent(total, lang),
              ),

              // ─── Error Message ───
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Bottom Action Buttons ───
              _buildBottomBar(lang),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Payment Method Tabs
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPaymentTabs(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildTab(
            method: PaymentMethod.cash,
            icon: Icons.attach_money,
            label: Translations.get('cash', lang),
          ),
          const SizedBox(width: 8),
          _buildTab(
            method: PaymentMethod.transfer,
            icon: Icons.account_balance_outlined,
            label: Translations.get('transfer', lang),
          ),
          const SizedBox(width: 8),
          _buildTab(
            method: PaymentMethod.bankQR,
            icon: Icons.qr_code_scanner,
            label: 'Bank QR',
          ),
          const SizedBox(width: 8),
          _buildTab(
            method: PaymentMethod.points,
            icon: Icons.card_giftcard,
            label: 'Points',
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap:
            _isProcessing
                ? null
                : () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryOrange : AppTheme.neutral200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color:
                    isSelected ? AppTheme.primaryOrange : AppTheme.neutral500,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? AppTheme.primaryOrange : AppTheme.neutral600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Cash Content
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCashContent(double total, String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _canComplete ? AppTheme.success : AppTheme.neutral300,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '₭',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.neutral400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tenderedController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          _canComplete ? AppTheme.success : AppTheme.neutral900,
                      fontSize: 24,
                      height: 1.1,
                    ),
                    decoration: InputDecoration(
                      hintText: CurrencyFormatter.format(total),
                      hintStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.neutral300,
                        height: 1.1,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _tenderedAmount = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount to pay row
          _buildInfoRow(
            label: Translations.get('amount_to_pay', lang),
            value: CurrencyFormatter.formatLAKWithSymbol(total),
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(height: 10),

          // Change row
          _buildInfoRow(
            label: Translations.get('change', lang),
            value:
                _canComplete
                    ? CurrencyFormatter.formatLAKWithSymbol(_change)
                    : Translations.get('insufficient', lang),
            color: _canComplete ? AppTheme.success : AppTheme.error,
            icon:
                _canComplete
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 20),

          // Quick amount buttons
          Row(
            children: [
              _buildQuickButton(
                Translations.get('exact', lang),
                Icons.check_circle_outline,
                () => _setQuickAmount(total),
              ),
              const SizedBox(width: 10),
              _buildQuickButton(
                '50K',
                Icons.payments_outlined,
                () => _setQuickAmount(50000),
              ),
              const SizedBox(width: 10),
              _buildQuickButton(
                '100K',
                Icons.account_balance_wallet_outlined,
                () => _setQuickAmount(100000),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.neutral700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryOrange.withValues(alpha: 0.3),
              width: 1.5,
            ),
            color: AppTheme.primaryOrange.withValues(alpha: 0.04),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryOrange, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Other Payment Methods (Transfer, Bank QR, Points)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildOtherMethodContent(double total, String lang) {
    final methodLabels = {
      PaymentMethod.transfer: Translations.get('transfer_note', lang),
      PaymentMethod.bankQR: Translations.get('bank_qr_note', lang),
      PaymentMethod.points: Translations.get('points_note', lang),
    };

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Total amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neutral200, width: 1.5),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                CurrencyFormatter.formatLAKWithSymbol(total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutral900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info message
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _selectedMethod == PaymentMethod.transfer
                    ? Icons.account_balance_outlined
                    : _selectedMethod == PaymentMethod.bankQR
                    ? Icons.qr_code_scanner
                    : Icons.card_giftcard,
                color: AppTheme.neutral500,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  methodLabels[_selectedMethod] ??
                      Translations.get('checkout_note', lang),
                  style: const TextStyle(
                    color: AppTheme.neutral600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Bottom Action Bar
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBottomBar(String lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.neutral300, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                Translations.get('cancel', lang),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Pay button (no print)
          Expanded(
            child: OutlinedButton(
              onPressed:
                  (_canComplete && !_isProcessing)
                      ? () => _processPayment(printReceipt: false)
                      : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color:
                      (_canComplete && !_isProcessing)
                          ? AppTheme.primaryOrange
                          : AppTheme.neutral300,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                Translations.get('pay', lang),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      (_canComplete && !_isProcessing)
                          ? AppTheme.primaryOrange
                          : AppTheme.neutral400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Pay + Print button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  (_canComplete && !_isProcessing)
                      ? () => _processPayment(printReceipt: true)
                      : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.primaryOrange,
                disabledBackgroundColor: AppTheme.neutral300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                        Translations.get('pay_and_print', lang),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Payment Processing
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _processPayment({required bool printReceipt}) async {
    double finalAmount = _tenderedAmount;
    if (_selectedMethod == PaymentMethod.cash) {
      if (finalAmount == 0 && _tenderedController.text.isNotEmpty) {
        finalAmount = double.tryParse(_tenderedController.text) ?? 0;
      }
    } else {
      finalAmount = widget.totalAmount; // exact amount for non-cash
    }

    final paymentNotifier = ref.read(paymentProvider.notifier);

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (printReceipt) {
        try {
          await _printReceipt();
        } catch (printError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Translations.get(
                    'print_failed_but_payment_will_continue',
                    ref.read(localizationProvider).languageCode,
                  ),
                ),
                backgroundColor: AppTheme.warning,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }

      final success = await paymentNotifier.processCashPayment(
        total: widget.totalAmount,
        tendered: finalAmount,
        cart: widget.cart,
      );

      if (success && mounted) {
        Navigator.pop(context, {
          'success': true,
          'tendered': finalAmount,
          'change': finalAmount - widget.totalAmount,
          'method': _selectedMethod.name,
        });
      } else if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Payment failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _printReceipt() async {
    final printerService = ref.read(settingsProvider.notifier).printerService;
    final settings = ref.read(settingsProvider);

    final isSunmi = await printerService.isSunmiDevice();
    if (isSunmi) {
      final connected = await printerService.ensureSunmiConnected();
      if (!connected) {
        await printerService.ensureSunmiConnected(force: true);
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
