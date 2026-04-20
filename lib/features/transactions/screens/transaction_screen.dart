import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day - 30);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      ref.read(transactionProvider.notifier).setDateRange(_startDate, _endDate);
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      ref.read(transactionProvider.notifier).setDateRange(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionProvider);
    final lang = ref.watch(localizationProvider).languageCode;
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer:
            const Drawer(child: AppSidebar(isInDrawer: true)),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title:
              _isSearchVisible
                  ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    onSubmitted: (v) {
                      setState(() {});
                    },
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: Translations.get('search', lang),
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                  : Text(
                    Translations.get('transactions', lang),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearchVisible ? Icons.close : Icons.search,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchController.clear();
                    setState(() {});
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Divider(height: 1, color: Colors.grey.shade200),

            // Date filter bar
            InkWell(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppTheme.primaryOrange,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                          : Translations.get('select_date_range', lang),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // Transaction list
            Expanded(
              child:
                  state.isLoading && state.transactions.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.transactions.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              Translations.get('no_transactions_found', lang),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh:
                            () =>
                                ref
                                    .read(transactionProvider.notifier)
                                    .refresh(),
                        child: _buildGroupedList(state.transactions, lang),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  /// Group transactions by date and build list
  Widget _buildGroupedList(List<Transaction> allTransactions, String lang) {
    // Client-side search filter
    final query = _searchController.text.trim().toLowerCase();
    final transactions =
        query.isEmpty
            ? allTransactions
            : allTransactions.where((txn) {
              return txn.transactionId.toLowerCase().contains(query) ||
                  txn.lineItems.any(
                    (item) => item.name.toLowerCase().contains(query),
                  );
            }).toList();

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Text(
            Translations.get('no_transactions_found', lang),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final grouped = <String, List<Transaction>>{};
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');

    for (final txn in transactions) {
      final date = (txn.timing.initiatedAt ?? txn.createdAt).toLocal();
      final key = dateFormat.format(date);
      grouped.putIfAbsent(key, () => []).add(txn);
    }

    final entries = grouped.entries.toList();

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (_, groupIndex) {
        final dateLabel = entries[groupIndex].key;
        final items = entries[groupIndex].value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.grey.shade50,
              child: Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // Transaction rows
            ...items.map(
              (txn) => Column(
                children: [
                  _buildTransactionRow(txn, lang),
                  Divider(height: 1, indent: 72, color: Colors.grey.shade200),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionRow(Transaction txn, String lang) {
    final time = DateFormat(
      'h:mm a',
    ).format((txn.timing.initiatedAt ?? txn.createdAt).toLocal());
    final amount = txn.consolidatedTotals.grandTotal.amount;
    final method = _getPrimaryMethod(txn);
    final isRefund =
        txn.transactionType == 'refund' || txn.transactionStatus == 'refunded';

    return InkWell(
      onTap: () => context.push('/transactions/${txn.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Payment method icon
            Icon(_getMethodIcon(method), size: 28, color: Colors.grey.shade600),
            const SizedBox(width: 16),

            // Amount + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.formatLAKWithSymbol(amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isRefund ? AppTheme.error : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Transaction ID + refund label
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  txn.shortId,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (isRefund) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Refund',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPrimaryMethod(Transaction txn) {
    if (txn.paymentSummary == null ||
        txn.paymentSummary!.paymentMethodBreakdown.isEmpty) {
      return 'cash';
    }
    return txn.paymentSummary!.paymentMethodBreakdown.first.method;
  }

  IconData _getMethodIcon(String method) {
    if (method == 'cash') return Icons.payments_outlined;
    if (method.contains('card')) return Icons.credit_card;
    if (method.contains('qr') || method.contains('bank')) {
      return Icons.qr_code_2;
    }
    return Icons.payment;
  }
}
