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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PhayPay'),
            Text(
              CurrencyFormatter.formatLAKWithSymbol(amount),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Bank',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: PhayPayBankMethod.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bank = PhayPayBankMethod.values[index];
                  return _BankOption(
                    bank: bank,
                    onTap: () {
                      Navigator.pop(context);
                      onBankSelected(bank);
                    },
                  );
                },
              ),
            ),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(paymentProvider.notifier).cancelPayment();
            Navigator.pop(context, false);
          },
        ),
        title: const Text('Scan to Pay'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bank info
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.neutral50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance,
                    size: 20,
                    color: AppTheme.neutral600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    phayPayPayment.bankMethod.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // QR Code or Status
                    if (paymentState.isCompleted)
                      _buildSuccessState(context)
                    else if (paymentState.isFailed)
                      _buildFailedState(
                        context,
                        paymentState.error ?? 'Payment failed',
                      )
                    else
                      _buildQRState(context, phayPayPayment, paymentState),

                    const SizedBox(height: 32),

                    // Amount
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrangeBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Amount',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.neutral600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.formatLAKWithSymbol(
                              phayPayPayment.amount,
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            if (paymentState.isCompleted || paymentState.isFailed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child:
                    paymentState.isCompleted
                        ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.success,
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(paymentProvider.notifier).reset();
                                  Navigator.pop(context, false);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('Try Again'),
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

  Widget _buildQRState(
    BuildContext context,
    PhayPayPayment payment,
    PaymentState state,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = (screenWidth * 0.6).clamp(180.0, 250.0);

    return Column(
      children: [
        // QR Code
        Container(
          width: qrSize,
          height: qrSize,
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
                      size: qrSize * 0.72,
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
    final size = MediaQuery.of(context).size.width < 360 ? 90.0 : 120.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppTheme.successLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: size * 0.67,
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
    final size = MediaQuery.of(context).size.width < 360 ? 90.0 : 120.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppTheme.errorLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            size: size * 0.67,
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
