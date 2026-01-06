import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/report.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportService(apiClient);
});

/// Service for reports and analytics
class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  /// Get daily sales summary
  Future<DailySalesSummary> getDailySummary({
    required String branchId,
    required String startDate, // YYYY-MM-DD
    required String endDate, // YYYY-MM-DD
  }) async {
    final response = await _apiClient.get(
      ApiConstants.dailySummary,
      queryParameters: {
        'branchId': branchId,
        'startDate': startDate,
        'endDate': endDate,
      },
    );

    return DailySalesSummary.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get daily summary for specific date
  Future<DailySalesSummary> getDailySummaryForDate({
    required String branchId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await getDailySummary(
      branchId: branchId,
      startDate: dateStr,
      endDate: dateStr,
    );
  }

  /// Get daily summary for today
  Future<DailySalesSummary> getTodaySummary({required String branchId}) async {
    return await getDailySummaryForDate(
      branchId: branchId,
      date: DateTime.now(),
    );
  }

  /// Get daily summary for date range
  Future<DailySalesSummary> getSummaryForDateRange({
    required String branchId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];
    return await getDailySummary(
      branchId: branchId,
      startDate: startStr,
      endDate: endStr,
    );
  }

  /// Get end of day report
  Future<EndOfDayReport> getEndOfDayReport({
    required String branchId,
    required String date, // YYYY-MM-DD
  }) async {
    final response = await _apiClient.get(
      ApiConstants.endOfDay,
      queryParameters: {'branchId': branchId, 'date': date},
    );

    return EndOfDayReport.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get end of day report for specific date
  Future<EndOfDayReport> getEndOfDayReportForDate({
    required String branchId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await getEndOfDayReport(branchId: branchId, date: dateStr);
  }

  /// Get today's end of day report
  Future<EndOfDayReport> getTodayEndOfDayReport({
    required String branchId,
  }) async {
    return await getEndOfDayReportForDate(
      branchId: branchId,
      date: DateTime.now(),
    );
  }

  /// Get sales by product report
  Future<List<SalesByProductItem>> getSalesByProduct({
    required String branchId,
    required String startDate,
    required String endDate,
    String? categoryId,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.salesItemsReport,
      queryParameters: {
        'branchId': branchId,
        'startDate': startDate,
        'endDate': endDate,
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );

    final data = response['data'] as List<dynamic>? ?? [];
    final List<SalesByProductItem> products = [];

    // Flatten the nested category/item structure
    for (final category in data) {
      final categoryData = category as Map<String, dynamic>;
      final items = categoryData['items'] as List<dynamic>? ?? [];

      for (final item in items) {
        final itemData = item as Map<String, dynamic>;
        final quantitySold = itemData['totalQuantity'] as int? ?? 0;
        final totalRevenue =
            (itemData['totalNetSales'] as num?)?.toDouble() ?? 0;
        final averagePrice =
            quantitySold > 0 ? totalRevenue / quantitySold : 0.0;

        products.add(
          SalesByProductItem(
            productId: itemData['menuItemId'] as String? ?? '',
            productName: itemData['itemName'] as String? ?? '',
            category: categoryData['categoryName'] as String?,
            quantitySold: quantitySold,
            totalRevenue: totalRevenue,
            averagePrice: averagePrice,
            orderCount: 0, // Not available in backend response
          ),
        );
      }
    }

    return products;
  }

  /// Get sales by product for date range
  Future<List<SalesByProductItem>> getSalesByProductForDateRange({
    required String branchId,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];
    return await getSalesByProduct(
      branchId: branchId,
      startDate: startStr,
      endDate: endStr,
      categoryId: categoryId,
    );
  }

  /// Get sales by staff/employee
  Future<List<SalesByStaffItem>> getSalesByStaff({
    required String branchId,
    required String startDate,
    required String endDate,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.salesByEmployee,
      queryParameters: {
        'branchId': branchId,
        'startDate': startDate,
        'endDate': endDate,
        'page': page,
        'limit': limit,
      },
    );

    // Handle both array and object response structures
    final data = response['data'];
    final List<SalesByStaffItem> staffMembers = [];

    if (data is List) {
      // If it's already a list, use it directly
      return data
          .map(
            (json) => SalesByStaffItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } else if (data is Map<String, dynamic>) {
      // If it's an object, check for common patterns like nested structure
      if (data.containsKey('employees') && data['employees'] is List) {
        final employees = data['employees'] as List<dynamic>;
        return employees
            .map(
              (json) => SalesByStaffItem.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else if (data.containsKey('items') && data['items'] is List) {
        final items = data['items'] as List<dynamic>;
        return items
            .map(
              (json) => SalesByStaffItem.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        // Try to convert the single object to a staff member
        try {
          final staffMember = SalesByStaffItem.fromJson(data);
          return [staffMember];
        } catch (e) {
          print('Failed to parse staff data as single object: $e');
        }
      }
    }

    return staffMembers;
  }

  /// Get sales by staff for date range
  Future<List<SalesByStaffItem>> getSalesByStaffForDateRange({
    required String branchId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];
    return await getSalesByStaff(
      branchId: branchId,
      startDate: startStr,
      endDate: endStr,
    );
  }

  /// Get sales trends
  Future<Map<String, dynamic>> getSalesTrends({
    required String branchId,
    required String period, // daily, weekly, monthly
    int daysBack = 30,
  }) async {
    final response = await _apiClient.get(
      '/reports/sales-trends',
      queryParameters: {
        'branchId': branchId,
        'period': period,
        'daysBack': daysBack,
      },
    );

    return response['data'] as Map<String, dynamic>;
  }

  /// Get category performance
  Future<List<dynamic>> getCategoryPerformance({
    required String branchId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.get(
      '/reports/category-performance',
      queryParameters: {
        'branchId': branchId,
        'startDate': startDate,
        'endDate': endDate,
      },
    );

    return response['data'] as List<dynamic>? ?? [];
  }

  /// Get payment methods breakdown
  Future<Map<String, dynamic>> getPaymentMethodsBreakdown({
    required String branchId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.get(
      '/reports/payment-methods',
      queryParameters: {
        'branchId': branchId,
        'startDate': startDate,
        'endDate': endDate,
      },
    );

    return response['data'] as Map<String, dynamic>;
  }

  /// Get hourly sales distribution
  Future<List<dynamic>> getHourlySales({
    required String branchId,
    required String date,
  }) async {
    final response = await _apiClient.get(
      '/reports/hourly-sales',
      queryParameters: {'branchId': branchId, 'date': date},
    );

    return response['data'] as List<dynamic>? ?? [];
  }

  /// Export report to PDF
  Future<String> exportReportToPDF({
    required String reportType, // daily, products, staff, eod
    required String branchId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.post(
      '/reports/export/pdf',
      data: {
        'reportType': reportType,
        'branchId': branchId,
        'startDate': startDate,
        'endDate': endDate,
      },
    );

    return response['data']['url'] as String? ?? '';
  }

  /// Export report to Excel/CSV
  Future<String> exportReportToExcel({
    required String reportType,
    required String branchId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.post(
      '/reports/export/excel',
      data: {
        'reportType': reportType,
        'branchId': branchId,
        'startDate': startDate,
        'endDate': endDate,
      },
    );

    return response['data']['url'] as String? ?? '';
  }

  /// Get report summary statistics
  Future<Map<String, dynamic>> getReportSummaryStats({
    required String branchId,
    required String period, // today, week, month, year
  }) async {
    final response = await _apiClient.get(
      '/reports/summary-stats',
      queryParameters: {'branchId': branchId, 'period': period},
    );

    return response['data'] as Map<String, dynamic>;
  }
}
