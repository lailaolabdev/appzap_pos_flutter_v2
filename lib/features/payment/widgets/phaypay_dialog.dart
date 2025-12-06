import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../app/theme.dart';
import '../../../core/models/payment.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/payment_provider.dart';

/// PhayPay bank selection dialog
class PhayPayBankSelectionDialog extends StatelessWidget {
  final double amount;
  final Function(PhayPayBankMethod) onBankSelected;

  const PhayPayBankSelectionDialog({
    super.key,
    required this.amount,
    required this.onBankSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 360,
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
                    Icons.qr_code_2,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PhayPay',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatLAKWithSymbol(amount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w600,
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

            Text('Select Bank', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // Bank options
            ...PhayPayBankMethod.values.map((bank) {
              return _BankOption(
                bank: bank,
                onTap: () {
                  Navigator.pop(context);
                  onBankSelected(bank);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BankOption extends StatelessWidget {
  final PhayPayBankMethod bank;
  final VoidCallback onTap;

  const _BankOption({required this.bank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.neutral200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: AppTheme.neutral600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    bank.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.neutral400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// PhayPay QR Code display dialog
class PhayPayQRDialog extends ConsumerWidget {
  const PhayPayQRDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentProvider);
    final phayPayPayment = paymentState.phayPayPayment;

    if (phayPayPayment == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scan to Pay',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(paymentProvider.notifier).cancelPayment();
                    Navigator.pop(context, false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bank info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                phayPayPayment.bankMethod.displayName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            if (paymentState.isCompleted)
              _buildSuccessState(context)
            else if (paymentState.isFailed)
              _buildFailedState(context, paymentState.error ?? 'Payment failed')
            else
              _buildQRState(context, phayPayPayment, paymentState),

            const SizedBox(height: 24),

            // Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrangeBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Amount: ',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    CurrencyFormatter.formatLAKWithSymbol(
                      phayPayPayment.amount,
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),

            if (paymentState.isCompleted) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Done'),
                ),
              ),
            ],

            if (paymentState.isFailed) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Retry
                        ref.read(paymentProvider.notifier).reset();
                        Navigator.pop(context, false);
                      },
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRState(
    BuildContext context,
    PhayPayPayment payment,
    PaymentState state,
  ) {
    return Column(
      children: [
        // QR Code
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child:
              payment.qrCode.startsWith('data:image')
                  ? Image.memory(
                    base64Decode(payment.qrCode.split(',').last),
                    fit: BoxFit.contain,
                  )
                  : Center(
                    child: Icon(
                      Icons.qr_code_2,
                      size: 180,
                      color: AppTheme.neutral300,
                    ),
                  ),
        ),
        const SizedBox(height: 16),

        // Timer
        if (state.remainingTime != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Expires in ${DateFormatter.formatDuration(state.remainingTime!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),

        // Waiting indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitThreeBounce(color: AppTheme.primaryOrange, size: 20),
            const SizedBox(width: 12),
            Text(
              'Waiting for payment...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppTheme.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 80,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Successful!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState(BuildContext context, String error) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppTheme.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Failed',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
