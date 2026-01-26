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
    print('\n📡 === PRODUCTS API REQUEST ===');
    print('   Restaurant ID: $restaurantId');
    print('   Branch ID: $branchId');
    print('   Endpoint: ${ApiConstants.menuItems}');
    
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
    
    print('   Query params: $queryParams');
    
    final response = await _apiClient.get(
      ApiConstants.menuItems,
      queryParameters: queryParams,
    );
    
    print('📥 API Response received:');
    print('   Response type: ${response.runtimeType}');
    print('   Data type: ${response['data']?.runtimeType}');
    
    final data = response['data'] as List<dynamic>? ?? [];
    print('   Items count: ${data.length}');
    
    if (data.isNotEmpty) {
      print('   First item sample:');
      final firstItem = data.first as Map<String, dynamic>;
      print('      - name: ${firstItem['name']}');
      print('      - has inventory: ${firstItem.containsKey('inventory')}');
      print('      - has currentStock: ${firstItem.containsKey('currentStock')}');
      if (firstItem.containsKey('inventory')) {
        print('      - inventory: ${firstItem['inventory']}');
      }
      if (firstItem.containsKey('currentStock')) {
        print('      - currentStock: ${firstItem['currentStock']}');
      }
    }
    
    final products = data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
        
    print('✅ Parsed ${products.length} products with inventory data');
    print('=== END PRODUCTS API REQUEST ===\n');
    
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

