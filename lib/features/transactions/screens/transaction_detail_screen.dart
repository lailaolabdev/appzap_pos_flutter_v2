import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).loadTransaction(widget.transactionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final transaction = transactionState.selectedTransaction;
    final isLoading = transactionState.isLoading;
    final error = transactionState.error;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.transactionId),
        actions: [
          if (transaction != null && transaction.isCompleted)
            IconButton(
              icon: const Icon(Icons.receipt),
              tooltip: 'View Receipt',
              onPressed: () => _viewReceipt(transaction),
            ),
        ],
      ),
      body: isLoading && transaction == null
          ? const Center(child: CircularProgressIndicator())
          : error != null && transaction == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text(error),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(transactionProvider.notifier)
                              .loadTransaction(widget.transactionId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : transaction == null
                  ? const Center(child: Text('Transaction not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          _buildHeaderCard(transaction),
                          const SizedBox(height: 16),

                          // Amount Summary Card
                          _buildAmountSummaryCard(transaction),
                          const SizedBox(height: 16),

                          // Payment Info Card
                          if (transaction.payments.isNotEmpty)
                            _buildPaymentInfoCard(transaction),
                          if (transaction.payments.isNotEmpty)
                            const SizedBox(height: 16),

                          // Line Items
                          _buildLineItemsCard(transaction),
                          const SizedBox(height: 16),

                          // Additional Info
                          _buildAdditionalInfoCard(transaction),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeaderCard(Transaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction ID',
                        style: TextStyle(
                          color: AppTheme.neutral600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.transactionId,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(transaction.transactionStatus),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppTheme.neutral600),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(
                    transaction.timing.initiatedAt ?? transaction.createdAt,
                  ),
                  style: const TextStyle(color: AppTheme.neutral600),
                ),
              ],
            ),
            if (transaction.timing.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                  const SizedBox(width: 8),
                  Text(
                    'Completed: ${DateFormat('h:mm a').format(transaction.timing.completedAt!)}',
                    style: const TextStyle(color: AppTheme.neutral600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSummaryCard(Transaction transaction) {
    final totals = transaction.consolidatedTotals;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAmountRow('Subtotal', totals.subtotal.amount),
            const SizedBox(height: 8),
            _buildAmountRow('Tax', totals.tax.amount),
            if (totals.discounts.amount > 0) ...[
              const SizedBox(height: 8),
              _buildAmountRow(
                'Discounts',
                -totals.discounts.amount,
                color: AppTheme.error,
              ),
            ],
            if (totals.serviceCharge.amount > 0) ...[
              const SizedBox(height: 8),
              _buildAmountRow('Service Charge', totals.serviceCharge.amount),
            ],
            const Divider(height: 24),
            _buildAmountRow(
              'Grand Total',
              totals.grandTotal.amount,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(Transaction transaction) {
    final payment = transaction.payments.first;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getPaymentIcon(payment.method),
                  color: _getPaymentColor(payment.method),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPaymentMethodLabel(payment.method),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatLAKWithSymbol(
                          payment.grossAmount.amount,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (payment.changeAmount != null && payment.changeAmount!.amount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Change Given',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatLAKWithSymbol(
                        payment.changeAmount!.amount,
                      ),
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemsCard(Transaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${transaction.lineItems.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...transaction.lineItems.map((item) => _buildLineItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(TransactionLineItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatLAKWithSymbol(item.unitPrice),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatLAKWithSymbol(item.total),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(Transaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (transaction.customer != null) ...[
              _buildInfoRow(
                'Customer',
                transaction.customer!.name ?? 'Unknown',
                icon: Icons.person,
              ),
              if (transaction.customer!.phone != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Phone',
                  transaction.customer!.phone!,
                  icon: Icons.phone,
                ),
              ],
              const SizedBox(height: 8),
            ],
            if (transaction.staff?.processedBy != null) ...[
              _buildInfoRow(
                'Processed By',
                transaction.staff!.processedBy!.name,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 8),
            ],
            if (transaction.tableInfo != null) ...[
              _buildInfoRow(
                'Table',
                'Table ${transaction.tableInfo!.tableNumber} - ${transaction.tableInfo!.zoneName}',
                icon: Icons.table_restaurant,
              ),
              const SizedBox(height: 8),
            ],
            if (transaction.receiptId != null)
              _buildInfoRow(
                'Receipt ID',
                transaction.receiptId!,
                icon: Icons.receipt,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    Color? color,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          CurrencyFormatter.formatLAKWithSymbol(amount),
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isTotal ? AppTheme.primaryOrange : null),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppTheme.neutral600),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = AppTheme.success;
        label = 'Completed';
        break;
      case 'pending':
        color = AppTheme.warning;
        label = 'Pending';
        break;
      case 'voided':
        color = AppTheme.error;
        label = 'Voided';
        break;
      case 'refunded':
      case 'partially_refunded':
        color = Colors.purple;
        label = status == 'refunded' ? 'Refunded' : 'Partial Refund';
        break;
      default:
        color = AppTheme.neutral500;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    if (method == 'cash') return Icons.payments;
    if (method.contains('card')) return Icons.credit_card;
    if (method.contains('qr') || method.contains('bank')) return Icons.qr_code_2;
    return Icons.payment;
  }

  Color _getPaymentColor(String method) {
    if (method == 'cash') return AppTheme.success;
    if (method.contains('card')) return Colors.blue;
    if (method.contains('qr') || method.contains('bank')) {
      return AppTheme.primaryOrange;
    }
    return AppTheme.neutral600;
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash Payment';
      case 'card':
        return 'Card Payment';
      case 'bank_qr_jdb':
        return 'JDB QR Code';
      case 'bank_qr_bcel':
        return 'BCEL QR Code';
      case 'bank_qr_ldb':
        return 'LDB QR Code';
      case 'bank_qr_ib':
        return 'Indochina Bank QR Code';
      default:
        return method.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _viewReceipt(Transaction transaction) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt viewing coming soon'),
      ),
    );
  }
}

