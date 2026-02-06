import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/models/transaction.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

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
      ref
          .read(transactionProvider.notifier)
          .loadTransaction(widget.transactionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final transaction = transactionState.selectedTransaction;
    final isLoading = transactionState.isLoading;
    final error = transactionState.error;
    final languageCode = ref.watch(localizationProvider).languageCode;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        surfaceTintColor: AppTheme.scaffoldBackground,
        title: Text(widget.transactionId),
        actions: [
          if (transaction != null && transaction.isCompleted)
            IconButton(
              icon: const Icon(Icons.receipt),
              tooltip: Translations.get('view_receipt', languageCode),
              onPressed: () => _viewReceipt(transaction, languageCode),
            ),
        ],
      ),
      body:
          isLoading && transaction == null
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
                      child: Text(Translations.get('retry', languageCode)),
                    ),
                  ],
                ),
              )
              : transaction == null
              ? Center(
                child: Text(
                  Translations.get('transaction_not_found', languageCode),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _buildHeaderCard(transaction, languageCode),
                    const SizedBox(height: 16),

                    // Amount Summary Card
                    _buildAmountSummaryCard(transaction, languageCode),
                    const SizedBox(height: 16),

                    // Payment Info Card
                    if (transaction.payments.isNotEmpty)
                      _buildPaymentInfoCard(transaction, languageCode),
                    if (transaction.payments.isNotEmpty)
                      const SizedBox(height: 16),

                    // Line Items
                    _buildLineItemsCard(transaction, languageCode),
                    const SizedBox(height: 16),

                    // Additional Info
                    _buildAdditionalInfoCard(transaction, languageCode),
                  ],
                ),
              ),
    );
  }

  Widget _buildHeaderCard(Transaction transaction, String languageCode) {
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
                      Text(
                        Translations.get('transaction_id', languageCode),
                        style: TextStyle(
                          color: AppTheme.neutral600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.transactionId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(transaction.transactionStatus, languageCode),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.neutral600,
                ),
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
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${Translations.get('completed', languageCode)}: ${DateFormat('h:mm a').format(transaction.timing.completedAt!)}',
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

  Widget _buildAmountSummaryCard(Transaction transaction, String languageCode) {
    final totals = transaction.consolidatedTotals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.get('amount_summary', languageCode),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAmountRow(
              Translations.get('subtotal', languageCode),
              totals.subtotal.amount,
            ),
            const SizedBox(height: 8),
            _buildAmountRow(
              Translations.get('tax', languageCode),
              totals.tax.amount,
            ),
            if (totals.discounts.amount > 0) ...[
              const SizedBox(height: 8),
              _buildAmountRow(
                Translations.get('discount', languageCode),
                -totals.discounts.amount,
                color: AppTheme.error,
              ),
            ],
            if (totals.serviceCharge.amount > 0) ...[
              const SizedBox(height: 8),
              _buildAmountRow(
                Translations.get('service_charge', languageCode),
                totals.serviceCharge.amount,
              ),
            ],
            const Divider(height: 24),
            _buildAmountRow(
              Translations.get('grand_total', languageCode),
              totals.grandTotal.amount,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(Transaction transaction, String languageCode) {
    final payment = transaction.payments.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.get('payment_information', languageCode),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            if (payment.changeAmount != null &&
                payment.changeAmount!.amount > 0) ...[
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
                    Text(
                      Translations.get('change_given', languageCode),
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

  Widget _buildLineItemsCard(Transaction transaction, String languageCode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${Translations.get('items', languageCode)} (${transaction.lineItems.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(
    Transaction transaction,
    String languageCode,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.get('additional', languageCode),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (transaction.customer != null) ...[
              _buildInfoRow(
                Translations.get('customer', languageCode),
                transaction.customer!.name ?? 'Unknown',
                icon: Icons.person,
              ),
              if (transaction.customer!.phone != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Translations.get('phone', languageCode),
                  transaction.customer!.phone!,
                  icon: Icons.phone,
                ),
              ],
              const SizedBox(height: 8),
            ],
            if (transaction.staff?.processedBy != null) ...[
              _buildInfoRow(
                Translations.get('processed_by', languageCode),
                transaction.staff!.processedBy!.name,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 8),
            ],
            if (transaction.tableInfo != null) ...[
              _buildInfoRow(
                Translations.get('table', languageCode),
                '${Translations.get('table', languageCode)} ${transaction.tableInfo!.tableNumber} - ${transaction.tableInfo!.zoneName}',
                icon: Icons.table_restaurant,
              ),
              const SizedBox(height: 8),
            ],
            if (transaction.receiptId != null)
              _buildInfoRow(
                Translations.get('receipt_id', languageCode),
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
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, String languageCode) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = AppTheme.success;
        label = Translations.get('completed', languageCode);
        break;
      case 'pending':
        color = AppTheme.warning;
        label = Translations.get('pending', languageCode);
        break;
      case 'voided':
        color = AppTheme.error;
        label = Translations.get('voided', languageCode);
        break;
      case 'refunded':
      case 'partially_refunded':
        color = Colors.purple;
        label =
            status == 'refunded'
                ? Translations.get('refunded', languageCode)
                : Translations.get('partial_refund', languageCode);
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
    if (method.contains('qr') || method.contains('bank'))
      return Icons.qr_code_2;
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

  void _viewReceipt(Transaction transaction, String languageCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Translations.get('receipt_viewing_coming_soon', languageCode),
        ),
      ),
    );
  }
}
