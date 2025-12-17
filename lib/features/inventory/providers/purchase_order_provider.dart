import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/inventory.dart';
import '../../../core/services/inventory_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Purchase Order state
class PurchaseOrderState {
  final List<PurchaseOrder> orders;
  final bool isLoading;
  final String? error;
  final String? statusFilter; // null = all, pending, ordered, received

  const PurchaseOrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
  });

  PurchaseOrderState copyWith({
    List<PurchaseOrder>? orders,
    bool? isLoading,
    String? error,
    String? statusFilter,
  }) {
    return PurchaseOrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  int get pendingCount => orders.where((o) => o.status == 'pending').length;
  int get orderedCount => orders.where((o) => o.status == 'ordered').length;
  int get receivedCount => orders.where((o) => o.status == 'received').length;
}

/// Purchase Order notifier
class PurchaseOrderNotifier extends StateNotifier<PurchaseOrderState> {
  final InventoryService _inventoryService;
  final String? _branchId;

  PurchaseOrderNotifier(this._inventoryService, this._branchId)
      : super(const PurchaseOrderState()) {
    loadPurchaseOrders();
  }

  /// Load purchase orders
  Future<void> loadPurchaseOrders() async {
    if (_branchId == null) {
      state = state.copyWith(
        error: 'Branch not configured',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final orders = await _inventoryService.getPurchaseOrders(
        branchId: _branchId,
        status: state.statusFilter,
      );

      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    loadPurchaseOrders();
  }

  /// Create purchase order
  Future<bool> createPurchaseOrder({
    required String supplierId,
    required List<PurchaseOrderItem> items,
    required String expectedDeliveryDate,
    String? notes,
  }) async {
    if (_branchId == null) return false;

    try {
      await _inventoryService.createPurchaseOrder(
        branchId: _branchId,
        supplierId: supplierId,
        items: items,
        expectedDeliveryDate: expectedDeliveryDate,
        notes: notes,
      );

      await loadPurchaseOrders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update purchase order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _inventoryService.updatePurchaseOrderStatus(
        orderId: orderId,
        status: status,
      );

      await loadPurchaseOrders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Refresh orders
  Future<void> refresh() => loadPurchaseOrders();
}

/// Purchase Order provider
final purchaseOrderProvider =
    StateNotifierProvider<PurchaseOrderNotifier, PurchaseOrderState>(
  (ref) {
    final inventoryService = ref.watch(inventoryServiceProvider);
    final branchId = ref.watch(currentBranchIdProvider);
    return PurchaseOrderNotifier(inventoryService, branchId);
  },
);

