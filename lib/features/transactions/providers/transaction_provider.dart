import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/transaction.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/api/api_client.dart';

/// Transaction Provider - State management for transactions
final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final transactionService = TransactionService(apiClient.dio);
  return TransactionNotifier(transactionService);
});

/// Transaction State
class TransactionState {
  final List<Transaction> transactions;
  final PaginationInfo? pagination;
  final TransactionSummary? summary;
  final TransactionFilters filters;
  final bool isLoading;
  final String? error;
  final Transaction? selectedTransaction;

  TransactionState({
    this.transactions = const [],
    this.pagination,
    this.summary,
    this.filters = const TransactionFilters(),
    this.isLoading = false,
    this.error,
    this.selectedTransaction,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    PaginationInfo? pagination,
    TransactionSummary? summary,
    TransactionFilters? filters,
    bool? isLoading,
    String? error,
    Transaction? selectedTransaction,
    bool clearError = false,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      pagination: pagination ?? this.pagination,
      summary: summary ?? this.summary,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedTransaction: selectedTransaction ?? this.selectedTransaction,
    );
  }
}

/// Transaction Filters
class TransactionFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? branchId;
  final String? status;
  final String? method;
  final String? staffId;
  final int page;
  final int limit;
  final bool includeSummary;

  const TransactionFilters({
    this.startDate,
    this.endDate,
    this.branchId,
    this.status,
    this.method,
    this.staffId,
    this.page = 1,
    this.limit = 20,
    this.includeSummary = true,
  });

  TransactionFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? status,
    String? method,
    String? staffId,
    int? page,
    int? limit,
    bool? includeSummary,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearStatus = false,
    bool clearMethod = false,
    bool clearStaffId = false,
  }) {
    return TransactionFilters(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      branchId: branchId ?? this.branchId,
      status: clearStatus ? null : (status ?? this.status),
      method: clearMethod ? null : (method ?? this.method),
      staffId: clearStaffId ? null : (staffId ?? this.staffId),
      page: page ?? this.page,
      limit: limit ?? this.limit,
      includeSummary: includeSummary ?? this.includeSummary,
    );
  }

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      status != null ||
      method != null ||
      staffId != null;

  TransactionFilters clearAll() {
    return const TransactionFilters();
  }
}

/// Transaction Notifier
class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionService _transactionService;

  TransactionNotifier(this._transactionService) : super(TransactionState());

  /// Load transactions with current filters
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _transactionService.getTransactions(
        startDate: state.filters.startDate,
        endDate: state.filters.endDate,
        branchId: state.filters.branchId,
        status: state.filters.status,
        method: state.filters.method,
        staffId: state.filters.staffId,
        page: state.filters.page,
        limit: state.filters.limit,
        includeSummary: state.filters.includeSummary,
      );

      state = state.copyWith(
        transactions: response.transactions,
        pagination: response.pagination,
        summary: response.summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions: $e',
      );
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMore() async {
    if (state.pagination == null || !state.pagination!.hasNext) return;
    if (state.isLoading) return;

    final nextPage = state.filters.page + 1;
    state = state.copyWith(
      filters: state.filters.copyWith(page: nextPage),
    );

    await loadTransactions();
  }

  /// Set date range filter
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        startDate: startDate,
        endDate: endDate,
        page: 1, // Reset to page 1
      ),
    );
    loadTransactions();
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        status: status,
        page: 1,
        clearStatus: status == null,
      ),
    );
    loadTransactions();
  }

  /// Set payment method filter
  void setMethodFilter(String? method) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        method: method,
        page: 1,
        clearMethod: method == null,
      ),
    );
    loadTransactions();
  }

  /// Set staff filter
  void setStaffFilter(String? staffId) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        staffId: staffId,
        page: 1,
        clearStaffId: staffId == null,
      ),
    );
    loadTransactions();
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      filters: state.filters.clearAll(),
    );
    loadTransactions();
  }

  /// Apply multiple filters at once
  void applyFilters(TransactionFilters filters) {
    state = state.copyWith(filters: filters.copyWith(page: 1));
    loadTransactions();
  }

  /// Load single transaction
  Future<void> loadTransaction(String transactionId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final transaction =
          await _transactionService.getTransaction(transactionId);

      state = state.copyWith(
        selectedTransaction: transaction,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transaction: $e',
      );
    }
  }

  /// Process refund
  Future<bool> processRefund({
    required String transactionId,
    required double refundAmount,
    required String refundMethod,
    required String reason,
    String? notes,
    required String managerId,
    required String approvalCode,
  }) async {
    try {
      await _transactionService.processRefund(
        transactionId: transactionId,
        refundAmount: refundAmount,
        refundMethod: refundMethod,
        reason: reason,
        notes: notes,
        managerId: managerId,
        approvalCode: approvalCode,
      );

      // Reload transactions and selected transaction
      await loadTransactions();
      if (state.selectedTransaction?.transactionId == transactionId) {
        await loadTransaction(transactionId);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to process refund: $e');
      return false;
    }
  }

  /// Void transaction
  Future<bool> voidTransaction({
    required String transactionId,
    required String reason,
    String? notes,
    required String managerId,
    required String approvalCode,
  }) async {
    try {
      await _transactionService.voidTransaction(
        transactionId: transactionId,
        reason: reason,
        notes: notes,
        managerId: managerId,
        approvalCode: approvalCode,
      );

      // Reload transactions and selected transaction
      await loadTransactions();
      if (state.selectedTransaction?.transactionId == transactionId) {
        await loadTransaction(transactionId);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to void transaction: $e');
      return false;
    }
  }

  /// Refresh (reload with current filters)
  Future<void> refresh() async {
    await loadTransactions();
  }
}

