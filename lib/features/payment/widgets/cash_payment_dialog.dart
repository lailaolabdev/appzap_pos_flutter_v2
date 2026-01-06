import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/cart.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/payment_provider.dart';

/// Cash payment dialog
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

  @override
  void dispose() {
    _tenderedController.dispose();
    super.dispose();
  }

  void _setQuickAmount(double amount) {
    print('🔘 Quick amount button clicked: $amount');
    setState(() {
      _tenderedAmount = amount;
      _tenderedController.text = amount.toInt().toString();
    });
    print(
      '✅ Updated _tenderedAmount=$_tenderedAmount, canComplete=$_canComplete',
    );
  }

  double get _change => _tenderedAmount - widget.totalAmount;
  bool get _canComplete {
    // Try to get amount from state first, fallback to controller text
    double amount = _tenderedAmount;
    if (amount == 0 && _tenderedController.text.isNotEmpty) {
      amount = double.tryParse(_tenderedController.text) ?? 0;
      print(
        '⚠️ Using controller text as fallback: ${_tenderedController.text} → $amount',
      );
    }
    final canComplete = amount >= widget.totalAmount;
    print(
      '🔍 _canComplete check: amount=$amount, total=${widget.totalAmount}, result=$canComplete',
    );
    return canComplete;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalAmount;

    // ✅ Watch payment provider to keep it alive during async operations
    ref.watch(paymentProvider);

    // Debug logging
    print(
      '💳 CashPaymentDialog build: _tenderedAmount=$_tenderedAmount, total=$total, canComplete=$_canComplete',
    );

    return PopScope(
      canPop: !_isProcessing, // Prevent back button during processing
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.neutral800),
            onPressed:
                _isProcessing
                    ? null // Disable close button during processing
                    : () {
                      print('❌ User clicked X button - cancelling payment');
                      Navigator.pop(context); // Returns null
                    },
          ),
          title: const Text(
            'Cash Payment',
            style: TextStyle(
              color: AppTheme.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Amount input - Simple, full-width single outline box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _canComplete
                                    ? AppTheme.success
                                    : AppTheme.primaryOrange,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tenderedController,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: Theme.of(
                                  context,
                                ).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _canComplete
                                          ? AppTheme.success
                                          : AppTheme.primaryOrange,
                                  letterSpacing: -2,
                                  fontSize: 48,
                                ),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  final parsed = double.tryParse(value) ?? 0;
                                  print(
                                    '💰 TextField onChanged: value="$value", parsed=$parsed',
                                  );
                                  setState(() {
                                    _tenderedAmount = parsed;
                                  });
                                  print(
                                    '✅ Updated _tenderedAmount=$_tenderedAmount, canComplete=$_canComplete',
                                  );
                                },
                              ),
                            ),
                            Text(
                              ' ₭',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.neutral400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Amount to Pay - Compact row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryOrange.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount to Pay',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.neutral700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatLAKWithSymbol(total),
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Change to Return - Compact row (similar to Amount to Pay but different)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _canComplete
                                  ? AppTheme.success.withValues(alpha: 0.08)
                                  : AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _canComplete
                                    ? AppTheme.success.withValues(alpha: 0.3)
                                    : AppTheme.error.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _canComplete
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  color:
                                      _canComplete
                                          ? AppTheme.success
                                          : AppTheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Change',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.neutral700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _canComplete
                                  ? CurrencyFormatter.formatLAKWithSymbol(
                                    _change,
                                  )
                                  : 'Insufficient',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    _canComplete
                                        ? AppTheme.success
                                        : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
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
                        const SizedBox(height: 16),
                      ],

                      // Quick amount buttons - Always visible above keyboard
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAmountButton(
                              amount: total,
                              label: 'Exact',
                              icon: Icons.check_circle_outline,
                              onTap: () => _setQuickAmount(total),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAmountButton(
                              amount: 50000,
                              label: '50K',
                              icon: Icons.payments_outlined,
                              onTap: () => _setQuickAmount(50000),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAmountButton(
                              amount: 100000,
                              label: '100K',
                              icon: Icons.account_balance_wallet_outlined,
                              onTap: () => _setQuickAmount(100000),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons - Fixed at bottom, above keyboard
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isProcessing
                                ? null // Disable during processing
                                : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: AppTheme.neutral300,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            (_canComplete && !_isProcessing)
                                ? () async {
                                  print('✅ Complete Payment button clicked!');
                                  print('   _tenderedAmount=$_tenderedAmount');
                                  print(
                                    '   _tenderedController.text=${_tenderedController.text}',
                                  );

                                  // Use fallback logic for tendered amount
                                  double finalAmount = _tenderedAmount;
                                  if (finalAmount == 0 &&
                                      _tenderedController.text.isNotEmpty) {
                                    finalAmount =
                                        double.tryParse(
                                          _tenderedController.text,
                                        ) ??
                                        0;
                                    print(
                                      '⚠️ Using controller text as fallback: $finalAmount',
                                    );
                                  }

                                  // ✅ Capture notifier BEFORE async operation (keeps it alive!)
                                  final paymentNotifier = ref.read(
                                    paymentProvider.notifier,
                                  );

                                  // ✅ Start processing (show loading inside dialog)
                                  setState(() {
                                    _isProcessing = true;
                                    _errorMessage = null;
                                  });

                                  try {
                                    // ✅ Process payment using captured notifier (stays alive!)
                                    print(
                                      '🔄 CashPaymentDialog: Processing payment: $finalAmount',
                                    );
                                    print('   Total: ${widget.totalAmount}');
                                    print('   Tendered: $finalAmount');
                                    print(
                                      '   Cart items: ${widget.cart.items.length}',
                                    );

                                    final success = await paymentNotifier
                                        .processCashPayment(
                                          total: widget.totalAmount,
                                          tendered: finalAmount,
                                          cart: widget.cart,
                                        );

                                    print(
                                      '📊 CashPaymentDialog: Payment result = $success',
                                    );
                                    print('   mounted = $mounted');

                                    if (success && mounted) {
                                      // ✅ Success! Close dialog and return to main screen
                                      print(
                                        '✅ CashPaymentDialog: Payment successful, closing dialog...',
                                      );
                                      Navigator.pop(context, {
                                        'success': true,
                                        'tendered': finalAmount,
                                        'change':
                                            finalAmount - widget.totalAmount,
                                      });
                                    } else if (mounted) {
                                      // ❌ Failed, show error in dialog
                                      print(
                                        '❌ CashPaymentDialog: Payment failed (success=$success, mounted=$mounted)',
                                      );
                                      setState(() {
                                        _isProcessing = false;
                                        _errorMessage =
                                            'Payment failed. Please try again.';
                                      });
                                    } else {
                                      print(
                                        '⚠️  CashPaymentDialog: Widget not mounted, cannot update UI',
                                      );
                                    }
                                  } catch (e, stackTrace) {
                                    // ❌ Exception, show error in dialog
                                    print(
                                      '❌ CashPaymentDialog: Payment exception: $e',
                                    );
                                    print('📍 Stack trace: $stackTrace');
                                    if (mounted) {
                                      setState(() {
                                        _isProcessing = false;
                                        _errorMessage = e.toString();
                                      });
                                    } else {
                                      print(
                                        '⚠️  CashPaymentDialog: Widget not mounted, cannot show error',
                                      );
                                    }
                                  }
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.success,
                          disabledBackgroundColor: AppTheme.neutral300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isProcessing
                                ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Processing...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Complete Payment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryOrange.withValues(alpha: 0.3),
              width: 2,
            ),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryOrange.withValues(alpha: 0.08),
                AppTheme.primaryOrange.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.primaryOrange, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
