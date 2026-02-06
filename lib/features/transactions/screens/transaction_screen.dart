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
import '../widgets/transaction_filter_dialog.dart';
import '../widgets/transaction_summary_cards.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Load transactions on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    // Set default date range (last 7 days)
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day - 7);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    ref.read(transactionProvider.notifier).setDateRange(_startDate, _endDate);
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

  void _showFilters() async {
    final result = await showDialog<TransactionFilters>(
      context: context,
      builder:
          (context) => TransactionFilterDialog(
            currentFilters: ref.read(transactionProvider).filters,
          ),
    );

    if (result != null) {
      ref.read(transactionProvider.notifier).applyFilters(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final isMobile = Responsive.isMobile(context);
    final languageCode = ref.watch(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          title: Text(Translations.get('transactions', languageCode)),
          surfaceTintColor: AppTheme.scaffoldBackground,
          actions: [
            // Date range button
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: Translations.get('date_range', languageCode),
              onPressed: _pickDateRange,
            ),
            // Filter button
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: Translations.get('filters', languageCode),
              onPressed: _showFilters,
            ),
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: Translations.get('refresh', languageCode),
              onPressed: () => ref.read(transactionProvider.notifier).refresh(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body:
            transactionState.isLoading && transactionState.transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : transactionState.error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text(transactionState.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () =>
                                ref
                                    .read(transactionProvider.notifier)
                                    .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh:
                      () => ref.read(transactionProvider.notifier).refresh(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date range display
                        _buildDateRangeDisplay(languageCode),
                        const SizedBox(height: 16),

                        // Active filters chips
                        if (transactionState.filters.hasActiveFilters)
                          _buildActiveFilters(
                            transactionState.filters,
                            languageCode,
                          ),

                        // Summary cards
                        if (transactionState.summary != null) ...[
                          const SizedBox(height: 16),
                          TransactionSummaryCards(
                            summary: transactionState.summary!,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Transactions list
                        _buildTransactionsList(
                          transactionState,
                          isMobile,
                          languageCode,
                        ),

                        // Pagination
                        if (transactionState.pagination != null) ...[
                          const SizedBox(height: 16),
                          _buildPagination(
                            transactionState.pagination!,
                            languageCode,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildDateRangeDisplay(String languageCode) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrangeBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            size: 20,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _startDate != null && _endDate != null
                  ? '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'
                  : Translations.get('select_date_range', languageCode),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit,
              size: 20,
              color: AppTheme.primaryOrange,
            ),
            onPressed: _pickDateRange,
            tooltip: Translations.get('change_date_range', languageCode),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(TransactionFilters filters, String languageCode) {
    final chips = <Widget>[];

    if (filters.status != null) {
      chips.add(
        _buildFilterChip(
          'Status: ${_getStatusLabel(filters.status!)}',
          () => ref.read(transactionProvider.notifier).setStatusFilter(null),
        ),
      );
    }

    if (filters.method != null) {
      chips.add(
        _buildFilterChip(
          'Method: ${_getMethodLabel(filters.method!, languageCode)}',
          () => ref.read(transactionProvider.notifier).setMethodFilter(null),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              Translations.get('active_filters', languageCode),
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            ...chips,
            const Spacer(),
            TextButton.icon(
              onPressed:
                  () => ref.read(transactionProvider.notifier).clearFilters(),
              icon: const Icon(Icons.clear, size: 16),
              label: Text(Translations.get('clear_all', languageCode)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDeleted,
        backgroundColor: AppTheme.neutral100,
      ),
    );
  }

  Widget _buildTransactionsList(
    TransactionState state,
    bool isMobile,
    String languageCode,
  ) {
    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(Icons.receipt_long, size: 64, color: AppTheme.neutral300),
            const SizedBox(height: 16),
            Text(
              Translations.get('no_transactions_found', languageCode),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.get('try_adjusting_your_filters', languageCode),
              style: TextStyle(color: AppTheme.neutral500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final transaction = state.transactions[index];
        return _buildTransactionCard(transaction, isMobile, languageCode);
      },
    );
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    bool isMobile,
    String languageCode,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/transactions/${transaction.transactionId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getPaymentMethodColor(
                        transaction,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPaymentMethodIcon(transaction),
                      color: _getPaymentMethodColor(transaction),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.transactionId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  _buildStatusBadge(
                    transaction.transactionStatus,
                    languageCode,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(
                            transaction.timing.initiatedAt ??
                                transaction.createdAt,
                          ),
                          style: const TextStyle(
                            color: AppTheme.neutral600,
                            fontSize: 13,
                          ),
                        ),
                        if (transaction.staff?.processedBy != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${Translations.get('by', languageCode)} ${transaction.staff!.processedBy!.name}',
                            style: const TextStyle(
                              color: AppTheme.neutral500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (transaction.paymentSummary != null &&
                      transaction
                          .paymentSummary!
                          .paymentMethodBreakdown
                          .isNotEmpty)
                    Text(
                      _getMethodLabel(
                        transaction
                            .paymentSummary!
                            .paymentMethodBreakdown
                            .first
                            .method,
                        languageCode,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.formatLAKWithSymbol(
                      transaction.consolidatedTotals.grandTotal.amount,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color:
                          transaction.isVoided
                              ? AppTheme.error
                              : AppTheme.neutral900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPagination(PaginationInfo pagination, String languageCode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              pagination.hasPrev
                  ? () {
                    final currentPage =
                        ref.read(transactionProvider).filters.page;
                    ref
                        .read(transactionProvider.notifier)
                        .applyFilters(
                          ref
                              .read(transactionProvider)
                              .filters
                              .copyWith(page: currentPage - 1),
                        );
                  }
                  : null,
          icon: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: 8),
        Text(
          '${Translations.get('page', languageCode)} ${pagination.page} ${Translations.get('of', languageCode)} ${pagination.totalPages}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed:
              pagination.hasNext
                  ? () {
                    final currentPage =
                        ref.read(transactionProvider).filters.page;
                    ref
                        .read(transactionProvider.notifier)
                        .applyFilters(
                          ref
                              .read(transactionProvider)
                              .filters
                              .copyWith(page: currentPage + 1),
                        );
                  }
                  : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(Transaction transaction) {
    if (transaction.paymentSummary == null ||
        transaction.paymentSummary!.paymentMethodBreakdown.isEmpty) {
      return Icons.payments;
    }

    final method =
        transaction.paymentSummary!.paymentMethodBreakdown.first.method;

    if (method == 'cash') return Icons.payments;
    if (method.contains('card')) return Icons.credit_card;
    if (method.contains('qr') || method.contains('bank'))
      return Icons.qr_code_2;
    return Icons.payment;
  }

  Color _getPaymentMethodColor(Transaction transaction) {
    if (transaction.paymentSummary == null ||
        transaction.paymentSummary!.paymentMethodBreakdown.isEmpty) {
      return AppTheme.neutral600;
    }

    final method =
        transaction.paymentSummary!.paymentMethodBreakdown.first.method;

    if (method == 'cash') return AppTheme.success;
    if (method.contains('card')) return Colors.blue;
    if (method.contains('qr') || method.contains('bank'))
      return AppTheme.primaryOrange;
    return AppTheme.neutral600;
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'voided':
        return 'Voided';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }

  String _getMethodLabel(String method, String languageCode) {
    switch (method) {
      case 'cash':
        return Translations.get('cash', languageCode);
      case 'card':
        return Translations.get('card', languageCode);
      case 'bank_qr_jdb':
        return 'JDB QR';
      case 'bank_qr_bcel':
        return 'BCEL QR';
      case 'bank_qr_ldb':
        return 'LDB QR';
      case 'bank_qr_ib':
        return 'IB QR';
      default:
        return method.replaceAll('_', ' ').toUpperCase();
    }
  }
}
