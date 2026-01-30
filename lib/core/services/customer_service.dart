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
    return await getCustomers(restaurantId: restaurantId, search: phone);
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
        'firstName': name,
        'phoneNumber': phone,
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
        if (name != null) 'firstName': name,
        if (phone != null) 'phoneNumber': phone,
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
  Future<CustomerPoints> getCustomerPoints(
    String customerId, {
    String? restaurantId,
  }) async {
    final url = ApiConstants.customerAvailablePoints.replaceAll(
      '{customerId}',
      customerId,
    );
    
    final queryParameters = <String, dynamic>{};
    if (restaurantId != null) {
      queryParameters['restaurantId'] = restaurantId;
    }
    
    try {
      final response = await _apiClient.get(
        url,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      return CustomerPoints.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      // If the loyalty points endpoint fails, return default points based on customer data
      // This is a fallback for when the server endpoint isn't implemented
      print('⚠️ Loyalty points endpoint failed: $e');
      print('🔄 Using fallback: creating CustomerPoints from customer data');
      
      // Try to get the customer to extract loyalty points
      try {
        final customers = await getCustomers(
          restaurantId: restaurantId ?? '',
          search: customerId,
        );
        
        final customer = customers.isNotEmpty ? customers.first : null;
        if (customer != null) {
          return CustomerPoints(
            customerId: customer.id,
            currentPoints: customer.loyaltyPoints,
            tier: customer.tier,
            nextTier: _getNextTier(customer.tier),
            pointsToNextTier: _getPointsToNextTier(customer.tier, customer.loyaltyPoints),
            history: [], // Empty history as fallback
          );
        }
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
      }
      
      // Final fallback - return empty points
      return CustomerPoints(
        customerId: customerId,
        currentPoints: 0,
        tier: LoyaltyTier.bronze,
        nextTier: LoyaltyTier.silver,
        pointsToNextTier: 100,
        history: [],
      );
    }
  }

  /// Get next loyalty tier
  LoyaltyTier? _getNextTier(LoyaltyTier currentTier) {
    switch (currentTier) {
      case LoyaltyTier.bronze:
        return LoyaltyTier.silver;
      case LoyaltyTier.silver:
        return LoyaltyTier.gold;
      case LoyaltyTier.gold:
        return LoyaltyTier.platinum;
      case LoyaltyTier.platinum:
        return null; // Already at highest tier
    }
  }

  /// Calculate points needed for next tier
  int _getPointsToNextTier(LoyaltyTier currentTier, int currentPoints) {
    final thresholds = {
      LoyaltyTier.bronze: 100,    // Points needed for Silver
      LoyaltyTier.silver: 500,   // Points needed for Gold  
      LoyaltyTier.gold: 1000,    // Points needed for Platinum
      LoyaltyTier.platinum: 0,   // Already at highest tier
    };
    
    final threshold = thresholds[currentTier] ?? 0;
    return threshold > currentPoints ? threshold - currentPoints : 0;
  }

  /// Redeem loyalty points
  Future<Map<String, dynamic>> redeemPoints({
    required String customerId,
    required int points,
    required String orderId,
  }) async {
    final url = ApiConstants.redeemPoints.replaceAll(
      '{customerId}',
      customerId,
    );
    final response = await _apiClient.post(
      url,
      data: {'points': points, 'orderId': orderId},
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
      data: {'points': points, 'reason': reason},
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
      queryParameters: {'page': page, 'limit': limit},
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
      queryParameters: {'restaurantId': restaurantId, 'limit': limit},
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
