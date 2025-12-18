import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';

class TransactionSummaryCards extends StatelessWidget {
  final TransactionSummary summary;

  const TransactionSummaryCards({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final crossAxisCount = isMobile ? 2 : 4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.2 : 1.5,
      children: [
        _buildSummaryCard(
          context,
          title: 'Total Sales',
          value: CurrencyFormatter.formatLAKWithSymbol(summary.salesAmount),
          subtitle: '${summary.salesCount} transactions',
          icon: Icons.attach_money,
          color: AppTheme.success,
        ),
        _buildSummaryCard(
          context,
          title: 'Average Value',
          value: CurrencyFormatter.formatLAKWithSymbol(
            summary.salesCount > 0
                ? summary.salesAmount / summary.salesCount
                : 0,
          ),
          subtitle: 'per transaction',
          icon: Icons.trending_up,
          color: Colors.blue,
        ),
        _buildSummaryCard(
          context,
          title: 'Void Count',
          value: summary.voidCount.toString(),
          subtitle: CurrencyFormatter.formatLAKWithSymbol(summary.voidAmount),
          icon: Icons.cancel,
          color: AppTheme.error,
        ),
        _buildSummaryCard(
          context,
          title: 'Payment Methods',
          value: summary.paymentMethodBreakdown.length.toString(),
          subtitle: summary.paymentMethodBreakdown.isNotEmpty
              ? _getMostUsedMethod(summary.paymentMethodBreakdown)
              : 'No data',
          icon: Icons.payment,
          color: AppTheme.primaryOrange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.neutral500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getMostUsedMethod(List<PaymentMethodBreakdown> methods) {
    if (methods.isEmpty) return 'N/A';

    // Find method with highest count (assuming it's available in the breakdown)
    var mostUsed = methods.first.method;
    var maxAmount = methods.first.amount;

    for (var method in methods) {
      if (method.amount > maxAmount) {
        maxAmount = method.amount;
        mostUsed = method.method;
      }
    }

    return _formatMethodName(mostUsed);
  }

  String _formatMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'bank_qr_jdb':
        return 'JDB QR';
      case 'bank_qr_bcel':
        return 'BCEL QR';
      default:
        return method.replaceAll('_', ' ').toUpperCase();
    }
  }
}

