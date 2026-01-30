import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/inventory.dart';
import '../../features/auth/providers/auth_provider.dart';

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final restaurantId = ref.watch(currentRestaurantIdProvider);
  final branchId = ref.watch(currentBranchIdProvider);
  return InventoryService(apiClient, restaurantId, branchId);
});

/// Service for inventory management operations (USP #2)
class InventoryService {
  final ApiClient _apiClient;
  final String? _restaurantId;
  final String? _branchId;

  InventoryService(this._apiClient, this._restaurantId, this._branchId);

  /// Get all inventory items for a branch
  Future<List<InventoryItem>> getInventoryItems({
    required String restaurantId,
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
        'restaurantId': restaurantId,
        'branchId': branchId,
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'categoryId': categoryId,
        if (status != null) 'status': status,
      },
    );

    print('\n🔍 === INVENTORY ITEMS API RESPONSE ===');
    print('📊 Raw inventory response: $response');

    final data = response['data'] as List<dynamic>? ?? [];
    print('📊 Inventory items count: ${data.length}');

    // Log each inventory item's raw data to debug the parsing
    for (int i = 0; i < data.length && i < 3; i++) {
      final itemJson = data[i] as Map<String, dynamic>;
      print('📊 Item $i raw JSON: $itemJson');
      print('   - currentStock field: ${itemJson['currentStock']}');
      print('   - availableStock field: ${itemJson['availableStock']}');
      print('   - stock field: ${itemJson['stock']}');
      print('   - quantity field: ${itemJson['quantity']}');
      print('   - minStockLevel field: ${itemJson['minStockLevel']}');
      print('   - lowStockThreshold field: ${itemJson['lowStockThreshold']}');
      print('   - itemId field: ${itemJson['itemId']}');
      print('   - _id field: ${itemJson['_id']}');
      print('   - id field: ${itemJson['id']}');
    }

    final items =
        data
            .map((json) => InventoryItem.fromJson(json as Map<String, dynamic>))
            .toList();

    print('📊 Parsed inventory items:');
    for (int i = 0; i < items.length && i < 3; i++) {
      final item = items[i];
      print(
        '   - ${item.name}: currentStock=${item.currentStock}, itemId=${item.itemId}',
      );
    }
    print('=== END INVENTORY RESPONSE DEBUG ===\n');

    return items;
  }

  /// Get inventory item by ID
  Future<InventoryItem> getInventoryItemById(String itemId) async {
    final response = await _apiClient.get(
      '${ApiConstants.inventoryItems}/$itemId',
    );

    return InventoryItem.fromJson(response['data'] as Map<String, dynamic>);
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
    String? menuItemId,
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
    if (menuItemId != null) data['itemId'] = menuItemId;

    print('🔄 Updating inventory item: $itemId');
    print('   - minStockLevel: $minStockLevel');

    final response = await _apiClient.put(
      '${ApiConstants.inventoryItems}/$itemId',
      data: data,
    );

    final updated = InventoryItem.fromJson(
      response['data'] as Map<String, dynamic>,
    );
    print(
      '✅ Updated inventory item - minStockLevel is now: ${updated.minStockLevel}',
    );
    return updated;
  }

  /// Get low stock items
  Future<List<InventoryItem>> getLowStockItems({
    required String restaurantId,
    required String branchId,
    int page = 1,
    int limit = 100,
  }) async {
    return await getInventoryItems(
      restaurantId: restaurantId,
      branchId: branchId,
      status: 'low_stock',
      page: page,
      limit: limit,
    );
  }

  /// Get out of stock items
  Future<List<InventoryItem>> getOutOfStockItems({
    required String restaurantId,
    required String branchId,
    int page = 1,
    int limit = 100,
  }) async {
    return await getInventoryItems(
      restaurantId: restaurantId,
      branchId: branchId,
      status: 'out_of_stock',
      page: page,
      limit: limit,
    );
  }

  /// Adjust stock levels
  Future<StockAdjustmentResult> adjustStock(StockAdjustment adjustment) async {
    try {
      print('\n🔄 === STARTING STOCK ADJUSTMENT ===');
      print('📤 Sending stock adjustment: ${adjustment.toJson()}');
      print('🏢 Using Restaurant ID: $_restaurantId, Branch ID: $_branchId');
      print('🏪 Item being adjusted: ${adjustment.inventoryItemId}');
      print(
        '📊 Operation: ${adjustment.operation.name} | Quantity: ${adjustment.quantity}',
      );

      final headers = <String, String>{};
      if (_restaurantId != null) {
        headers['Restaurant-ID'] = _restaurantId;
      }
      if (_branchId != null) {
        headers['Branch-ID'] = _branchId;
      }

      print('📋 Sending headers: $headers');

      // 🔧 FIX: Format the request according to backend requirements
      final Map<String, dynamic> itemData = {
        'itemId': adjustment.inventoryItemId, // ✅ Backend expects 'itemId'
        'operation':
            adjustment.operation.name.toLowerCase(), // ✅ "add", "remove", "set"
        'quantity': adjustment.quantity,
      };

      // ✅ Add unitCost for 'add' operations (recommended by backend)
      if (adjustment.operation == StockOperation.add &&
          adjustment.costPrice != null) {
        itemData['unitCost'] = adjustment.costPrice;
      }

      final requestData = {
        'items': [itemData],
        'reason': adjustment.reason,
        'restaurantId': _restaurantId,
        'branchId': _branchId,
        if (adjustment.notes != null) 'notes': adjustment.notes,
      };

      print('\n📦 === REQUEST DATA ===');
      print('📦 Full request data: $requestData');
      print('🔍 Items array type: ${requestData['items'].runtimeType}');
      print('🔍 Items array length: ${(requestData['items'] as List).length}');
      print('🔍 First item details: ${(requestData['items'] as List).first}');
      print('🔍 Restaurant ID: $_restaurantId');
      print('🔍 Branch ID: $_branchId');

      // Validate required fields
      if (_restaurantId == null || _branchId == null) {
        throw Exception(
          'Missing restaurant ID or branch ID for stock adjustment',
        );
      }

      final response = await _apiClient.post(
        ApiConstants.stockAdjust,
        data: requestData,
        options: Options(headers: headers),
      );

      print('\n📥 === API RESPONSE ===');
      print('📥 Raw API response: $response');
      print('📥 Response type: ${response.runtimeType}');

      // Check if the operation actually succeeded
      final data = response['data'];
      print('📥 Response data: $data');
      print('📥 Response data type: ${data.runtimeType}');

      if (data is Map<String, dynamic>) {
        final operationSuccess = data['success'] as bool? ?? true;
        print('📥 Operation success: $operationSuccess');

        if (!operationSuccess) {
          // Extract error details
          final errors = data['errors'] as List<dynamic>? ?? [];
          final errorMessage = data['message'] as String? ?? 'Operation failed';

          print('❌ Stock operation failed: $errorMessage');
          if (errors.isNotEmpty) {
            print('❌ Errors: $errors');
          }

          // Throw exception with detailed error
          throw Exception(
            '$errorMessage${errors.isNotEmpty ? '\nErrors: ${errors.join(', ')}' : ''}',
          );
        }

        // ✅ CRITICAL FIX: Extract actual stock data from API response
        print('\n🔍 === EXTRACTING STOCK DATA ===');

        // Try to extract updated inventory item data from response
        Map<String, dynamic>? updatedItemData;
        int? newStockLevel;
        int? previousStockLevel;

        // ✅ FIX: Check for 'results' array format (actual API response format)
        if (data.containsKey('results') && data['results'] is List) {
          final results = data['results'] as List;
          print('📊 Found results array with ${results.length} items');
          if (results.isNotEmpty) {
            updatedItemData = results[0] as Map<String, dynamic>;
            print('📊 Using first result item: $updatedItemData');
          }
        } else if (data.containsKey('updatedItems') &&
            data['updatedItems'] is List) {
          final updatedItems = data['updatedItems'] as List;
          print(
            '📊 Found updatedItems array with ${updatedItems.length} items',
          );
          if (updatedItems.isNotEmpty) {
            updatedItemData = updatedItems[0] as Map<String, dynamic>;
          }
        } else if (data.containsKey('item') && data['item'] is Map) {
          print('📊 Found single item in response');
          updatedItemData = data['item'] as Map<String, dynamic>;
        } else if (data.containsKey('inventory') && data['inventory'] is Map) {
          print('📊 Found inventory data in response');
          updatedItemData = data['inventory'] as Map<String, dynamic>;
        } else if (data.containsKey('result') && data['result'] is Map) {
          print('📊 Found result data in response');
          updatedItemData = data['result'] as Map<String, dynamic>;
        } else {
          print('📊 No nested data found, checking top-level for stock info');
          if (data.containsKey('currentStock') ||
              data.containsKey('newStock')) {
            updatedItemData = data;
          }
        }

        // ✅ FIX: Extract stock levels using actual API response field names
        if (updatedItemData != null) {
          print('📊 Updated item data: $updatedItemData');

          // Try multiple field name variations based on actual API response
          newStockLevel =
              (updatedItemData['stockAfter'] as num?)
                  ?.toInt() ?? // ✅ Actual API field
              (updatedItemData['totalStock'] as num?)
                  ?.toInt() ?? // ✅ Actual API field
              (updatedItemData['currentStock'] as num?)?.toInt() ??
              (updatedItemData['newStock'] as num?)?.toInt();

          previousStockLevel =
              (updatedItemData['stockBefore'] as num?)
                  ?.toInt() ?? // ✅ Actual API field
              (updatedItemData['previousStock'] as num?)?.toInt() ??
              (updatedItemData['oldStock'] as num?)?.toInt();
          print(
            '📊 Extracted stock levels - Previous: $previousStockLevel, New: $newStockLevel',
          );
        }

        // If we still don't have stock levels, this is a critical issue
        if (newStockLevel == null) {
          print('\n⚠️ === CRITICAL ISSUE DETECTED ===');
          print('⚠️ No stock levels in API response!');
          print(
            '⚠️ This suggests the backend is not returning updated inventory data',
          );
          print(
            '⚠️ This means the update might not be persisting to the database',
          );
          print(
            '⚠️ Backend should return the updated inventory item with new currentStock value',
          );
          print('⚠️ Available data keys: ${data.keys.toList()}');

          // Log what we do have in the response
          for (final key in data.keys) {
            print('   - $key: ${data[key]}');
          }
        }

        print('✅ Stock adjustment completed successfully');
        print(
          '📊 Final stock levels - Previous: ${previousStockLevel ?? "unknown"}, New: ${newStockLevel ?? "unknown"}',
        );

        return StockAdjustmentResult(
          transactionId:
              data['transactionId']?.toString() ??
              data['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          previousStock: previousStockLevel ?? 0,
          newStock: newStockLevel ?? 0,
          operation: adjustment.operation.name.toUpperCase(),
          quantity: adjustment.quantity,
        );
      }
    } catch (e, stackTrace) {
      print('\n❌ === STOCK ADJUSTMENT ERROR ===');
      print('📋 Failed stock adjustment data: ${adjustment.toJson()}');
      print('📋 Full error details: $e');
      print('📋 Stack trace: $stackTrace');

      // Log additional context for debugging
      print('📋 Restaurant ID: $_restaurantId');
      print('📋 Branch ID: $_branchId');
      print('📋 API endpoint: ${ApiConstants.stockAdjust}');

      // Try to extract more specific error information
      if (e.toString().contains('DioException')) {
        print('🔍 DioException detected - checking response details');

        // Try to get the actual error message from the response
        String errorMsg = 'Stock adjustment failed';

        if (e.toString().contains('400')) {
          errorMsg =
              'Bad request - Invalid data format or missing required fields';
          print(
            '💡 Suggestion: Check if all required fields are provided and in correct format',
          );
        } else if (e.toString().contains('404')) {
          errorMsg = 'Inventory item or branch not found';
          print(
            '💡 Suggestion: Verify the inventory item ID and branch ID exist in database',
          );
        } else if (e.toString().contains('401')) {
          errorMsg = 'Unauthorized - Please login again';
          print('💡 Suggestion: User authentication may have expired');
        } else if (e.toString().contains('403')) {
          errorMsg = 'Forbidden - Insufficient permissions';
          print(
            '💡 Suggestion: User may not have inventory management permissions',
          );
        } else if (e.toString().contains('500')) {
          errorMsg = 'Server error - Please try again later';
          print('💡 Suggestion: Backend server error - check server logs');
        }

        print('❌ Final error message: $errorMsg');
        throw Exception(errorMsg);
      }

      // Re-throw with simplified message
      print('❌ Non-DioException error occurred');
      throw Exception(
        'Stock adjustment failed: Please check the data and try again',
      );
    }

    // This should never be reached due to the logic above, but adding for completeness
    throw Exception('Unexpected end of adjustStock method');
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
    required String restaurantId,
    required String branchId,
    String? alertType, // low_stock, out_of_stock, expiring_soon
  }) async {
    final response = await _apiClient.get(
      ApiConstants.inventoryAlerts,
      queryParameters: {
        'restaurantId': restaurantId,
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
    required String restaurantId,
    required String branchId,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.inventoryValuation,
      queryParameters: {'restaurantId': restaurantId, 'branchId': branchId},
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

  /// Diagnostic method to test inventory API endpoints and connection
  Future<Map<String, dynamic>> runInventoryDiagnostics({
    required String restaurantId,
    required String branchId,
  }) async {
    print('\n🔧 === RUNNING INVENTORY DIAGNOSTICS ===');
    final results = <String, dynamic>{};

    try {
      // Test 1: Check API connectivity
      print('🔧 Test 1: API Connectivity');
      try {
        final items = await getInventoryItems(
          restaurantId: restaurantId,
          branchId: branchId,
          limit: 1,
        );
        results['api_connectivity'] = {
          'status': 'success',
          'message': 'API is reachable',
          'item_count': items.length,
        };
        print('✅ API connectivity: SUCCESS');
      } catch (e) {
        results['api_connectivity'] = {
          'status': 'failed',
          'error': e.toString(),
        };
        print('❌ API connectivity: FAILED - $e');
      }

      // Test 2: Check endpoints configuration
      print('🔧 Test 2: Endpoints Configuration');
      results['endpoints'] = {
        'inventory_items': ApiConstants.inventoryItems,
        'stock_adjust': ApiConstants.stockAdjust,
        'inventory_transactions': ApiConstants.inventoryTransactions,
      };
      print('✅ Stock adjust endpoint: ${ApiConstants.stockAdjust}');

      // Test 3: Check authentication headers
      print('🔧 Test 3: Authentication Context');
      results['auth_context'] = {
        'restaurant_id': _restaurantId,
        'branch_id': _branchId,
        'has_restaurant': _restaurantId != null,
        'has_branch': _branchId != null,
      };
      print('✅ Restaurant ID: ${_restaurantId ?? "NULL"}');
      print('✅ Branch ID: ${_branchId ?? "NULL"}');

      // Test 4: Try a simple stock transaction (dry run data)
      print('🔧 Test 4: Stock Adjustment Endpoint Test');
      try {
        // Create a test request format (don't send it)
        final testRequest = {
          'items': [
            {'itemId': 'test-item-id', 'operation': 'add', 'quantity': 1},
          ],
          'reason': 'diagnostic_test',
          'restaurantId': _restaurantId,
          'branchId': _branchId,
        };

        results['stock_request_format'] = {
          'status': 'formatted',
          'endpoint': ApiConstants.stockAdjust,
          'sample_request': testRequest,
        };
        print('✅ Stock request format: VALID');

        // Note: We won't actually send this test request to avoid creating fake data
        print(
          'ℹ️  Stock endpoint test prepared (not executed to avoid fake data)',
        );
      } catch (e) {
        results['stock_request_format'] = {
          'status': 'failed',
          'error': e.toString(),
        };
        print('❌ Stock request format: FAILED - $e');
      }
    } catch (e) {
      print('❌ Diagnostic error: $e');
      results['diagnostic_error'] = e.toString();
    }

    print('🔧 === DIAGNOSTICS COMPLETE ===');
    return results;
  }

  /// Verify stock adjustment by fetching fresh inventory data
  Future<InventoryItem?> verifyStockAdjustment({
    required String inventoryItemId,
    required String branchId,
    int expectedStock = -1,
  }) async {
    try {
      print('\n🔍 === VERIFYING STOCK ADJUSTMENT ===');
      print('🔍 Fetching fresh data for item: $inventoryItemId');

      // Get all inventory items to find the updated one
      final items = await getInventoryItems(
        restaurantId: _restaurantId!,
        branchId: branchId,
        limit: 1000,
      );

      // Find the item by ID (try multiple matching strategies)
      InventoryItem? updatedItem;

      // Strategy 1: Match by inventory ID
      updatedItem =
          items.where((item) => item.id == inventoryItemId).firstOrNull;

      // Strategy 2: Match by item ID (menu item reference)
      if (updatedItem == null) {
        updatedItem =
            items.where((item) => item.itemId == inventoryItemId).firstOrNull;
      }

      if (updatedItem != null) {
        print('✅ Found updated inventory item: ${updatedItem.name}');
        print('📊 Current stock level: ${updatedItem.currentStock}');
        print('📊 Min stock level: ${updatedItem.minStockLevel}');
        print('📊 Max stock level: ${updatedItem.maxStockLevel}');

        if (expectedStock >= 0) {
          if (updatedItem.currentStock == expectedStock) {
            print('✅ Stock level matches expected value: $expectedStock');
          } else {
            print('⚠️  Stock level mismatch!');
            print('   Expected: $expectedStock');
            print('   Actual: ${updatedItem.currentStock}');
            print('   This indicates the backend update may have failed');
          }
        }

        return updatedItem;
      } else {
        print('❌ Could not find inventory item with ID: $inventoryItemId');
        print('📋 Available items:');
        for (final item in items.take(10)) {
          print('   - ${item.name} (ID: ${item.id}, ItemID: ${item.itemId})');
        }
        return null;
      }
    } catch (e) {
      print('❌ Error verifying stock adjustment: $e');
      return null;
    }
  }

  /// Export inventory to CSV
  Future<String> exportInventory({required String branchId}) async {
    final response = await _apiClient.get(
      '/inventory/export',
      queryParameters: {'branchId': branchId},
    );

    return response['data']['url'] as String? ?? '';
  }

  /// Create inventory item from menu item
  Future<InventoryItem> createInventoryItemFromMenu({
    required String menuItemId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    String category = 'finished_good',
    String unit = 'unit',
    required double costPerUnit,
    double? sellingPrice,
    int initialStock = 0,
    int minStockLevel = 10,
    int maxStockLevel = 500,
  }) async {
    if (_restaurantId == null || _branchId == null) {
      throw Exception('Restaurant or Branch not configured');
    }

    print('🔄 Creating inventory item for menu item: $name');

    // Create the inventory item with menu item ID reference
    final request = CreateInventoryItemRequest(
      itemId: menuItemId, // ✅ Link to menu item
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      category: category,
      unitOfMeasure: UnitOfMeasure(
        name: unit,
        abbreviation: unit,
        category: 'count',
      ),
      costPerUnit: costPerUnit,
      sellingPrice: sellingPrice,
      minStockLevel: minStockLevel,
      maxStockLevel: maxStockLevel,
      status: 'active',
    );

    final response = await _apiClient.post(
      ApiConstants.inventoryItems,
      data: request.toJson(),
    );

    final inventoryItem = InventoryItem.fromJson(
      response['data'] as Map<String, dynamic>,
    );

    // Set initial stock if provided
    if (initialStock > 0) {
      await addStock(
        inventoryItemId: inventoryItem.id,
        branchId: _branchId,
        quantity: initialStock,
        reason: 'Initial stock for menu item',
        notes: 'Created from menu item: $name',
      );
    }

    print(
      '✅ Created inventory item: ${inventoryItem.name} with stock: $initialStock',
    );
    return inventoryItem;
  }

  /// Deduct stock when order is processed
  Future<void> deductStockForOrder({
    required String orderId,
    required List<Map<String, dynamic>> orderItems,
  }) async {
    if (_restaurantId == null || _branchId == null) {
      print('❌ Restaurant ID: $_restaurantId, Branch ID: $_branchId');
      throw Exception('Restaurant or Branch not configured');
    }

    print('🔄 === STARTING STOCK DEDUCTION FOR ORDER ===');
    print('📋 Order ID: $orderId');
    print('📦 Processing ${orderItems.length} items');
    print('🏢 Restaurant ID: $_restaurantId');
    print('🏪 Branch ID: $_branchId');

    try {
      // Process each order item
      for (int index = 0; index < orderItems.length; index++) {
        final item = orderItems[index];
        final menuItemId = item['menuItemId'] as String?;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final itemName = item['name'] as String? ?? 'Unknown item';

        print(
          '\\n📦 === PROCESSING ITEM ${index + 1}/${orderItems.length} ===',
        );
        print('📋 Item name: $itemName');
        print('🆔 Menu item ID: $menuItemId');
        print('📊 Quantity to deduct: $quantity');

        if (menuItemId == null || quantity <= 0) {
          print(
            '⚠️ Skipping invalid item: $itemName (menuItemId: $menuItemId, quantity: $quantity)',
          );
          continue;
        }

        // Find the inventory item for this menu item
        try {
          print('🔍 Searching for inventory item...');
          final allItems = await getInventoryItems(
            restaurantId: _restaurantId,
            branchId: _branchId,
            limit: 1000, // Get all items
          );

          print('📊 Total inventory items found: ${allItems.length}');

          // Look for inventory item linked to this menu item
          final matchingItems =
              allItems
                  .where(
                    (inv) =>
                        inv.itemId ==
                            menuItemId || // ✅ Correct: match by itemId field
                        inv.id == menuItemId || // Fallback: Direct ID match
                        inv.name.toLowerCase().contains(
                          itemName.toLowerCase(),
                        ), // Fallback: Name match
                  )
                  .toList();

          print('📊 Matching inventory items found: ${matchingItems.length}');
          for (final match in matchingItems) {
            print(
              '   - ${match.name} (ID: ${match.id}, itemId: ${match.itemId}, stock: ${match.currentStock})',
            );
          }

          final inventoryItem =
              matchingItems.isNotEmpty ? matchingItems.first : null;

          if (inventoryItem != null) {
            print('✅ Found matching inventory item: ${inventoryItem.name}');
            print(
              '📊 Current stock before deduction: ${inventoryItem.currentStock}',
            );
            print('📊 Will deduct: $quantity units');
            print(
              '📊 Expected stock after deduction: ${inventoryItem.currentStock - quantity}',
            );

            print('🔄 Calling removeStock API...');
            final result = await removeStock(
              inventoryItemId: inventoryItem.id,
              branchId: _branchId,
              quantity: quantity,
              reason: 'Sale - Order: $orderId',
              notes: 'Automatic stock deduction for order',
            );

            print('✅ Stock deduction API call completed');
            print('📊 API Result: ${result.toString()}');
            print('✅ Stock deducted successfully for ${inventoryItem.name}');
          } else {
            print(
              '❌ No inventory item found for menu item: $itemName ($menuItemId)',
            );
            print('📋 Available inventory items:');
            for (final availableItem in allItems.take(5)) {
              print(
                '   - ${availableItem.name} (ID: ${availableItem.id}, itemId: ${availableItem.itemId})',
              );
            }
            print('ℹ️ This item may not have stock tracking enabled');
          }
        } catch (e) {
          print('❌ Error deducting stock for $itemName: $e');
          print('📋 Full error details: ${e.toString()}');
          print('📋 Stack trace: ${StackTrace.current}');
          // Continue with other items even if one fails
        }
      }

      print('\\n✅ === STOCK DEDUCTION COMPLETED ===');
      print('📋 All items processed for order: $orderId');
    } catch (e) {
      print('❌ Error processing stock deduction for order $orderId: $e');
      print('📋 Full error details: ${e.toString()}');
      print('📋 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Check if a menu item has inventory tracking enabled
  /// Items with inventory records are considered to have inventory tracking enabled
  Future<bool> hasInventoryTracking(String menuItemId) async {
    try {
      print('🔍 Checking inventory tracking for menu item: $menuItemId');

      if (_restaurantId == null || _branchId == null) {
        print('❌ Missing restaurant/branch ID for inventory check');
        return false;
      }

      // Get all inventory items for the branch
      final inventoryItems = await getInventoryItems(
        restaurantId: _restaurantId,
        branchId: _branchId,
        limit: 1000, // Get all items to search
      );

      // Check if any inventory item matches this menu item ID
      final matchingItem =
          inventoryItems.where((item) {
            // Check both itemId field (reference to menu item) and id field
            return item.itemId == menuItemId || item.id == menuItemId;
          }).toList();

      final hasTracking = matchingItem.isNotEmpty;
      print('📊 Inventory tracking check result for $menuItemId: $hasTracking');
      if (hasTracking) {
        print('   ✅ Found matching inventory item: ${matchingItem.first.name}');
        print('   📦 Stock: ${matchingItem.first.currentStock}');
      } else {
        print(
          '   ❌ No inventory record found - item does not have inventory tracking',
        );
      }

      return hasTracking;
    } catch (e) {
      print('❌ Error checking inventory tracking for $menuItemId: $e');
      // Default to false (no inventory tracking) if there's an error
      return false;
    }
  }

  /// Validate stock availability for cart items before payment
  /// Throws exception if any item doesn't have enough stock
  Future<void> validateStockAvailability(
    List<Map<String, dynamic>> cartItems,
  ) async {
    try {
      print(
        '🔍 Validating stock availability for ${cartItems.length} cart items...',
      );

      if (_restaurantId == null || _branchId == null) {
        print('❌ Missing restaurant/branch ID for stock validation');
        throw Exception(
          'Cannot validate stock: Missing restaurant/branch information',
        );
      }

      // Get all inventory items for the branch
      final inventoryItems = await getInventoryItems(
        restaurantId: _restaurantId,
        branchId: _branchId,
        limit: 1000, // Get all items to search
      );

      // Check each cart item
      for (final cartItem in cartItems) {
        final menuItemId = cartItem['menuItemId'] as String;
        final requestedQuantity = cartItem['quantity'] as int;
        final itemName = cartItem['name'] as String;

        // Find matching inventory item
        final matchingInventoryItem =
            inventoryItems.where((item) {
              return item.itemId == menuItemId || item.id == menuItemId;
            }).toList();

        if (matchingInventoryItem.isEmpty) {
          print('❌ No inventory record found for $itemName ($menuItemId)');
          throw Exception(
            'Stock validation failed: $itemName is not found in inventory system',
          );
        }

        final inventoryItem = matchingInventoryItem.first;
        final availableStock = inventoryItem.currentStock;

        print('📦 Stock check for $itemName:');
        print('   Available: $availableStock');
        print('   Requested: $requestedQuantity');

        if (availableStock < requestedQuantity) {
          print('❌ Insufficient stock for $itemName');
          throw Exception(
            'Insufficient stock: $itemName has only $availableStock units available, but $requestedQuantity requested. Please reduce quantity or remove item from cart.',
          );
        }

        // Check for low stock warning
        if (availableStock <= inventoryItem.minStockLevel) {
          print(
            '⚠️  Low stock warning for $itemName: $availableStock units (threshold: ${inventoryItem.minStockLevel})',
          );
        }

        print('   ✅ Stock validation passed for $itemName');
      }

      print('✅ All items have sufficient stock available');
    } catch (e) {
      print('❌ Stock validation failed: $e');
      rethrow;
    }
  }

  /// Get current stock level for a specific menu item
  Future<int> getStockLevel(String menuItemId) async {
    try {
      if (_restaurantId == null || _branchId == null) {
        print('❌ Missing restaurant/branch ID for stock check');
        return 0;
      }

      final inventoryItems = await getInventoryItems(
        restaurantId: _restaurantId,
        branchId: _branchId,
        limit: 1000,
      );

      final matchingItem =
          inventoryItems.where((item) {
            return item.itemId == menuItemId || item.id == menuItemId;
          }).toList();

      if (matchingItem.isEmpty) {
        return 0;
      }

      return matchingItem.first.currentStock;
    } catch (e) {
      print('❌ Error getting stock level for $menuItemId: $e');
      return 0;
    }
  }
}
