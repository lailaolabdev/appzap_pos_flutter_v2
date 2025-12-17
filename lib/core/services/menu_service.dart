import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/product.dart';

final menuServiceProvider = Provider<MenuService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MenuService(apiClient);
});

/// Service for menu management operations (CRUD for items and categories)
class MenuService {
  final ApiClient _apiClient;

  MenuService(this._apiClient);

  // ==================== MENU ITEMS ====================

  /// Create a new menu item
  Future<Product> createMenuItem({
    required String restaurantId,
    String? branchId,
    required String categoryId,
    required String name,
    String? description,
    String? itemCode,
    String? barcode,
    String? sku,
    String itemLevel = 'restaurant',
    required double basePrice,
    double? costPrice,
    double taxRate = 0,
    bool taxIncluded = false,
    String currency = 'LAK',
    bool trackStock = true,
    int lowStockThreshold = 10,
    String unit = 'unit',
    bool isActive = true,
    int displayOrder = 0,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.menuItems,
      data: {
        'restaurantId': restaurantId,
        if (branchId != null) 'branchId': branchId,
        'categoryId': categoryId,
        'name': name,
        if (description != null) 'description': description,
        if (itemCode != null) 'itemCode': itemCode,
        if (barcode != null) 'barcode': barcode,
        if (sku != null) 'sku': sku,
        'itemLevel': itemLevel,
        'pricing': {
          'basePrice': basePrice,
          if (costPrice != null) 'costPrice': costPrice,
          'taxRate': taxRate,
          'taxIncluded': taxIncluded,
          'currency': currency,
        },
        'inventory': {
          'trackStock': trackStock,
          'lowStockThreshold': lowStockThreshold,
          'unit': unit,
        },
        'isActive': isActive,
        'displayOrder': displayOrder,
      },
    );

    // ⚠️ CREATE response format: { success, message, data: { menuItem: {...}, inventoryActivation: {...} } }
    // Access nested menuItem
    final data = response['data'];
    if (data == null || data['menuItem'] == null) {
      throw Exception('No data in response - menu item may not have been created');
    }

    final menuItemData = Map<String, dynamic>.from(data['menuItem']);

    // Normalize populated fields to IDs (API returns populated objects)
    // categoryId: { _id: "...", name: "..." } → categoryId: "..."
    if (menuItemData['categoryId'] is Map) {
      menuItemData['categoryId'] = menuItemData['categoryId']['_id'];
    }
    if (menuItemData['recipeId'] is Map) {
      menuItemData['recipeId'] = menuItemData['recipeId']['_id'];
    }
    if (menuItemData['createdBy'] is Map) {
      menuItemData['createdBy'] = menuItemData['createdBy']['_id'];
    }
    if (menuItemData['updatedBy'] is Map) {
      menuItemData['updatedBy'] = menuItemData['updatedBy']['_id'];
    }

    return Product.fromJson(menuItemData);
  }

  /// Update an existing menu item
  Future<Product> updateMenuItem({
    required String itemId,
    String? name,
    String? description,
    String? categoryId,
    double? basePrice,
    double? costPrice,
    double? taxRate,
    bool? taxIncluded,
    bool? trackStock,
    int? lowStockThreshold,
    bool? isActive,
    int? displayOrder,
  }) async {
    final Map<String, dynamic> data = {};

    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (categoryId != null) data['categoryId'] = categoryId;
    
    if (basePrice != null || costPrice != null || taxRate != null || taxIncluded != null) {
      data['pricing'] = {};
      if (basePrice != null) data['pricing']['basePrice'] = basePrice;
      if (costPrice != null) data['pricing']['costPrice'] = costPrice;
      if (taxRate != null) data['pricing']['taxRate'] = taxRate;
      if (taxIncluded != null) data['pricing']['taxIncluded'] = taxIncluded;
    }

    if (trackStock != null || lowStockThreshold != null) {
      data['inventory'] = {};
      if (trackStock != null) data['inventory']['trackStock'] = trackStock;
      if (lowStockThreshold != null) data['inventory']['lowStockThreshold'] = lowStockThreshold;
    }

    if (isActive != null) data['isActive'] = isActive;
    if (displayOrder != null) data['displayOrder'] = displayOrder;

    final response = await _apiClient.patch(
      '${ApiConstants.menuItems}/$itemId',
      data: data,
    );

    // ⚠️ UPDATE response format: Direct menu item object { _id, name, ... }
    // NOT wrapped in { success, data }
    return Product.fromJson(response);
  }

  /// Delete a menu item (soft delete)
  Future<void> deleteMenuItem(String itemId) async {
    await _apiClient.delete('${ApiConstants.menuItems}/$itemId');
  }

  /// Bulk create menu items
  Future<List<Product>> bulkCreateMenuItems({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.menuItems}/bulk',
      data: {
        'restaurantId': restaurantId,
        'items': items,
      },
    );

    final itemsList = response['data']['items'] as List<dynamic>? ?? [];
    return itemsList
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Upload menu item image
  Future<MenuItemImage> uploadMenuItemImage({
    required String itemId,
    required String imagePath,
  }) async {
    // TODO: Implement multipart/form-data upload
    // This requires FormData from dio package
    throw UnimplementedError('Image upload not implemented yet');
  }

  // ==================== CATEGORIES ====================

  /// Create a new category
  Future<Category> createCategory({
    required String restaurantId,
    required String name,
    String? description,
    int displayOrder = 0,
    bool isActive = true,
    String? color,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.menuCategories,
      data: {
        'restaurantId': restaurantId,
        'name': name,
        if (description != null) 'description': description,
        'displayOrder': displayOrder,
        'isActive': isActive,
        if (color != null) 'color': color,
      },
    );

    // ⚠️ Category endpoints return direct object, NOT wrapped in { success, data }
    // Response format: { _id, name, description, ... }
    return Category.fromJson(response);
  }

  /// Update an existing category
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    int? displayOrder,
    bool? isActive,
    String? color,
  }) async {
    final Map<String, dynamic> data = {};

    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (isActive != null) data['isActive'] = isActive;
    if (color != null) data['color'] = color;

    final response = await _apiClient.patch(
      '${ApiConstants.menuCategories}/$categoryId',
      data: data,
    );

    // ⚠️ Category endpoints return direct object, NOT wrapped in { success, data }
    // Response format: { _id, name, description, ... }
    return Category.fromJson(response);
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _apiClient.delete('${ApiConstants.menuCategories}/$categoryId');
  }

  /// Get a single category by ID
  Future<Category> getCategoryById(String categoryId) async {
    final response = await _apiClient.get(
      '${ApiConstants.menuCategories}/$categoryId',
    );

    // ⚠️ Category endpoints return direct object, NOT wrapped in { success, data }
    // Response format: { _id, name, description, ... }
    return Category.fromJson(response);
  }
}

/// Menu item image model
class MenuItemImage {
  final String imageId;
  final String url;
  final String? thumbnailUrl;

  MenuItemImage({
    required this.imageId,
    required this.url,
    this.thumbnailUrl,
  });

  factory MenuItemImage.fromJson(Map<String, dynamic> json) {
    return MenuItemImage(
      imageId: json['imageId'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

