import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';

/// Cash payment dialog
class CashPaymentDialog extends ConsumerStatefulWidget {
  final double totalAmount;
  final VoidCallback onPaymentComplete;

  const CashPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onPaymentComplete,
  });

  @override
  ConsumerState<CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends ConsumerState<CashPaymentDialog> {
  final _tenderedController = TextEditingController();
  double _tenderedAmount = 0;

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
  bool get _canComplete => _tenderedAmount >= widget.totalAmount;

  @override
  Widget build(BuildContext context) {
    final total = widget.totalAmount;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.neutral800),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cash Payment',
          style: TextStyle(color: AppTheme.neutral900, fontWeight: FontWeight.bold),
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
                    // Amount input - Premium design with TextField (TOP)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _canComplete 
                              ? AppTheme.success.withValues(alpha: 0.4)
                              : AppTheme.primaryOrange.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _canComplete 
                                ? AppTheme.success.withValues(alpha: 0.15)
                                : AppTheme.primaryOrange.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Customer Pays',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.neutral600,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
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
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _canComplete ? AppTheme.success : AppTheme.primaryOrange,
                                    letterSpacing: -2,
                                    fontSize: 56,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _tenderedAmount = double.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              Text(
                                ' ₭',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.neutral400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount to Pay - Small text below input
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount to Pay',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutral700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatLAKWithSymbol(total),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick amount buttons - Premium design
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
                    const SizedBox(height: 24),

                    // Change display - Premium design
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _canComplete
                              ? [
                                  AppTheme.success.withValues(alpha: 0.2),
                                  AppTheme.success.withValues(alpha: 0.08),
                                ]
                              : [
                                  AppTheme.error.withValues(alpha: 0.2),
                                  AppTheme.error.withValues(alpha: 0.08),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _canComplete 
                              ? AppTheme.success.withValues(alpha: 0.4)
                              : AppTheme.error.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _canComplete ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: _canComplete ? AppTheme.success : AppTheme.error,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Change to Return',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.neutral800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _canComplete
                                ? CurrencyFormatter.formatLAKWithSymbol(_change)
                                : 'Insufficient Amount',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _canComplete ? AppTheme.success : AppTheme.error,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action buttons - Premium design
            Container(
              padding: const EdgeInsets.all(20),
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
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: AppTheme.neutral300, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                      onPressed: _canComplete
                          ? () {
                              widget.onPaymentComplete();
                              Navigator.pop(
                                context,
                                {
                                  'tendered': _tenderedAmount,
                                  'change': _change,
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: AppTheme.success,
                        disabledBackgroundColor: AppTheme.neutral300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 20),
                          const SizedBox(width: 8),
                          const Text(
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
              Icon(
                icon,
                color: AppTheme.primaryOrange,
                size: 24,
              ),
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


