import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/models/transaction.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
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
  bool _isPrinting = false;

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
    final state = ref.watch(transactionProvider);
    final txn = state.selectedTransaction;
    final lang = ref.watch(localizationProvider).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          txn != null ? txn.shortId : '',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon:
                _isPrinting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryOrange,
                      ),
                    )
                    : const Icon(Icons.print, color: Colors.black),
            onPressed:
                (_isPrinting || txn == null)
                    ? null
                    : () => _printTransactionReceipt(txn),
          ),
        ],
      ),
      body:
          state.isLoading && txn == null
              ? const Center(child: CircularProgressIndicator())
              : state.error != null && txn == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed:
                          () => ref
                              .read(transactionProvider.notifier)
                              .loadTransaction(widget.transactionId),
                      child: Text(
                        Translations.get('retry', lang),
                        style: const TextStyle(color: AppTheme.primaryOrange),
                      ),
                    ),
                  ],
                ),
              )
              : txn == null
              ? Center(
                child: Text(
                  Translations.get('transaction_not_found', lang),
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
              : _buildContent(txn, lang),
    );
  }

  Widget _buildContent(Transaction txn, String lang) {
    final total = txn.consolidatedTotals.grandTotal.amount;
    final subtotal = txn.consolidatedTotals.subtotal.amount;
    final tax = txn.consolidatedTotals.tax.amount;
    final discount = txn.consolidatedTotals.discounts.amount;
    final payment = txn.payments.isNotEmpty ? txn.payments.first : null;
    final methodLabel =
        payment != null ? _methodLabel(payment.method, lang) : '';
    final methodIcon =
        payment != null ? _methodIcon(payment.method) : Icons.payments_outlined;
    final staffName = txn.staff?.processedBy?.name;
    final staffRole = txn.staff?.processedBy?.role;
    final orderType =
        txn.transactionType == 'sale' ? 'Takeaway' : txn.transactionType;
    final date = (txn.timing.initiatedAt ?? txn.createdAt).toLocal();
    final isRefund =
        txn.transactionType == 'refund' || txn.transactionStatus == 'refunded';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── Receipt Card ───
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // ─── Status Banner ───
                const SizedBox(height: 20),
                Container(
                  child: Text(
                    isRefund
                        ? Translations.get('refunded', lang)
                        : Translations.get('completed', lang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isRefund ? AppTheme.error : AppTheme.primaryOrange,
                    ),
                  ),
                ),
                // ─── Total Amount ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: Text(
                    CurrencyFormatter.formatLAKWithSymbol(total),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Text(
                  Translations.get('total', lang),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 20),

                // ─── Info Rows ───
                _divider(),
                if (staffName != null)
                  _infoRow(
                    Icons.person_outline,
                    Translations.get('employee', lang),
                    '$staffName${staffRole != null ? ' ($staffRole)' : ''}',
                  ),
                if (txn.qNumber != null)
                  _infoRow(
                    Icons.tag,
                    Translations.get('queue', lang),
                    '#${txn.qNumber}',
                  ),
                _infoRow(
                  Icons.access_time,
                  Translations.get('date', lang),
                  DateFormat('dd MMM yyyy, h:mm a').format(date),
                ),
                _infoRow(
                  orderType == 'Takeaway'
                      ? Icons.shopping_bag_outlined
                      : Icons.restaurant,
                  Translations.get('type', lang),
                  orderType == 'Takeaway'
                      ? Translations.get('takeaway', lang)
                      : orderType,
                ),

                // ─── Line Items Section ───
                _divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        '${Translations.get('items', lang)} (${txn.lineItems.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                ...txn.lineItems.map((item) => _buildLineItem(item)),

                // ─── Summary Section ───
                _divider(),
                const SizedBox(height: 8),
                if (subtotal != total) ...[
                  _summaryRow(Translations.get('subtotal', lang), subtotal),
                  if (tax > 0) _summaryRow(Translations.get('tax', lang), tax),
                  if (discount > 0)
                    _summaryRow(
                      Translations.get('discount', lang),
                      -discount,
                      isRed: true,
                    ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),
                  const SizedBox(height: 4),
                ],
                _summaryRow(
                  Translations.get('total', lang),
                  total,
                  isBold: true,
                ),
                const SizedBox(height: 4),

                // ─── Payment Method ───
                _divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          methodIcon,
                          size: 20,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              methodLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (payment?.changeAmount != null &&
                                payment!.changeAmount!.amount > 0)
                              Text(
                                '${Translations.get('change', lang)}: ${CurrencyFormatter.formatLAKWithSymbol(payment.changeAmount!.amount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatLAKWithSymbol(total),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Footer ───
                _divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('d/M/yy h:mm a').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        txn.shortId,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Colors.grey.shade100,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(TransactionLineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantity}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.options.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.optionsSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                Text(
                  CurrencyFormatter.formatLAKWithSymbol(item.unitPrice),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatLAKWithSymbol(item.total),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              color:
                  isRed
                      ? AppTheme.error
                      : (isBold ? Colors.black : Colors.grey.shade600),
            ),
          ),
          Text(
            CurrencyFormatter.formatLAKWithSymbol(amount),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isRed ? AppTheme.error : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  IconData _methodIcon(String method) {
    if (method == 'cash') return Icons.payments_outlined;
    if (method.contains('card')) return Icons.credit_card;
    if (method.contains('qr') || method.contains('bank'))
      return Icons.qr_code_2;
    return Icons.payment;
  }

  String _methodLabel(String method, String lang) {
    switch (method) {
      case 'cash':
        return Translations.get('cash', lang);
      case 'card':
        return Translations.get('card', lang);
      case 'bank_qr_jdb':
        return Translations.get('jdb_qr', lang);
      case 'bank_qr_bcel':
        return Translations.get('bcel_qr', lang);
      case 'bank_qr_ldb':
        return Translations.get('ldb_qr', lang);
      default:
        return method.replaceAll('_', ' ');
    }
  }

  Future<void> _printTransactionReceipt(Transaction txn) async {
    setState(() => _isPrinting = true);
    final lang = ref.read(localizationProvider).languageCode;

    try {
      final settings = ref.read(settingsProvider);
      final printerService = ref.read(settingsProvider.notifier).printerService;

      if (settings.printerName.isEmpty) {
        throw Exception('No printer configured');
      }

      // Connect if needed
      if (!printerService.isConnected) {
        final isSunmi = await printerService.isSunmiDevice();
        if (isSunmi) {
          await printerService.ensureSunmiConnected(force: true);
        }
        if (!printerService.isConnected) {
          throw Exception('Printer not connected');
        }
      }

      // Get paper width
      final activePrinter =
          settings.printers.isNotEmpty
              ? settings.printers.firstWhere(
                (p) => p.name == settings.printerName,
                orElse: () => settings.printers.first,
              )
              : null;

      // Build items list from transaction line items
      final items =
          txn.lineItems
              .map(
                (item) => {
                  'name': item.name,
                  'quantity': item.quantity,
                  'price': item.unitPrice,
                },
              )
              .toList();

      final total = txn.consolidatedTotals.grandTotal.amount;
      final staffName = txn.staff?.processedBy?.name ?? 'Staff';

      final restaurantName = ref.read(currentUserProvider)?.restaurant?.name;
      final receiptHeader =
          settings.receiptHeader.isNotEmpty
              ? settings.receiptHeader
              : (restaurantName?.isNotEmpty == true)
              ? restaurantName!
              : 'APPZAP POS';

      final success = await printerService.printReceipt(
        header: receiptHeader,
        orderId: txn.shortId,
        serverName: staffName,
        items: items,
        total: total,
        orderType:
            txn.transactionType == 'sale' ? 'Takeaway' : txn.transactionType,
        paymentMethod: txn.payments.isNotEmpty ? txn.payments.first.method : '',
        paperWidth: activePrinter?.paperWidth ?? '80 mm',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? Translations.get('success', lang)
                  : Translations.get('error', lang),
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }

    if (mounted) setState(() => _isPrinting = false);
  }
}
