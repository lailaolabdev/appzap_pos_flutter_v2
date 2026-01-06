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
      'currentStock': currentStock,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'status': status,
      'trackStock': trackStock,
    };

    if (description != null) data['description'] = description;
    if (sku != null) data['sku'] = sku;
    if (barcode != null) data['barcode'] = barcode;
    if (sellingPrice != null) data['sellingPrice'] = sellingPrice;

    final response = await _apiClient.post(
      ApiConstants.inventoryItems,
      data: data,
    );

    return InventoryItem.fromJson(response['data']);
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

    if (itemId != null) {
      queryParams['itemId'] = itemId;
    }

    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/transactions',
      queryParameters: queryParams,
    );

    final List<dynamic> transactions =
        response['data']['transactions'] ?? response['data'] ?? [];
    return transactions.map((t) => StockTransaction.fromJson(t)).toList();
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
      id: json['id'] as String,
      inventoryItemId: json['inventoryItemId'] as String,
      inventoryItemName: json['inventoryItemName'] as String? ?? '',
      operation: json['operation'] as String,
      quantityBefore: (json['quantityBefore'] as num).toInt(),
      quantityChanged: (json['quantityChanged'] as num).toInt(),
      quantityAfter: (json['quantityAfter'] as num).toInt(),
      reason: json['reason'] as String,
      notes: json['notes'] as String?,
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      referenceId: json['referenceId'] as String?,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalTransactions: (json['totalTransactions'] as num).toInt(),
      totalValueChange: (json['totalValueChange'] as num).toDouble(),
      transactionsByType: Map<String, int>.from(
        json['transactionsByType'] ?? {},
      ),
      topMovingItems:
          (json['topMovingItems'] as List<dynamic>?)
              ?.map((item) => TopMovingItem.fromJson(item))
              .toList() ??
          [],
      generatedAt: DateTime.parse(json['generatedAt'] as String),
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
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      totalMovement: (json['totalMovement'] as num).toInt(),
      totalValue: (json['totalValue'] as num).toDouble(),
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
      totalProcessed: (json['totalProcessed'] as num).toInt(),
      successCount: (json['successCount'] as num).toInt(),
      failureCount: (json['failureCount'] as num).toInt(),
      errors: List<String>.from(json['errors'] ?? []),
      importedAt: DateTime.parse(json['importedAt'] as String),
    );
  }
}
