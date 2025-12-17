import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/inventory.dart';

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryService(apiClient);
});

/// Service for inventory management operations (USP #2)
class InventoryService {
  final ApiClient _apiClient;

  InventoryService(this._apiClient);

  /// Get all inventory items for a branch
  Future<List<InventoryItem>> getInventoryItems({
    required String branchId,
    String? search,
    String? categoryId,
    String? status, // active, low_stock, out_of_stock
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.inventoryItems,
      queryParameters: {
        'branchId': branchId,
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'categoryId': categoryId,
        if (status != null) 'status': status,
      },
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => InventoryItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get inventory item by ID
  Future<InventoryItem> getInventoryItemById(String itemId) async {
    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/$itemId',
    );

    return InventoryItem.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get low stock items
  Future<List<InventoryItem>> getLowStockItems({
    required String branchId,
    int page = 1,
    int limit = 100,
  }) async {
    return await getInventoryItems(
      branchId: branchId,
      status: 'low_stock',
      page: page,
      limit: limit,
    );
  }

  /// Get out of stock items
  Future<List<InventoryItem>> getOutOfStockItems({
    required String branchId,
    int page = 1,
    int limit = 100,
  }) async {
    return await getInventoryItems(
      branchId: branchId,
      status: 'out_of_stock',
      page: page,
      limit: limit,
    );
  }

  /// Adjust stock levels
  Future<StockAdjustmentResult> adjustStock(
    StockAdjustment adjustment,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.stockAdjust,
      data: adjustment.toJson(),
    );

    return StockAdjustmentResult.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  /// Add stock (purchase, return)
  Future<StockAdjustmentResult> addStock({
    required String inventoryItemId,
    required String branchId,
    required int quantity,
    required String reason,
    String? notes,
    double? costPrice,
  }) async {
    return await adjustStock(
      StockAdjustment(
        inventoryItemId: inventoryItemId,
        branchId: branchId,
        operation: StockOperation.add,
        quantity: quantity,
        reason: reason,
        notes: notes,
        costPrice: costPrice,
      ),
    );
  }

  /// Remove stock (damage, theft, waste)
  Future<StockAdjustmentResult> removeStock({
    required String inventoryItemId,
    required String branchId,
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    return await adjustStock(
      StockAdjustment(
        inventoryItemId: inventoryItemId,
        branchId: branchId,
        operation: StockOperation.remove,
        quantity: quantity,
        reason: reason,
        notes: notes,
      ),
    );
  }

  /// Set exact stock level (physical count)
  Future<StockAdjustmentResult> setStock({
    required String inventoryItemId,
    required String branchId,
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    return await adjustStock(
      StockAdjustment(
        inventoryItemId: inventoryItemId,
        branchId: branchId,
        operation: StockOperation.set,
        quantity: quantity,
        reason: reason,
        notes: notes,
      ),
    );
  }

  /// Get inventory alerts (low stock, out of stock, expiring soon)
  Future<List<InventoryAlert>> getInventoryAlerts({
    required String branchId,
    String? alertType, // low_stock, out_of_stock, expiring_soon
  }) async {
    final response = await _apiClient.get(
      ApiConstants.inventoryAlerts,
      queryParameters: {
        'branchId': branchId,
        if (alertType != null) 'alertType': alertType,
      },
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => InventoryAlert.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create purchase order
  Future<PurchaseOrder> createPurchaseOrder({
    required String branchId,
    required String supplierId,
    required List<PurchaseOrderItem> items,
    String? expectedDeliveryDate,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.purchaseOrders,
      data: {
        'branchId': branchId,
        'supplierId': supplierId,
        'items': items.map((item) => item.toJson()).toList(),
        if (expectedDeliveryDate != null)
          'expectedDeliveryDate': expectedDeliveryDate,
        if (notes != null) 'notes': notes,
      },
    );

    return PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get purchase orders
  Future<List<PurchaseOrder>> getPurchaseOrders({
    required String branchId,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.purchaseOrders,
      queryParameters: {
        'branchId': branchId,
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get purchase order by ID
  Future<PurchaseOrder> getPurchaseOrderById(String orderId) async {
    final response = await _apiClient.get(
      '${ApiConstants.purchaseOrders}/$orderId',
    );

    return PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Update purchase order status
  Future<PurchaseOrder> updatePurchaseOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final response = await _apiClient.patch(
      '${ApiConstants.purchaseOrders}/$orderId/status',
      data: {'status': status},
    );

    return PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Receive purchase order (update stock from received PO)
  Future<PurchaseOrder> receivePurchaseOrder({
    required String orderId,
    required List<Map<String, dynamic>> receivedItems,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.purchaseOrders}/$orderId/receive',
      data: {'items': receivedItems},
    );

    return PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get inventory valuation
  Future<InventoryValuation> getInventoryValuation({
    required String branchId,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.inventoryValuation,
      queryParameters: {'branchId': branchId},
    );

    return InventoryValuation.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  /// Get stock movement history
  Future<List<dynamic>> getStockMovements({
    required String branchId,
    String? inventoryItemId,
    String? operation,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      '/inventory/stock-movements',
      queryParameters: {
        'branchId': branchId,
        'page': page,
        'limit': limit,
        if (inventoryItemId != null) 'inventoryItemId': inventoryItemId,
        if (operation != null) 'operation': operation,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );

    return response['data'] as List<dynamic>? ?? [];
  }

  /// Export inventory to CSV
  Future<String> exportInventory({
    required String branchId,
  }) async {
    final response = await _apiClient.get(
      '/inventory/export',
      queryParameters: {'branchId': branchId},
    );

    return response['data']['url'] as String? ?? '';
  }
}

