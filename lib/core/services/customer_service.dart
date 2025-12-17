import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/customer.dart';

final customerServiceProvider = Provider<CustomerService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerService(apiClient);
});

/// Service for customer and loyalty operations (USP #3)
class CustomerService {
  final ApiClient _apiClient;

  CustomerService(this._apiClient);

  /// Get all customers for a restaurant
  Future<List<Customer>> getCustomers({
    required String restaurantId,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.customers,
      queryParameters: {
        'restaurantId': restaurantId,
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => Customer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get customer by ID
  Future<Customer> getCustomerById(String customerId) async {
    final response = await _apiClient.get(
      '${ApiConstants.customers}/$customerId',
    );

    return Customer.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Search customers by phone
  Future<List<Customer>> searchByPhone({
    required String restaurantId,
    required String phone,
  }) async {
    return await getCustomers(
      restaurantId: restaurantId,
      search: phone,
    );
  }

  /// Create a new customer
  Future<Customer> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? dateOfBirth,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.customers,
      data: {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      },
    );

    return Customer.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Update customer information
  Future<Customer> updateCustomer({
    required String customerId,
    String? name,
    String? phone,
    String? email,
    String? dateOfBirth,
  }) async {
    final response = await _apiClient.patch(
      '${ApiConstants.customers}/$customerId',
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      },
    );

    return Customer.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Delete customer
  Future<void> deleteCustomer(String customerId) async {
    await _apiClient.delete('${ApiConstants.customers}/$customerId');
  }

  /// Get customer loyalty points and history
  Future<CustomerPoints> getCustomerPoints(String customerId) async {
    final url = ApiConstants.customerPoints.replaceAll('{customerId}', customerId);
    final response = await _apiClient.get(url);

    return CustomerPoints.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Redeem loyalty points
  Future<Map<String, dynamic>> redeemPoints({
    required String customerId,
    required int points,
    required String orderId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.redeemPoints,
      data: {
        'customerId': customerId,
        'points': points,
        'orderId': orderId,
      },
    );

    return response['data'] as Map<String, dynamic>;
  }

  /// Add loyalty points (manual adjustment)
  Future<CustomerPoints> addPoints({
    required String customerId,
    required int points,
    required String reason,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.customers}/$customerId/points/add',
      data: {
        'points': points,
        'reason': reason,
      },
    );

    return CustomerPoints.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get customer purchase history
  Future<List<dynamic>> getCustomerOrders({
    required String customerId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.customers}/$customerId/orders',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    return response['data'] as List<dynamic>? ?? [];
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    final response = await _apiClient.get(
      '${ApiConstants.customers}/$customerId/stats',
    );

    return response['data'] as Map<String, dynamic>;
  }

  /// Get top customers by spending
  Future<List<Customer>> getTopCustomers({
    required String restaurantId,
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.customers}/top',
      queryParameters: {
        'restaurantId': restaurantId,
        'limit': limit,
      },
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => Customer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get loyalty program summary
  Future<Map<String, dynamic>> getLoyaltyProgramSummary(
    String restaurantId,
  ) async {
    final response = await _apiClient.get(
      '/crm/loyalty-program/summary',
      queryParameters: {'restaurantId': restaurantId},
    );

    return response['data'] as Map<String, dynamic>;
  }
}

