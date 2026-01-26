import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/inventory.dart';

final inventoryApiServiceProvider = Provider<InventoryApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryApiService(apiClient);
});

class InventoryApiService {
  final ApiClient _apiClient;

  InventoryApiService(this._apiClient);

  /// Get all inventory items
  Future<List<InventoryItem>> getInventoryItems({
    String? search,
    String? category,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiConstants.inventoryItems,
      queryParameters: queryParams,
    );

    final List<dynamic> items =
        response['data']['items'] ?? response['data'] ?? [];
    return items.map((item) => InventoryItem.fromJson(item)).toList();
  }

  /// Create new inventory item
  Future<InventoryItem> createInventoryItem({
    required String name,
    String? description,
    String? sku,
    String? barcode,
    required String category,
    required String unit,
    required double costPerUnit,
    double? sellingPrice,
    required int currentStock,
    required int minStockLevel,
    required int maxStockLevel,
    String status = 'active',
    bool trackStock = true,
    String? itemId,
    String? itemType,
    String? restaurantId,
    String? branchId,
  }) async {
    final itemData = {
      'name': name,
      'category': category,
      'unitOfMeasure': {
        'name': unit,
        'abbreviation': unit,
        'category': 'count',
      },
      'costPerUnit': costPerUnit,
      'currentStock': currentStock,
      'minStockLevel': minStockLevel, // ✅ This should be the real value
      'maxStockLevel': maxStockLevel,
      'status': status,
      'trackStock': trackStock,
      'itemType':
          itemType ?? 'product', // Use parameter or default to 'product'
    };

    print('📦 Inventory API Service - Creating item with data:');
    print('   - name: $name');
    print('   - minStockLevel: $minStockLevel (this should be the user input)');
    print('   - currentStock: $currentStock');
    print('   - maxStockLevel: $maxStockLevel');

    // Add required fields if provided
    if (itemId != null) itemData['itemId'] = itemId;
    if (restaurantId != null) itemData['restaurantId'] = restaurantId;
    if (branchId != null) itemData['branchId'] = branchId;

    // Add optional fields
    if (description != null) itemData['description'] = description;
    if (sku != null) itemData['sku'] = sku;
    if (barcode != null) itemData['barcode'] = barcode;
    if (sellingPrice != null) itemData['sellingPrice'] = sellingPrice;

    // Wrap in items array as expected by the backend
    final data = {
      'items': [itemData],
    };

    print('🚨 === CRITICAL DEBUG: SENDING TO BACKEND ===');
    print('🚨 Full request data being sent: $data');
    print('🚨 itemData[minStockLevel] = ${itemData['minStockLevel']}');
    print('🚨 This value MUST be $minStockLevel');

    final response = await _apiClient.post(
      ApiConstants.inventoryItems,
      data: data,
    );

    print('🚨 === CRITICAL DEBUG: BACKEND RESPONSE ===');
    print('🚨 Full response: $response');

    // Extract the first (and only) item from the response
    final responseData = response['data'];
    if (responseData is Map<String, dynamic> && responseData['items'] is List) {
      final items = responseData['items'] as List;
      if (items.isNotEmpty) {
        final itemJson = items[0] as Map<String, dynamic>;
        print('🚨 Backend returned item: $itemJson');
        print(
          '🚨 Backend returned minStockLevel: ${itemJson['minStockLevel']}',
        );
        print('🚨 Expected minStockLevel: $minStockLevel');
        if (itemJson['minStockLevel'] != minStockLevel) {
          print('🚨 ❌❌❌ BACKEND BUG DETECTED! ❌❌❌');
          print(
            '🚨 Backend changed $minStockLevel to ${itemJson['minStockLevel']}',
          );
          print(
            '🚨 This is a BACKEND ISSUE - the backend is not saving the correct value!',
          );
        }
        return InventoryItem.fromJson(itemJson);
      }
    }

    // Fallback for direct item response format
    print('🚨 Using fallback response format');
    final itemJson = response['data'] as Map<String, dynamic>;
    print('🚨 Backend returned item: $itemJson');
    print('🚨 Backend returned minStockLevel: ${itemJson['minStockLevel']}');
    return InventoryItem.fromJson(itemJson);
  }

  /// Create multiple inventory items at once
  Future<List<InventoryItem>> createInventoryItems({
    required List<Map<String, dynamic>> items,
  }) async {
    final data = {'items': items};

    final response = await _apiClient.post(
      ApiConstants.inventoryItems,
      data: data,
    );

    // Handle different response formats
    final responseData = response['data'];
    if (responseData is Map<String, dynamic> && responseData['items'] is List) {
      final itemsList = responseData['items'] as List;
      return itemsList
          .map((item) => InventoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Fallback for direct list response
    if (responseData is List) {
      return responseData
          .map((item) => InventoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Update inventory item
  Future<InventoryItem> updateInventoryItem({
    required String itemId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    required String category,
    required String unit,
    required double costPerUnit,
    double? sellingPrice,
    required int minStockLevel,
    required int maxStockLevel,
    String status = 'active',
    bool trackStock = true,
    String? menuItemId, // ✅ Add menu item ID parameter
  }) async {
    final data = {
      'name': name,
      'category': category,
      'unitOfMeasure': {
        'name': unit,
        'abbreviation': unit,
        'category': 'count',
      },
      'costPerUnit': costPerUnit,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'status': status,
      'trackStock': trackStock,
    };

    if (description != null) data['description'] = description;
    if (sku != null) data['sku'] = sku;
    if (barcode != null) data['barcode'] = barcode;
    if (sellingPrice != null) data['sellingPrice'] = sellingPrice;
    if (menuItemId != null)
      data['itemId'] = menuItemId; // ✅ Include menu item ID

    final response = await _apiClient.put(
      '${ApiConstants.inventoryItems}/$itemId',
      data: data,
    );

    return InventoryItem.fromJson(response['data']);
  }

  /// Delete inventory item
  Future<bool> deleteInventoryItem(String itemId) async {
    await _apiClient.delete('${ApiConstants.inventoryItems}/$itemId');
    return true;
  }

  /// Get single inventory item
  Future<InventoryItem> getInventoryItem(String itemId) async {
    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/$itemId',
    );
    return InventoryItem.fromJson(response['data']);
  }

  /// Adjust stock
  Future<void> adjustStock({
    required String itemId,
    required StockOperation operation,
    required int quantity,
    required String reason,
    String? notes,
    double? costPrice,
    String? referenceId,
  }) async {
    final data = {
      'operation': operation.name.toUpperCase(),
      'quantity': quantity,
      'reason': reason,
    };

    if (notes != null) data['notes'] = notes;
    if (costPrice != null) data['costPrice'] = costPrice;
    if (referenceId != null) data['referenceId'] = referenceId;

    await _apiClient.post(
      '${ApiConstants.inventoryItems}/$itemId/adjust-stock',
      data: data,
    );
  }

  /// Get stock history
  Future<List<StockTransaction>> getStockHistory({
    String? itemId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (itemId != null && itemId.isNotEmpty) {
      queryParams['itemId'] = itemId;
    }

    final response = await _apiClient.get(
      ApiConstants.inventoryTransactions,
      queryParameters: queryParams,
    );

    // Safely access the response data
    final data = response['data'];
    if (data == null) return [];

    final List<dynamic> transactions;
    if (data is Map<String, dynamic>) {
      transactions = data['transactions'] as List<dynamic>? ?? [];
    } else if (data is List<dynamic>) {
      transactions = data;
    } else {
      return [];
    }

    return transactions
        .map(
          (t) =>
              t is Map<String, dynamic> ? StockTransaction.fromJson(t) : null,
        )
        .where((t) => t != null)
        .cast<StockTransaction>()
        .toList();
  }

  /// Get inventory categories
  Future<List<InventoryCategory>> getCategories() async {
    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/categories',
    );
    final List<dynamic> categories = response['data'] ?? [];
    return categories.map((c) => InventoryCategory.fromJson(c)).toList();
  }

  /// Create inventory category
  Future<InventoryCategory> createCategory({
    required String name,
    String? description,
    String? color,
  }) async {
    final data = {'name': name};

    if (description != null) data['description'] = description;
    if (color != null) data['color'] = color;

    final response = await _apiClient.post(
      '${ApiConstants.inventoryItems}/categories',
      data: data,
    );

    return InventoryCategory.fromJson(response['data']);
  }

  /// Get low stock alerts
  Future<List<InventoryAlert>> getLowStockAlerts() async {
    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/alerts',
    );
    final List<dynamic> alerts = response['data'] ?? [];
    return alerts.map((a) => InventoryAlert.fromJson(a)).toList();
  }

  /// Get inventory valuation
  Future<InventoryValuation> getInventoryValuation() async {
    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/valuation',
    );
    return InventoryValuation.fromJson(response['data']);
  }

  /// Get inventory reports
  Future<InventoryReport> getInventoryReport({
    required DateTime startDate,
    required DateTime endDate,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };

    if (category != null) {
      queryParams['category'] = category;
    }

    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/reports',
      queryParameters: queryParams,
    );

    return InventoryReport.fromJson(response['data']);
  }

  /// Search inventory items with barcode
  Future<InventoryItem?> searchByBarcode(String barcode) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.inventoryItems}/search/barcode',
        queryParameters: {'barcode': barcode},
      );

      if (response['data'] != null) {
        return InventoryItem.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Bulk import inventory items
  Future<BulkImportResult> bulkImportItems(
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _apiClient.post(
      '${ApiConstants.inventoryItems}/bulk-import',
      data: {'items': items},
    );

    return BulkImportResult.fromJson(response['data']);
  }

  /// Export inventory data
  Future<String> exportInventory({
    String format = 'csv',
    String? category,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{'format': format};

    if (category != null) queryParams['category'] = category;
    if (status != null) queryParams['status'] = status;

    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/export',
      queryParameters: queryParams,
    );

    return response['data']['downloadUrl'];
  }
}

/// Stock Transaction Model
class StockTransaction {
  final String id;
  final String inventoryItemId;
  final String inventoryItemName;
  final String operation;
  final int quantityBefore;
  final int quantityChanged;
  final int quantityAfter;
  final String reason;
  final String? notes;
  final double? costPrice;
  final String? referenceId;
  final String userId;
  final String userName;
  final DateTime createdAt;

  const StockTransaction({
    required this.id,
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.operation,
    required this.quantityBefore,
    required this.quantityChanged,
    required this.quantityAfter,
    required this.reason,
    this.notes,
    this.costPrice,
    this.referenceId,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id']?.toString() ?? '',
      inventoryItemId: json['inventoryItemId']?.toString() ?? '',
      inventoryItemName: json['inventoryItemName']?.toString() ?? '',
      operation: json['operation']?.toString() ?? '',
      quantityBefore: (json['quantityBefore'] as num?)?.toInt() ?? 0,
      quantityChanged: (json['quantityChanged'] as num?)?.toInt() ?? 0,
      quantityAfter: (json['quantityAfter'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString() ?? '',
      notes: json['notes']?.toString(),
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      referenceId: json['referenceId']?.toString(),
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Inventory Category Model
class InventoryCategory {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final int itemCount;
  final DateTime createdAt;

  const InventoryCategory({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.itemCount = 0,
    required this.createdAt,
  });

  factory InventoryCategory.fromJson(Map<String, dynamic> json) {
    return InventoryCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      color: json['color']?.toString(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Category Valuation Model
class CategoryValuation {
  final double value;
  final int items;
  final double percentage;

  const CategoryValuation({
    required this.value,
    required this.items,
    required this.percentage,
  });

  factory CategoryValuation.fromJson(Map<String, dynamic> json) {
    return CategoryValuation(
      value: (json['value'] as num).toDouble(),
      items: (json['items'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

/// Inventory Report Model
class InventoryReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalTransactions;
  final double totalValueChange;
  final Map<String, int> transactionsByType;
  final List<TopMovingItem> topMovingItems;
  final DateTime generatedAt;

  const InventoryReport({
    required this.startDate,
    required this.endDate,
    required this.totalTransactions,
    required this.totalValueChange,
    required this.transactionsByType,
    required this.topMovingItems,
    required this.generatedAt,
  });

  factory InventoryReport.fromJson(Map<String, dynamic> json) {
    return InventoryReport(
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now(),
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      totalValueChange: (json['totalValueChange'] as num?)?.toDouble() ?? 0.0,
      transactionsByType: Map<String, int>.from(
        json['transactionsByType'] ?? {},
      ),
      topMovingItems:
          (json['topMovingItems'] as List<dynamic>?)
              ?.map((item) => TopMovingItem.fromJson(item))
              .toList() ??
          [],
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Top Moving Item Model
class TopMovingItem {
  final String itemId;
  final String itemName;
  final int totalMovement;
  final double totalValue;

  const TopMovingItem({
    required this.itemId,
    required this.itemName,
    required this.totalMovement,
    required this.totalValue,
  });

  factory TopMovingItem.fromJson(Map<String, dynamic> json) {
    return TopMovingItem(
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      totalMovement: (json['totalMovement'] as num?)?.toInt() ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Bulk Import Result Model
class BulkImportResult {
  final int totalProcessed;
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final DateTime importedAt;

  const BulkImportResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failureCount,
    required this.errors,
    required this.importedAt,
  });

  factory BulkImportResult.fromJson(Map<String, dynamic> json) {
    return BulkImportResult(
      totalProcessed: (json['totalProcessed'] as num?)?.toInt() ?? 0,
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      failureCount: (json['failureCount'] as num?)?.toInt() ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
      importedAt:
          DateTime.tryParse(json['importedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
