import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/inventory.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/inventory_api_service.dart' as api;
import '../../auth/providers/auth_provider.dart';

/// Inventory state
class InventoryState {
  final List<InventoryItem> items;
  final List<InventoryAlert> alerts;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? statusFilter; // null = all, 'low_stock', 'out_of_stock'

  const InventoryState({
    this.items = const [],
    this.alerts = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
  });

  InventoryState copyWith({
    List<InventoryItem>? items,
    List<InventoryAlert>? alerts,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
  }) {
    return InventoryState(
      items: items ?? this.items,
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  int get lowStockCount => items.where((i) => i.isLowStock).length;
  int get outOfStockCount => items.where((i) => i.currentStock == 0).length;
  int get totalAlerts => alerts.length;
}

/// Inventory notifier
class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryService _inventoryService;
  final String? _restaurantId;
  final String? _branchId;

  /// Categories and Units
  final List<String> _categories = [
    'Food Items',
    'Beverages',
    'Supplies',
    'Packaging',
    'Cleaning',
    'Equipment',
    'Raw Materials',
    'Condiments',
  ];

  final List<String> _units = [
    'pieces',
    'kg',
    'g',
    'liters',
    'ml',
    'boxes',
    'packs',
    'bottles',
    'cans',
    'bags',
  ];

  /// Getters
  List<String> get categories => List.unmodifiable(_categories);
  List<String> get units => List.unmodifiable(_units);

  InventoryNotifier(this._inventoryService, this._restaurantId, this._branchId)
    : super(const InventoryState()) {
    loadInventory();
    loadAlerts();
  }

  /// Load inventory items
  Future<void> loadInventory() async {
    if (_restaurantId == null || _branchId == null) {
      state = state.copyWith(
        error: 'Restaurant or Branch not configured',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    print(
      '🔄 Loading inventory items for restaurant: $_restaurantId, branch: $_branchId',
    );

    try {
      final items = await _inventoryService.getInventoryItems(
        restaurantId: _restaurantId,
        branchId: _branchId,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
        limit: 1000, // Increased limit to ensure all items are loaded
      );

      print('✅ Loaded ${items.length} inventory items');
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      print('❌ Error loading inventory: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load inventory alerts
  Future<void> loadAlerts() async {
    if (_restaurantId == null || _branchId == null) return;

    try {
      final apiService = api.InventoryApiService(_inventoryService as dynamic);
      final alerts = await apiService.getLowStockAlerts();

      state = state.copyWith(alerts: alerts);
    } catch (e) {
      // Silent fail for alerts
    }
  }

  /// Search inventory
  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadInventory();
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    loadInventory();
  }

  /// Refresh inventory
  Future<void> refresh() async {
    await loadInventory();
    await loadAlerts();
  }

  /// Adjust stock
  Future<bool> adjustStock(StockAdjustment adjustment) async {
    try {
      await _inventoryService.adjustStock(adjustment);
      await loadInventory();
      await loadAlerts();
      return true;
    } catch (e) {
      // Add better error logging
      print('📋 Stock adjustment error: $e');
      if (e.toString().contains('DioException')) {
        // Try to extract meaningful error from DioException
        final errorMessage = e.toString();
        if (errorMessage.contains('400')) {
          throw Exception(
            'Invalid request data - please check all required fields',
          );
        } else if (errorMessage.contains('401')) {
          throw Exception('Authentication required - please login again');
        } else if (errorMessage.contains('403')) {
          throw Exception('Permission denied - insufficient access rights');
        } else if (errorMessage.contains('404')) {
          throw Exception('Inventory item or branch not found');
        } else if (errorMessage.contains('500')) {
          throw Exception('Server error - please try again later');
        }
      }
      // Re-throw the original error if we can't parse it
      rethrow;
    }
  }

  /// Create inventory item
  Future<void> createInventoryItem({
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
    if (_restaurantId == null || _branchId == null) {
      throw Exception('Restaurant or Branch not configured');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = api.InventoryApiService(_inventoryService as dynamic);
      await apiService.createInventoryItem(
        name: name,
        description: description,
        sku: sku,
        barcode: barcode,
        category: category,
        unit: unit,
        costPerUnit: costPerUnit,
        sellingPrice: sellingPrice,
        currentStock: currentStock,
        minStockLevel: minStockLevel,
        maxStockLevel: maxStockLevel,
        status: status,
        trackStock: trackStock,
      );

      await loadInventory();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// Update inventory item
  Future<void> updateInventoryItem({
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
    if (_restaurantId == null || _branchId == null) {
      throw Exception('Restaurant or Branch not configured');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = api.InventoryApiService(_inventoryService as dynamic);
      await apiService.updateInventoryItem(
        itemId: itemId,
        name: name,
        description: description,
        sku: sku,
        barcode: barcode,
        category: category,
        unit: unit,
        costPerUnit: costPerUnit,
        sellingPrice: sellingPrice,
        minStockLevel: minStockLevel,
        maxStockLevel: maxStockLevel,
        status: status,
        trackStock: trackStock,
      );

      await loadInventory();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// Delete inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    if (_restaurantId == null || _branchId == null) {
      throw Exception('Restaurant or Branch not configured');
    }

    try {
      final apiService = api.InventoryApiService(_inventoryService as dynamic);
      await apiService.deleteInventoryItem(itemId);
      await loadInventory();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if item has sufficient stock
  bool checkStock(String menuItemId, int requestedQuantity) {
    print('\n🏪 === INVENTORY STOCK CHECK ===');
    print('   Checking stock for menu item ID: $menuItemId');
    print('   Requested quantity: $requestedQuantity');
    print('   Total inventory items in state: ${state.items.length}');

    try {
      // Try to find by menu item ID (itemId field) first, then fallback strategies
      InventoryItem? item;

      // Strategy 1: Match by itemId field (correct way)
      try {
        item = state.items.firstWhere((inv) => inv.itemId == menuItemId);
        print('   ✅ Found item by itemId field: ${item.name}');
      } catch (e) {
        print('   ❌ No item found with itemId: $menuItemId');

        // Strategy 2: Try direct ID match (legacy support)
        try {
          item = state.items.firstWhere((inv) => inv.id == menuItemId);
          print('   ✅ Found item by direct ID match: ${item.name}');
        } catch (e2) {
          print('   ❌ No item found with direct ID: $menuItemId');

          // List all available inventory items for debugging
          print('   Available inventory items:');
          for (int i = 0; i < state.items.length; i++) {
            final inv = state.items[i];
            print(
              '      [$i] ID: ${inv.id}, ItemId: ${inv.itemId}, Name: ${inv.name}, Stock: ${inv.currentStock}',
            );
          }

          print('   ❌ No inventory item found for menu item ID: $menuItemId');
          print('=== END INVENTORY CHECK ===\n');
          return false;
        }
      }

      print('   Item found: ${item.name}');
      print('   Available stock: ${item.availableStock}');
      print('   Current stock: ${item.currentStock}');
      print('   Reserved stock: ${item.reservedStock}');
      print('   Requested: $requestedQuantity');

      if (item.availableStock >= requestedQuantity) {
        print(
          '   ✅ STOCK CHECK PASSED: ${item.availableStock} >= $requestedQuantity',
        );
        print('=== END INVENTORY CHECK ===\n');
        return true;
      } else {
        print(
          '   ❌ INSUFFICIENT STOCK: ${item.availableStock} < $requestedQuantity',
        );
        print('=== END INVENTORY CHECK ===\n');
        return false;
      }
    } catch (e) {
      print('   ❌ Error during stock check: $e');
      print('   Available inventory items:');
      for (var inv in state.items) {
        print('      - ${inv.id}: ${inv.name} (${inv.currentStock} units)');
      }
      print('=== END INVENTORY CHECK ===\n');
      return false;
    }
  }

  /// Get stock level for an item
  int? getStockLevel(String menuItemId) {
    print('\n📊 === GET STOCK LEVEL ===');
    print('   Getting stock level for menu item ID: $menuItemId');

    try {
      // Try to find by itemId field first (correct way)
      InventoryItem? item;
      try {
        item = state.items.firstWhere((inv) => inv.itemId == menuItemId);
        print('   ✅ Found item by itemId: ${item.name}');
      } catch (e) {
        // Fallback to direct ID match (legacy support)
        try {
          item = state.items.firstWhere((inv) => inv.id == menuItemId);
          print('   ✅ Found item by direct ID: ${item.name}');
        } catch (e2) {
          print('   ❌ Item not found in inventory: $menuItemId');
          print('   Available items: ${state.items.length}');
          for (var inv in state.items) {
            print(
              '      - ID: ${inv.id}, ItemId: ${inv.itemId}, Name: ${inv.name}',
            );
          }
          print('=== END GET STOCK LEVEL ===\n');
          return null;
        }
      }

      print('   Stock level: ${item.availableStock}');
      print('=== END GET STOCK LEVEL ===\n');
      return item.availableStock;
    } catch (e) {
      print('   ❌ Error getting stock level: $e');
      print('=== END GET STOCK LEVEL ===\n');
      return null;
    }
  }

  /// Sync menu item with inventory (create inventory entry for new menu items)
  Future<void> syncMenuItemWithInventory({
    required String menuItemId,
    required String name,
    required double costPrice,
    required int initialStock,
    required int lowStockThreshold,
    String category = 'finished_good',
    String unit = 'unit',
    String? sku,
    String? barcode,
    String? description,
  }) async {
    if (_restaurantId == null || _branchId == null) {
      throw Exception('Restaurant or Branch not configured');
    }

    try {
      // Check if inventory item already exists for this menu item
      final existingItem =
          state.items
              .where(
                (item) =>
                    item.itemId ==
                        menuItemId || // ✅ Correct: match by itemId field
                    item.name.toLowerCase() == name.toLowerCase() ||
                    item.id == menuItemId ||
                    (item.sku != null && sku != null && item.sku == sku) ||
                    (item.barcode != null &&
                        barcode != null &&
                        item.barcode == barcode),
              )
              .firstOrNull;

      if (existingItem == null) {
        print('🔄 Creating inventory entry for menu item: $name');

        try {
          // Use the inventory service to create the item
          await _inventoryService.createInventoryItemFromMenu(
            menuItemId: menuItemId,
            name: name,
            description: description,
            sku: sku,
            barcode: barcode,
            category: category,
            unit: unit,
            costPerUnit: costPrice,
            initialStock: initialStock,
            minStockLevel: lowStockThreshold,
            maxStockLevel: 500,
          );

          // Refresh inventory after creation
          await loadInventory();

          print(
            '✅ Created inventory entry for: $name with initial stock: $initialStock',
          );
        } catch (e) {
          print('❌ Error creating inventory item via service: $e');
          // Fallback to the old method
          await createInventoryItem(
            name: name,
            description: description,
            sku: sku,
            barcode: barcode,
            category: category,
            unit: unit,
            costPerUnit: costPrice,
            currentStock: initialStock,
            minStockLevel: lowStockThreshold,
            maxStockLevel: 500,
            trackStock: true,
          );
        }
      } else {
        print(
          'ℹ️ Inventory entry already exists for: $name (${existingItem.id})',
        );
        print('📊 Current stock: ${existingItem.currentStock}');
      }
    } catch (e) {
      print('❌ Failed to sync menu item with inventory: $e');
      rethrow;
    }
  }

  /// Process stock deduction for completed orders
  Future<void> processStockDeduction({
    required String orderId,
    required List<Map<String, dynamic>> orderItems,
  }) async {
    if (_restaurantId == null || _branchId == null) {
      throw Exception('Restaurant or Branch not configured');
    }

    print('🔄 Processing stock deduction for order: $orderId');

    try {
      await _inventoryService.deductStockForOrder(
        orderId: orderId,
        orderItems: orderItems,
      );

      // Refresh inventory after stock deduction
      await loadInventory();
      await loadAlerts();

      print('✅ Stock deduction completed for order: $orderId');
    } catch (e) {
      print('❌ Error processing stock deduction: $e');
      rethrow;
    }
  }

  /// Fix existing inventory items by linking them to menu items
  /// Call this method to fix the current issue where inventory items exist but aren't linked to menu items
  Future<void> fixInventoryLinking({
    required List<Map<String, String>>
    menuItemsToLink, // [{menuItemId: 'xxx', inventoryName: 'yyy'}]
  }) async {
    if (_restaurantId == null || _branchId == null) {
      throw Exception('Restaurant or Branch not configured');
    }

    print('🔧 === FIXING INVENTORY LINKING ===');
    print('   Processing ${menuItemsToLink.length} menu items');

    try {
      for (final linkData in menuItemsToLink) {
        final menuItemId = linkData['menuItemId'];
        final inventoryName = linkData['inventoryName'];

        if (menuItemId == null || inventoryName == null) {
          print('❌ Skipping invalid link data: $linkData');
          continue;
        }

        print(
          '\\n🔗 Linking menu item $menuItemId to inventory "$inventoryName"',
        );

        // Find the inventory item by name
        final inventoryItem =
            state.items
                .where(
                  (item) =>
                      item.name.toLowerCase() == inventoryName.toLowerCase(),
                )
                .firstOrNull;

        if (inventoryItem == null) {
          print('❌ No inventory item found with name: $inventoryName');
          continue;
        }

        print(
          '✅ Found inventory item: ${inventoryItem.name} (ID: ${inventoryItem.id})',
        );

        try {
          // Update the inventory item to include the menu item ID
          final apiService = api.InventoryApiService(
            _inventoryService as dynamic,
          );
          await apiService.updateInventoryItem(
            itemId: inventoryItem.id,
            name: inventoryItem.name,
            description: inventoryItem.description,
            sku: inventoryItem.sku,
            barcode: inventoryItem.barcode,
            category: inventoryItem.category,
            unit: inventoryItem.unitOfMeasure.name,
            costPerUnit: inventoryItem.costPerUnit,
            sellingPrice: inventoryItem.sellingPrice,
            minStockLevel: inventoryItem.minStockLevel,
            maxStockLevel: inventoryItem.maxStockLevel,
            status: inventoryItem.status,
            trackStock: true,
            menuItemId: menuItemId, // ✅ Add the menu item ID link
          );

          print(
            '✅ Successfully linked inventory "${inventoryItem.name}" to menu item $menuItemId',
          );
        } catch (e) {
          print('❌ Failed to update inventory item ${inventoryItem.name}: $e');
        }
      }

      // Refresh inventory after all updates
      await loadInventory();
      print('\\n🔄 Inventory refreshed after linking');
      print('=== END FIXING INVENTORY LINKING ===\\n');
    } catch (e) {
      print('❌ Error during inventory linking: $e');
      rethrow;
    }
  }
}

/// Inventory provider
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      final inventoryService = ref.watch(inventoryServiceProvider);
      final restaurantId = ref.watch(currentRestaurantIdProvider);
      final branchId = ref.watch(currentBranchIdProvider);
      return InventoryNotifier(inventoryService, restaurantId, branchId);
    });

/// Inventory valuation provider
final inventoryValuationProvider = FutureProvider<InventoryValuation?>((
  ref,
) async {
  final restaurantId = ref.watch(currentRestaurantIdProvider);
  final branchId = ref.watch(currentBranchIdProvider);
  if (restaurantId == null || branchId == null) return null;

  try {
    return await ref
        .read(inventoryServiceProvider)
        .getInventoryValuation(restaurantId: restaurantId, branchId: branchId);
  } catch (e) {
    return null;
  }
});
