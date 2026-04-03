import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/product.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductService(apiClient);
});

/// Service for product and category operations
class ProductService {
  final ApiClient _apiClient;

  ProductService(this._apiClient);

  /// Get all products for a branch
  Future<List<Product>> getProducts({
    required String restaurantId,
    String? branchId,
    String? categoryId,
    String? search,
    bool isActive = true,
    int page = 1,
    int limit = 500,
  }) async {
    
    final queryParams = {
      'restaurantId': restaurantId,
      if (branchId != null) 'branchId': branchId, // ✅ CRITICAL: Include branchId
      'isActive': isActive,
      'page': page,
      'limit': limit,
      'includeInventory': true, // ✅ Request inventory data
      if (categoryId != null) 'categoryId': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    
    
    final response = await _apiClient.get(
      ApiConstants.menuItems,
      queryParameters: queryParams,
    );
    
    
    final data = response['data'] as List<dynamic>? ?? [];
    
    final products = data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
        
    
    return products;
  }

  /// Get product by ID
  Future<Product> getProductById(String itemId) async {
    final response = await _apiClient.get('${ApiConstants.menuItems}/$itemId');
    return Product.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Search product by barcode
  Future<Product?> getProductByBarcode({
    required String restaurantId,
    required String branchId,
    required String barcode,
  }) async {
    final products = await getProducts(
      restaurantId: restaurantId,
      branchId: branchId,
      search: barcode,
    );

    // Find exact barcode match
    return products.cast<Product?>().firstWhere(
          (p) => p?.barcode == barcode,
          orElse: () => null,
        );
  }

  /// Get all categories for a restaurant
  Future<List<Category>> getCategories({
    required String restaurantId,
    bool isActive = true,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.menuCategories,
      queryParameters: {
        'restaurantId': restaurantId,
        'isActive': isActive,
      },
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

