import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/cart.dart';
import '../models/order.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});

/// Service for order operations
class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  /// Create a new takeaway order
  Future<Order> createOrder({
    required String branchId,
    required Cart cart,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createOrder,
      data: cart.toOrderRequest(branchId),
    );

    return Order.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get order by ID
  Future<Order> getOrderById(String orderId) async {
    final response = await _apiClient.get('${ApiConstants.orders}/$orderId');
    return Order.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Update order status
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final response = await _apiClient.patch(
      '${ApiConstants.orders}/$orderId/status',
      data: {'orderStatus': status.name},
    );

    return Order.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get orders for a branch
  Future<List<Order>> getOrders({
    required String branchId,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.orders,
      queryParameters: {
        'branchId': branchId,
        'page': page,
        'limit': limit,
        if (status != null) 'orderStatus': status.name,  // Use 'orderStatus' per API doc
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );

    // ⚠️ Orders are NESTED under data.orders, NOT directly in data
    // Response format: { success, data: { orders: [...], pagination: {...}, statistics: {...} } }
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final orders = data['orders'] as List<dynamic>? ?? [];
    
    return orders
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Cancel an order
  Future<Order> cancelOrder(String orderId) async {
    return updateOrderStatus(
      orderId: orderId,
      status: OrderStatus.cancelled,
    );
  }

  /// Complete an order
  Future<Order> completeOrder(String orderId) async {
    return updateOrderStatus(
      orderId: orderId,
      status: OrderStatus.completed,
    );
  }
}

