import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../models/payment.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentService(apiClient);
});

/// Service for payment operations
class PaymentService {
  final ApiClient _apiClient;

  PaymentService(this._apiClient);

  /// Calculate pricing for an order
  Future<Map<String, dynamic>> calculatePricing(String orderId) async {
    final response = await _apiClient.post(
      ApiConstants.calculatePricing,
      data: {'orderId': orderId},
    );

    return response['data']['pricing'] as Map<String, dynamic>;
  }

  /// Process cash payment
  Future<PaymentResult> processCashPayment({
    required String orderId,
    required String branchId,
    required double total,
    required double tendered,
    List<CashDenomination>? denominations,
  }) async {
    final change = tendered - total;

    final response = await _apiClient.post(
      ApiConstants.processPayment,
      data: {
        'orderId': orderId,
        'branchId': branchId,
        'paymentMethod': 'cash',
        'amount': {
          'total': total,
          'tendered': tendered,
          'change': change,
          'currency': 'LAK',
        },
        if (denominations != null && denominations.isNotEmpty)
          'paymentDetails': CashPaymentDetails(
            denominations: denominations,
          ).toJson(),
      },
    );

    return PaymentResult.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Create PhayPay payment
  Future<PhayPayPayment> createPhayPayPayment({
    required String orderId,
    required String branchId,
    required double amount,
    required PhayPayBankMethod bankMethod,
    String? description,
    String? customerName,
    String? customerPhone,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createPhayPay,
      data: {
        'orderId': orderId,
        'branchId': branchId,
        'amount': amount,
        'currency': 'LAK',
        'bankMethod': bankMethod.code,
        if (description != null) 'description': description,
        if (customerName != null || customerPhone != null)
          'customer': {
            if (customerName != null) 'name': customerName,
            if (customerPhone != null) 'phone': customerPhone,
          },
      },
    );

    return PhayPayPayment.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Check PhayPay payment status
  Future<PhayPayStatus> checkPhayPayStatus(String paymentId) async {
    final response = await _apiClient.get(
      '${ApiConstants.phayPayStatus}/$paymentId',
    );

    return PhayPayStatus.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Watch PhayPay payment status with polling
  Stream<PhayPayStatus> watchPhayPayPayment(String paymentId) async* {
    final maxDuration = AppConstants.phayPayTimeout;
    final pollInterval = AppConstants.phayPayPollInterval;
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        final status = await checkPhayPayStatus(paymentId);
        yield status;

        if (status.isCompleted || status.isFailed || status.isExpired) {
          break;
        }

        await Future.delayed(pollInterval);
      } catch (e) {
        // Continue polling on error
        await Future.delayed(pollInterval);
      }
    }
  }

  /// Wait for PhayPay payment completion
  Future<PhayPayStatus?> waitForPayment(
    String paymentId, {
    Duration? timeout,
  }) async {
    final maxDuration = timeout ?? AppConstants.phayPayTimeout;
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        final status = await checkPhayPayStatus(paymentId);

        if (status.isCompleted) {
          return status;
        }

        if (status.isFailed || status.isExpired) {
          return status;
        }

        await Future.delayed(AppConstants.phayPayPollInterval);
      } catch (e) {
        await Future.delayed(AppConstants.phayPayPollInterval);
      }
    }

    return null;
  }
}

