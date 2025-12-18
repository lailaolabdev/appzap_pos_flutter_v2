import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/transaction.dart';

/// Transaction Service - Handles all transaction-related API calls
class TransactionService {
  final Dio _dio;

  TransactionService(this._dio);

  /// Get transaction history with filtering and pagination
  Future<TransactionHistoryResponse> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? status,
    String? method,
    String? staffId,
    int page = 1,
    int limit = 20,
    bool includeSummary = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'includeSummary': includeSummary.toString(),
      };

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      if (branchId != null) queryParams['branchId'] = branchId;
      if (status != null) queryParams['status'] = status;
      if (method != null) queryParams['method'] = method;
      if (staffId != null) queryParams['staffId'] = staffId;

      final response = await _dio.get(
        ApiConstants.transactions,
        queryParameters: queryParams,
      );

      // ✅ Access nested data structure
      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      return TransactionHistoryResponse(
        transactions: (data['transactions'] as List<dynamic>?)
                ?.map((json) => Transaction.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [],
        pagination: PaginationInfo.fromJson(
          data['pagination'] as Map<String, dynamic>? ?? {},
        ),
        summary: data['summary'] != null
            ? TransactionSummary.fromJson(
                data['summary'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (e) {
      print('❌ Get transactions error: $e');
      rethrow;
    }
  }

  /// Get single transaction details
  Future<Transaction> getTransaction(String transactionId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.transactions}$transactionId',
      );

      // ⚠️ Direct response (not wrapped in {success, data})
      return Transaction.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('❌ Get transaction error: $e');
      rethrow;
    }
  }

  /// Get transaction summary (aggregate statistics)
  Future<TransactionSummaryReport> getSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      if (branchId != null) queryParams['branchId'] = branchId;

      final response = await _dio.get(
        ApiConstants.transactionSummary,
        queryParameters: queryParams,
      );

      return TransactionSummaryReport.fromJson(
        response.data['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      print('❌ Get transaction summary error: $e');
      rethrow;
    }
  }

  /// Process refund
  Future<RefundResult> processRefund({
    required String transactionId,
    required double refundAmount,
    required String refundMethod,
    required String reason,
    String? notes,
    required String managerId,
    required String approvalCode,
  }) async {
    try {
      final endpoint = ApiConstants.transactionRefund
          .replaceAll('{transactionId}', transactionId);

      final response = await _dio.post(
        endpoint,
        data: {
          'refundAmount': refundAmount,
          'refundMethod': refundMethod,
          'reason': reason,
          if (notes != null) 'notes': notes,
          'managerApproval': {
            'managerId': managerId,
            'approvalCode': approvalCode,
          },
        },
      );

      return RefundResult.fromJson(
        response.data['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      print('❌ Process refund error: $e');
      rethrow;
    }
  }

  /// Void transaction
  Future<VoidResult> voidTransaction({
    required String transactionId,
    required String reason,
    String? notes,
    required String managerId,
    required String approvalCode,
  }) async {
    try {
      final endpoint = ApiConstants.transactionVoid
          .replaceAll('{transactionId}', transactionId);

      final response = await _dio.post(
        endpoint,
        data: {
          'reason': reason,
          if (notes != null) 'notes': notes,
          'managerApproval': {
            'managerId': managerId,
            'approvalCode': approvalCode,
          },
        },
      );

      return VoidResult.fromJson(
        response.data['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      print('❌ Void transaction error: $e');
      rethrow;
    }
  }

  /// Get transaction receipt
  Future<TransactionReceipt> getReceipt(String transactionId) async {
    try {
      final endpoint = ApiConstants.transactionReceipt
          .replaceAll('{transactionId}', transactionId);

      final response = await _dio.get(endpoint);

      return TransactionReceipt.fromJson(
        response.data['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      print('❌ Get receipt error: $e');
      rethrow;
    }
  }
}

/// Transaction History Response
class TransactionHistoryResponse {
  final List<Transaction> transactions;
  final PaginationInfo pagination;
  final TransactionSummary? summary;

  TransactionHistoryResponse({
    required this.transactions,
    required this.pagination,
    this.summary,
  });
}

/// Transaction Summary Report (aggregate statistics)
class TransactionSummaryReport {
  final int totalTransactions;
  final double totalRevenue;
  final double averageTransactionValue;
  final List<PaymentMethodStat> paymentMethodBreakdown;
  final List<StatusStat> statusBreakdown;
  final List<DailyStat> dailyTransactions;
  final List<HourlyStat> hourlyTransactions;

  TransactionSummaryReport({
    required this.totalTransactions,
    required this.totalRevenue,
    required this.averageTransactionValue,
    required this.paymentMethodBreakdown,
    required this.statusBreakdown,
    required this.dailyTransactions,
    required this.hourlyTransactions,
  });

  factory TransactionSummaryReport.fromJson(Map<String, dynamic> json) {
    return TransactionSummaryReport(
      totalTransactions: json['totalTransactions'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averageTransactionValue:
          (json['averageTransactionValue'] as num?)?.toDouble() ?? 0.0,
      paymentMethodBreakdown: (json['paymentMethodBreakdown'] as List<dynamic>?)
              ?.map((e) => PaymentMethodStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      statusBreakdown: (json['statusBreakdown'] as List<dynamic>?)
              ?.map((e) => StatusStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dailyTransactions: (json['dailyTransactions'] as List<dynamic>?)
              ?.map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hourlyTransactions: (json['hourlyTransactions'] as List<dynamic>?)
              ?.map((e) => HourlyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Payment Method Stat
class PaymentMethodStat {
  final String method;
  final int count;
  final double totalAmount;
  final double percentage;

  PaymentMethodStat({
    required this.method,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });

  factory PaymentMethodStat.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStat(
      method: json['method'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Status Stat
class StatusStat {
  final String status;
  final int count;

  StatusStat({
    required this.status,
    required this.count,
  });

  factory StatusStat.fromJson(Map<String, dynamic> json) {
    return StatusStat(
      status: json['status'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

/// Daily Stat
class DailyStat {
  final String date;
  final int count;
  final double totalAmount;

  DailyStat({
    required this.date,
    required this.count,
    required this.totalAmount,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      date: json['date'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Hourly Stat
class HourlyStat {
  final int hour;
  final int count;
  final double totalAmount;

  HourlyStat({
    required this.hour,
    required this.count,
    required this.totalAmount,
  });

  factory HourlyStat.fromJson(Map<String, dynamic> json) {
    return HourlyStat(
      hour: json['hour'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Transaction Receipt
class TransactionReceipt {
  final String receiptId;
  final String transactionId;
  final Map<String, dynamic> restaurant;
  final Map<String, dynamic> branch;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> totals;
  final Map<String, dynamic> payment;
  final String staff;
  final DateTime date;
  final String? receiptHtml;
  final String? receiptText;

  TransactionReceipt({
    required this.receiptId,
    required this.transactionId,
    required this.restaurant,
    required this.branch,
    required this.items,
    required this.totals,
    required this.payment,
    required this.staff,
    required this.date,
    this.receiptHtml,
    this.receiptText,
  });

  factory TransactionReceipt.fromJson(Map<String, dynamic> json) {
    return TransactionReceipt(
      receiptId: json['receiptId'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
      restaurant: json['restaurant'] as Map<String, dynamic>? ?? {},
      branch: json['branch'] as Map<String, dynamic>? ?? {},
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      totals: json['totals'] as Map<String, dynamic>? ?? {},
      payment: json['payment'] as Map<String, dynamic>? ?? {},
      staff: json['staff'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      receiptHtml: json['receiptHtml'] as String?,
      receiptText: json['receiptText'] as String?,
    );
  }
}

