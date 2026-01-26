import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/product.dart';
import 'inventory_api_service.dart';

final menuServiceProvider = Provider<MenuService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final inventoryService = ref.watch(inventoryApiServiceProvider);
  return MenuService(apiClient, inventoryService);
});

/// Service for menu management operations (CRUD for items and categories)
class MenuService {
  final ApiClient _apiClient;
  final InventoryApiService _inventoryService;

  MenuService(this._apiClient, this._inventoryService);

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
    int initialStock = 0,
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
      throw Exception(
        'No data in response - menu item may not have been created',
      );
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

    final createdProduct = Product.fromJson(menuItemData);

    // 🚀 AUTO-CREATE INVENTORY ITEM when trackStock is enabled
    if (trackStock) {
      try {
        print('🔄 Creating inventory item for menu item: $name');
        print('   Restaurant ID: $restaurantId');
        print('   Branch ID: $branchId');
        print('   Track Stock: $trackStock');
        print('   Cost Price: $costPrice');

        if (restaurantId == null || branchId == null) {
          throw Exception(
            'Restaurant ID and Branch ID are required for inventory creation',
          );
        }

        print('🔄 Creating inventory item for menu item: $name');
        print('   Restaurant ID: $restaurantId');
        print('   Branch ID: $branchId');
        print('   Track Stock: $trackStock');
        print('   lowStockThreshold parameter received: $lowStockThreshold');
        print('   Cost Price: ${costPrice ?? 0.0}');

        final createdInventoryItem = await _inventoryService.createInventoryItem(
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          category: 'finished_good', // Menu items are typically finished goods
          unit: unit,
          costPerUnit: costPrice ?? 0.0,
          sellingPrice: basePrice,
          currentStock: initialStock, // Use the provided initial stock
          minStockLevel:
              lowStockThreshold, // ✅ This should be the real value from form
          maxStockLevel: lowStockThreshold * 10, // Default to 10x min level
          status: isActive ? 'active' : 'inactive',
          trackStock: true,
          itemId: createdProduct.id, // Use menu item ID as itemId
          itemType: 'menu_item', // Set proper item type
          restaurantId: restaurantId,
          branchId: branchId,
        );

        print('✅ Auto-created inventory item for menu item: $name');
        print('🔍 Verifying created inventory item threshold...');
        print('   Expected minStockLevel: $lowStockThreshold');
        print('   Actual minStockLevel: ${createdInventoryItem.minStockLevel}');

        // 🛡️ WORKAROUND: If backend returned wrong threshold, update it
        if (createdInventoryItem.minStockLevel != lowStockThreshold) {
          print(
            '⚠️ Backend returned incorrect minStockLevel! Attempting to fix...',
          );
          try {
            await _inventoryService.updateInventoryItem(
              itemId: createdInventoryItem.id,
              name: name,
              description: description,
              sku: sku,
              barcode: barcode,
              category: 'finished_good',
              unit: unit,
              costPerUnit: costPrice ?? 0.0,
              sellingPrice: basePrice,
              minStockLevel: lowStockThreshold, // Force correct value
              maxStockLevel: lowStockThreshold * 10,
              status: isActive ? 'active' : 'inactive',
              trackStock: true,
              menuItemId: createdProduct.id,
            );
            print(
              '✅ Successfully updated minStockLevel to correct value: $lowStockThreshold',
            );
          } catch (updateError) {
            print('❌ Failed to update minStockLevel: $updateError');
            print(
              '   The inventory item was created with minStockLevel: ${createdInventoryItem.minStockLevel}',
            );
          }
        }
      } catch (e) {
        // Don't fail menu creation if inventory creation fails
        // Just log the error
        print('❌ Failed to auto-create inventory item for $name: $e');
        print(
          '   This means the menu item was created but no inventory entry exists.',
        );
        print(
          '   You may need to manually create the inventory entry or check the backend.',
        );
      }
    }

    return createdProduct;
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
    String? restaurantId,
    String? branchId,
  }) async {
    final Map<String, dynamic> data = {};

    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (categoryId != null) data['categoryId'] = categoryId;

    if (basePrice != null ||
        costPrice != null ||
        taxRate != null ||
        taxIncluded != null) {
      data['pricing'] = {};
      if (basePrice != null) data['pricing']['basePrice'] = basePrice;
      if (costPrice != null) data['pricing']['costPrice'] = costPrice;
      if (taxRate != null) data['pricing']['taxRate'] = taxRate;
      if (taxIncluded != null) data['pricing']['taxIncluded'] = taxIncluded;
    }

    if (trackStock != null || lowStockThreshold != null) {
      data['inventory'] = {};
      if (trackStock != null) data['inventory']['trackStock'] = trackStock;
      if (lowStockThreshold != null)
        data['inventory']['lowStockThreshold'] = lowStockThreshold;
    }

    if (isActive != null) data['isActive'] = isActive;
    if (displayOrder != null) data['displayOrder'] = displayOrder;

    final response = await _apiClient.patch(
      '${ApiConstants.menuItems}/$itemId',
      data: data,
    );

    // ⚠️ UPDATE response format: Direct menu item object { _id, name, ... }
    // NOT wrapped in { success, data }
    final updatedProduct = Product.fromJson(response);

    // 🚀 AUTO-CREATE INVENTORY ITEM when trackStock is being enabled
    if (trackStock == true) {
      try {
        // Check if inventory item already exists for this menu item
        // For now, we'll attempt to create and handle duplicates gracefully
        await _inventoryService.createInventoryItem(
          name: updatedProduct.name,
          description: updatedProduct.description,
          sku: updatedProduct.sku,
          barcode: updatedProduct.barcode,
          category: 'finished_good',
          unit: updatedProduct.inventory?.unit ?? 'unit',
          costPerUnit: updatedProduct.pricing.costPrice ?? 0.0,
          sellingPrice: updatedProduct.pricing.basePrice,
          currentStock: 0, // Start with 0 stock
          minStockLevel: updatedProduct.inventory?.lowStockThreshold ?? 10,
          maxStockLevel:
              (updatedProduct.inventory?.lowStockThreshold ?? 10) * 10,
          status: updatedProduct.isActive ? 'active' : 'inactive',
          trackStock: true,
          itemId: updatedProduct.id, // Use menu item ID as itemId
          itemType: 'menu_item', // Required: Type of item
          restaurantId: restaurantId,
          branchId: branchId,
        );

        print(
          '✅ Auto-created inventory item for updated menu item: ${updatedProduct.name}',
        );
      } catch (e) {
        // Handle case where inventory item might already exist
        final errorMessage = e.toString();
        if (errorMessage.contains('duplicate') ||
            errorMessage.contains('exists')) {
          print('ℹ️ Inventory item already exists for: ${updatedProduct.name}');
        } else {
          print(
            '⚠️ Failed to auto-create inventory item for ${updatedProduct.name}: $e',
          );
        }
      }
    }

    return updatedProduct;
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
      data: {'restaurantId': restaurantId, 'items': items},
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

  /// Sync existing menu items with inventory (create inventory items for menu items with trackStock enabled)
  Future<Map<String, String>> syncMenuItemsToInventory(
    List<Product> menuItems, {
    required String restaurantId,
    required String branchId,
  }) async {
    final results = <String, String>{};

    // Separate items that need syncing
    final itemsToSync = <Product>[];
    for (final menuItem in menuItems) {
      if (menuItem.inventory?.trackStock == true) {
        itemsToSync.add(menuItem);
      } else {
        results[menuItem.id] = 'skipped_no_track_stock';
      }
    }

    if (itemsToSync.isEmpty) {
      return results;
    }

    // Prepare inventory item data for bulk creation
    final inventoryItemsData =
        itemsToSync
            .map(
              (menuItem) => {
                'itemId': menuItem.id, // Required: Menu item ID
                'itemType': 'menu_item', // Required: Type of item
                'branchId': branchId, // Required: Branch ID
                'restaurantId': restaurantId, // Restaurant ID
                'name': menuItem.name,
                'category': 'finished_good',
                'unitOfMeasure': {
                  'name': menuItem.inventory?.unit ?? 'unit',
                  'abbreviation': menuItem.inventory?.unit ?? 'unit',
                  'category': 'count',
                },
                'costPerUnit': menuItem.pricing.costPrice ?? 0.0,
                'currentStock': menuItem.inventory?.currentStock ?? 0,
                'minStockLevel': menuItem.inventory?.lowStockThreshold ?? 10,
                'maxStockLevel':
                    (menuItem.inventory?.lowStockThreshold ?? 10) * 10,
                'status': menuItem.isActive ? 'active' : 'inactive',
                'trackStock': true,
                if (menuItem.description != null)
                  'description': menuItem.description,
                if (menuItem.sku != null) 'sku': menuItem.sku,
                if (menuItem.barcode != null) 'barcode': menuItem.barcode,
                if (menuItem.pricing.basePrice > 0)
                  'sellingPrice': menuItem.pricing.basePrice,
              },
            )
            .toList();

    try {
      // Try bulk creation first
      await _inventoryService.createInventoryItems(items: inventoryItemsData);

      // If successful, mark all as success
      for (final menuItem in itemsToSync) {
        results[menuItem.id] = 'success';
      }

      print('✅ Bulk synced ${itemsToSync.length} menu items to inventory');
    } catch (e) {
      // If bulk creation fails, fall back to individual creation
      print('⚠️ Bulk sync failed, trying individual sync: $e');

      for (final menuItem in itemsToSync) {
        try {
          await _inventoryService.createInventoryItem(
            name: menuItem.name,
            description: menuItem.description,
            sku: menuItem.sku,
            barcode: menuItem.barcode,
            category: 'finished_good',
            unit: menuItem.inventory?.unit ?? 'unit',
            costPerUnit: menuItem.pricing.costPrice ?? 0.0,
            sellingPrice: menuItem.pricing.basePrice,
            currentStock: menuItem.inventory?.currentStock ?? 0,
            minStockLevel: menuItem.inventory?.lowStockThreshold ?? 10,
            maxStockLevel: (menuItem.inventory?.lowStockThreshold ?? 10) * 10,
            status: menuItem.isActive ? 'active' : 'inactive',
            trackStock: true,
            itemId: menuItem.id, // Use menu item ID as itemId
            itemType: 'menu_item', // Required: Type of item
            restaurantId: restaurantId,
            branchId: branchId,
          );

          results[menuItem.id] = 'success';
          print('✅ Synced menu item to inventory: ${menuItem.name}');
        } catch (e) {
          final errorMessage = e.toString();
          if (errorMessage.contains('duplicate') ||
              errorMessage.contains('exists') ||
              errorMessage.contains('already')) {
            results[menuItem.id] = 'already_exists';
            print('ℹ️ Inventory item already exists for: ${menuItem.name}');
          } else {
            results[menuItem.id] = 'failed: $errorMessage';
            print('⚠️ Failed to sync menu item ${menuItem.name}: $e');
          }
        }
      }
    }

    return results;
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

  MenuItemImage({required this.imageId, required this.url, this.thumbnailUrl});

  factory MenuItemImage.fromJson(Map<String, dynamic> json) {
    return MenuItemImage(
      imageId: json['imageId'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}
