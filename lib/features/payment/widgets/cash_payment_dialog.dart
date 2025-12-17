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
      _tenderedController.text = CurrencyFormatter.formatLAK(amount);
    });
  }

  void _addAmount(double amount) {
    setState(() {
      _tenderedAmount += amount;
      _tenderedController.text = CurrencyFormatter.formatLAK(_tenderedAmount);
    });
  }

  double get _change => _tenderedAmount - widget.totalAmount;
  bool get _canComplete => _tenderedAmount >= widget.totalAmount;

  @override
  Widget build(BuildContext context) {
    // Calculate quick amounts
    final total = widget.totalAmount;
    final quickAmounts = _calculateQuickAmounts(total);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrangeBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Payment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.formatLAKWithSymbol(total)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount received input
            TextField(
              controller: _tenderedController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Amount Received',
                hintText: '0',
                suffixText: '₭',
                filled: true,
                fillColor: AppTheme.neutral50,
              ),
              onChanged: (value) {
                setState(() {
                  _tenderedAmount = double.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),

            // Quick amount buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  quickAmounts.map((amount) {
                    return _QuickAmountButton(
                      amount: amount,
                      onTap: () => _setQuickAmount(amount),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // Denomination buttons
            Text(
              'Add denomination',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  CurrencyFormatter.lakDenominations.map((denom) {
                    return _DenominationButton(
                      denomination: denom,
                      onTap: () => _addAmount(denom.toDouble()),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),

            // Change display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _canComplete ? AppTheme.successLight : AppTheme.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change to return',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    _canComplete
                        ? CurrencyFormatter.formatLAKWithSymbol(_change)
                        : 'Insufficient',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _canComplete ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _canComplete
                            ? () {
                              if (widget.onPaymentComplete != null) {
                                widget.onPaymentComplete!();
                              }
                              Navigator.pop(
                                context,
                                {
                                  'tendered': _tenderedAmount,
                                  'change': _change,
                                },
                              );
                            }
                            : null,
                    child: const Text('Complete Payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<double> _calculateQuickAmounts(double total) {
    final amounts = <double>[];
    final roundedUp = ((total / 1000).ceil() * 1000).toDouble();
    amounts.add(roundedUp);

    // Add common amounts above total
    for (final denom in [10000, 20000, 50000, 100000]) {
      if (denom >= total && !amounts.contains(denom.toDouble())) {
        amounts.add(denom.toDouble());
      }
    }

    amounts.sort();
    return amounts.take(4).toList();
  }
}

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final VoidCallback onTap;

  const _QuickAmountButton({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryOrangeBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            CurrencyFormatter.formatLAKWithSymbol(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
      ),
    );
  }
}

class _DenominationButton extends StatelessWidget {
  final int denomination;
  final VoidCallback onTap;

  const _DenominationButton({required this.denomination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.neutral100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '+${CurrencyFormatter.formatDenomination(denomination)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
