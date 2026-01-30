import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/transaction.dart';

/// Transaction Service - Handles all transaction-related API calls
class TransactionService {
  final Dio _dio;

  TransactionService(this._dio);

  /// Create a new transaction
  Future<Transaction> createTransaction({
    required String transactionType,
    required String branchId,
    required List<Map<String, dynamic>> orderReferences,
    required List<Map<String, dynamic>> payments,
    Map<String, dynamic>? customer,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.transactions,
        data: {
          'transactionType': transactionType,
          'branchId': branchId,
          'orderReferences': orderReferences,
          'payments': payments,
          if (customer != null) 'customer': customer,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return Transaction.fromJson(data);
    } catch (e) {
      print('❌ Create transaction error: $e');
      rethrow;
    }
  }

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
        transactions:
            (data['transactions'] as List<dynamic>?)?.map((json) {
              final transformedData = _transformApiResponse(
                json as Map<String, dynamic>,
              );
              return Transaction.fromJson(transformedData);
            }).toList() ??
            [],
        pagination: PaginationInfo.fromJson(
          data['pagination'] as Map<String, dynamic>? ?? {},
        ),
        summary:
            data['summary'] != null
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
      Response? response;

      // Primary endpoint: /transactions/{transactionId} as per documentation
      try {
        final endpoint = ApiConstants.transactionById.replaceAll(
          '{transactionId}',
          transactionId,
        );
        response = await _dio.get(endpoint);
        print(' response: $response');
        print('✅ Successfully retrieved transaction via primary endpoint');
      } catch (e) {
        print('❌ Primary endpoint failed: ${e.toString()}');

        // Fallback: Search in transaction list with filter
        try {
          print('🔄 Trying fallback: search in transaction list');
          response = await _dio.get(
            ApiConstants.transactions,
            queryParameters: {'transactionId': transactionId, 'limit': 1},
          );
          print('✅ Retrieved transaction via list filter');
        } catch (e2) {
          print('❌ Fallback endpoint failed: ${e2.toString()}');
          throw Exception(
            'Unable to retrieve transaction $transactionId. Please check if the transaction exists.',
          );
        }
      }

      if (response.data == null) throw Exception('No valid response received');

      // ✅ Handle wrapped response format like the list endpoint
      final data = response.data;

      print('📊 Raw API Response: ${data.runtimeType}');
      print(
        '📊 Response Keys: ${data is Map ? data.keys.toList() : 'Not a map'}',
      );

      try {
        Map<String, dynamic> transactionData;

        // Handle API response structure as per documentation
        if (data is Map<String, dynamic> && data.containsKey('_id')) {
          // Direct transaction object (when fetching by ID)
          transactionData = data;
          print('📊 Using direct transaction format');
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          final wrappedData = data['data'] as Map<String, dynamic>;

          // Check if this is a transaction list response (fallback endpoint)
          if (wrappedData.containsKey('transactions')) {
            final transactions = wrappedData['transactions'] as List<dynamic>;
            if (transactions.isEmpty) {
              throw Exception('Transaction $transactionId not found');
            }
            // Extract the single transaction from the filtered list
            transactionData = transactions.first as Map<String, dynamic>;
            print('📊 Extracted transaction from list response');
          } else {
            // Direct transaction in wrapped format
            transactionData = wrappedData;
            print('📊 Using wrapped transaction format');
          }
        } else {
          // Fallback to direct format
          transactionData = data as Map<String, dynamic>;
          print('📊 Using fallback direct format');
        }

        print('📊 Transaction Data Keys: ${transactionData.keys.toList()}');

        // Transform API response to match Transaction model expectations
        final transformedData = _transformApiResponse(transactionData);
        return Transaction.fromJson(transformedData);
      } catch (parseError) {
        print('❌ JSON Parsing Error: $parseError');
        print('📊 Problem Data: $data');
        throw Exception('Failed to parse transaction data: $parseError');
      }
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
      final endpoint = ApiConstants.transactionRefund.replaceAll(
        '{transactionId}',
        transactionId,
      );

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
      final endpoint = ApiConstants.transactionVoid.replaceAll(
        '{transactionId}',
        transactionId,
      );

      final response = await _dio.post(
        endpoint,
        data: {
          'voidReason': reason, // Match documented field name
          'managerApproval': {
            'managerId': managerId,
            'managerPin': approvalCode, // Match documented field name
          },
          if (notes != null) 'notes': notes,
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
      final endpoint = ApiConstants.transactionReceipt.replaceAll(
        '{transactionId}',
        transactionId,
      );

      final response = await _dio.get(endpoint);

      return TransactionReceipt.fromJson(
        response.data['data'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      print('❌ Get receipt error: $e');
      rethrow;
    }
  }

  /// Transform API response to match Transaction model expectations
  Map<String, dynamic> _transformApiResponse(Map<String, dynamic> apiData) {
    final transformed = <String, dynamic>{};

    // Copy basic fields
    transformed['_id'] = apiData['_id'];
    transformed['transactionId'] = apiData['transactionId'];
    transformed['transactionType'] = apiData['transactionType'] ?? 'sale';
    transformed['transactionStatus'] =
        apiData['transactionStatus'] ?? 'completed';

    // Transform amount structure to consolidatedTotals
    final amount = _extractAmountValue(apiData['amount']);
    final paidAmount = _extractAmountValue(apiData['paidAmount']);

    transformed['consolidatedTotals'] = {
      'subtotal': {'amount': amount, 'currency': 'LAK'},
      'tax': {'amount': 0.0, 'currency': 'LAK'},
      'discounts': {'amount': 0.0, 'currency': 'LAK'},
      'serviceCharge': {'amount': 0.0, 'currency': 'LAK'},
      'grandTotal': {'amount': amount, 'currency': 'LAK'},
    };

    // Transform payment methods to payments array
    final paymentMethods = apiData['paymentMethods'] as List<dynamic>? ?? [];

    transformed['payments'] =
        paymentMethods.isNotEmpty
            ? paymentMethods
                .map(
                  (method) => {
                    'paymentId': 'pay_${DateTime.now().millisecondsSinceEpoch}',
                    'method': method.toString(),
                    'status': 'completed',
                    'customerAmount': {'amount': paidAmount, 'currency': 'LAK'},
                    'tenderedAmount': {'amount': paidAmount, 'currency': 'LAK'},
                    'changeAmount': {'amount': 0.0, 'currency': 'LAK'},
                  },
                )
                .toList()
            : [
              {
                'paymentId': 'pay_${DateTime.now().millisecondsSinceEpoch}',
                'method': 'cash',
                'status': 'completed',
                'customerAmount': {'amount': paidAmount, 'currency': 'LAK'},
                'tenderedAmount': {'amount': paidAmount, 'currency': 'LAK'},
                'changeAmount': {'amount': 0.0, 'currency': 'LAK'},
              },
            ];

    // Create payment summary
    transformed['paymentSummary'] = {
      'totalPaid': {'amount': paidAmount, 'currency': 'LAK'},
      'changeGiven': {'amount': 0.0, 'currency': 'LAK'},
      'paymentMethodBreakdown':
          paymentMethods.isNotEmpty
              ? paymentMethods
                  .map(
                    (method) => {
                      'method': method.toString(),
                      'amount': {'amount': paidAmount, 'currency': 'LAK'},
                    },
                  )
                  .toList()
              : [
                {
                  'method': 'cash',
                  'amount': {'amount': paidAmount, 'currency': 'LAK'},
                },
              ],
    };

    // Create empty line items if not present
    transformed['lineItems'] = apiData['lineItems'] ?? [];

    // Copy timing
    transformed['timing'] =
        apiData['timing'] ??
        {
          'createdAt': DateTime.now().toIso8601String(),
          'completedAt': DateTime.now().toIso8601String(),
        };

    // Create staff structure
    if (apiData['processedBy'] != null) {
      transformed['staff'] = {
        'processedBy': apiData['processedBy'],
        'cashier': apiData['processedBy'],
      };
    }

    // Copy other fields
    transformed['tableInfo'] = apiData['tableInfo'];
    transformed['tableSessionId'] = apiData['tableSessionId'];
    transformed['countInTotals'] = apiData['countInTotals'] ?? true;

    print('✅ API response transformed successfully');
    return transformed;
  }

  /// Helper method to extract amount value from API response
  /// Handles both direct numbers and {amount: number, currency: string} objects
  double _extractAmountValue(dynamic value) {
    if (value == null) return 0.0;

    // If it's already a number, return it
    if (value is num) return value.toDouble();

    // If it's a Map with 'amount' field, extract the amount
    if (value is Map<String, dynamic> && value.containsKey('amount')) {
      final amount = value['amount'];
      if (amount is num) return amount.toDouble();
    }

    // Fallback: try to parse as string or return 0
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
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

  /// Static helper method to extract amount value from API response
  /// Handles both direct numbers and {amount: number, currency: string} objects
  static double extractAmountValue(dynamic value) {
    if (value == null) return 0.0;

    // If it's already a number, return it
    if (value is num) return value.toDouble();

    // If it's a Map with 'amount' field, extract the amount
    if (value is Map<String, dynamic> && value.containsKey('amount')) {
      final amount = value['amount'];
      if (amount is num) return amount.toDouble();
    }

    // Fallback: try to parse as string or return 0
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }
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
      totalRevenue: TransactionHistoryResponse.extractAmountValue(
        json['totalRevenue'],
      ),
      averageTransactionValue: TransactionHistoryResponse.extractAmountValue(
        json['averageTransactionValue'],
      ),
      paymentMethodBreakdown:
          (json['paymentMethodBreakdown'] as List<dynamic>?)
              ?.map(
                (e) => PaymentMethodStat.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      statusBreakdown:
          (json['statusBreakdown'] as List<dynamic>?)
              ?.map((e) => StatusStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dailyTransactions:
          (json['dailyTransactions'] as List<dynamic>?)
              ?.map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hourlyTransactions:
          (json['hourlyTransactions'] as List<dynamic>?)
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
      totalAmount: TransactionHistoryResponse.extractAmountValue(
        json['totalAmount'],
      ),
      percentage: TransactionHistoryResponse.extractAmountValue(
        json['percentage'],
      ),
    );
  }
}

/// Status Stat
class StatusStat {
  final String status;
  final int count;

  StatusStat({required this.status, required this.count});

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
      totalAmount: TransactionHistoryResponse.extractAmountValue(
        json['totalAmount'],
      ),
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
      totalAmount: TransactionHistoryResponse.extractAmountValue(
        json['totalAmount'],
      ),
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
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      totals: json['totals'] as Map<String, dynamic>? ?? {},
      payment: json['payment'] as Map<String, dynamic>? ?? {},
      staff: json['staff'] as String? ?? '',
      date:
          json['date'] != null
              ? DateTime.parse(json['date'] as String)
              : DateTime.now(),
      receiptHtml: json['receiptHtml'] as String?,
      receiptText: json['receiptText'] as String?,
    );
  }
}
