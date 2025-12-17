import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/inventory.dart';
import '../../../core/services/inventory_service.dart';
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

    try {
      final items = await _inventoryService.getInventoryItems(
        restaurantId: _restaurantId,
        branchId: _branchId,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
      );

      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Load inventory alerts
  Future<void> loadAlerts() async {
    if (_restaurantId == null || _branchId == null) return;

    try {
      final alerts = await _inventoryService.getInventoryAlerts(
        restaurantId: _restaurantId,
        branchId: _branchId,
      );

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
      return false;
    }
  }
}

/// Inventory provider
final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>(
  (ref) {
    final inventoryService = ref.watch(inventoryServiceProvider);
    final restaurantId = ref.watch(currentRestaurantIdProvider);
    final branchId = ref.watch(currentBranchIdProvider);
    return InventoryNotifier(inventoryService, restaurantId, branchId);
  },
);

/// Inventory valuation provider
final inventoryValuationProvider = FutureProvider<InventoryValuation?>((ref) async {
  final restaurantId = ref.watch(currentRestaurantIdProvider);
  final branchId = ref.watch(currentBranchIdProvider);
  if (restaurantId == null || branchId == null) return null;

  try {
    return await ref.read(inventoryServiceProvider).getInventoryValuation(
      restaurantId: restaurantId,
      branchId: branchId,
    );
  } catch (e) {
    return null;
  }
});

