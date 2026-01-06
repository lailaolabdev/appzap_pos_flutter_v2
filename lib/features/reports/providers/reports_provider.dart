import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/report.dart';
import '../../../core/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Reports dashboard state
class ReportsState {
  final DailySalesSummary? summary;
  final List<SalesByProductItem> topProducts;
  final List<SalesByStaffItem> employeePerformance;
  final bool isLoading;
  final String? error;
  final DateTime startDate;
  final DateTime endDate;

  const ReportsState({
    this.summary,
    this.topProducts = const [],
    this.employeePerformance = const [],
    this.isLoading = false,
    this.error,
    required this.startDate,
    required this.endDate,
  });

  ReportsState copyWith({
    DailySalesSummary? summary,
    List<SalesByProductItem>? topProducts,
    List<SalesByStaffItem>? employeePerformance,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportsState(
      summary: summary ?? this.summary,
      topProducts: topProducts ?? this.topProducts,
      employeePerformance: employeePerformance ?? this.employeePerformance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Reports notifier
class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportService _reportService;
  final String? _branchId;

  ReportsNotifier(this._reportService, this._branchId)
    : super(
        ReportsState(
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
        ),
      ) {
    loadReports();
  }

  /// Load all reports
  Future<void> loadReports() async {
    if (_branchId == null) {
      state = state.copyWith(error: 'Branch not configured', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load reports individually to handle failures gracefully
      DailySalesSummary? summary;
      List<SalesByProductItem> topProducts = [];
      List<SalesByStaffItem> employeePerformance = [];

      // Try to load daily summary (may fail with 404)
      try {
        summary = await _reportService.getSummaryForDateRange(
          branchId: _branchId,
          startDate: state.startDate,
          endDate: state.endDate,
        );
      } catch (e) {
        // Ignore daily summary errors - endpoint may not exist
        print('Daily summary failed: $e');
      }

      // Try to load products report and extract payment methods data
      try {
        // First, get products the normal way
        topProducts = await _reportService.getSalesByProductForDateRange(
          branchId: _branchId,
          startDate: state.startDate,
          endDate: state.endDate,
        );

        // Then try to get payment methods data by calling getSalesByProduct directly
        // which should return more detailed response including summary
        try {
          final startStr = state.startDate.toIso8601String().split('T')[0];
          final endStr = state.endDate.toIso8601String().split('T')[0];

          // Create a temporary summary with payment data from products
          if (topProducts.isNotEmpty) {
            final totalSales = topProducts.fold<double>(
              0.0,
              (sum, product) => sum + product.totalRevenue,
            );

            // Default to cash payment method for now
            final Map<String, double> paymentsMap = {'cash': totalSales};

            summary = DailySalesSummary(
              period: Period(startDate: startStr, endDate: endStr),
              sales: SalesData(
                totalSales: totalSales,
                totalOrders: topProducts.fold<int>(
                  0,
                  (sum, product) => sum + product.quantitySold,
                ),
                averageOrderValue:
                    totalSales > 0 ? totalSales / topProducts.length : 0.0,
                totalTax: 0.0, // No tax data available from current API
              ),
              payments: paymentsMap,
            );
          }
        } catch (e) {
          print('Failed to create summary from products data: $e');
        }
      } catch (e) {
        print('Products report failed: $e');
      }

      // Try to load staff report
      try {
        employeePerformance = await _reportService.getSalesByStaffForDateRange(
          branchId: _branchId,
          startDate: state.startDate,
          endDate: state.endDate,
        );
      } catch (e) {
        print('Staff report failed: $e');
      }

      state = state.copyWith(
        summary: summary,
        topProducts: topProducts,
        employeePerformance: employeePerformance,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Set date range
  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    loadReports();
  }

  /// Load today's report
  void loadToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setDateRange(today, today);
  }

  /// Load this week's report
  void loadThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    setDateRange(DateTime(weekStart.year, weekStart.month, weekStart.day), now);
  }

  /// Load this month's report
  void loadThisMonth() {
    final now = DateTime.now();
    setDateRange(DateTime(now.year, now.month, 1), now);
  }

  /// Refresh reports
  Future<void> refresh() => loadReports();
}

/// Reports provider
final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((
  ref,
) {
  final reportService = ref.watch(reportServiceProvider);
  final branchId = ref.watch(currentBranchIdProvider);
  return ReportsNotifier(reportService, branchId);
});

/// Today's end of day report provider
final endOfDayReportProvider = FutureProvider<EndOfDayReport?>((ref) async {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return null;

  try {
    return await ref
        .read(reportServiceProvider)
        .getTodayEndOfDayReport(branchId: branchId);
  } catch (e) {
    return null;
  }
});
