import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/order.dart' as order_model;
import '../../../core/services/order_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Orders state
class OrdersState {
  final List<order_model.Order> orders;
  final List<order_model.Order> filteredOrders;
  final bool isLoading;
  final String? error;
  final String? statusFilter;

  OrdersState({
    this.orders = const [],
    this.filteredOrders = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
  });

  OrdersState copyWith({
    List<order_model.Order>? orders,
    List<order_model.Order>? filteredOrders,
    bool? isLoading,
    String? error,
    String? statusFilter,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

/// Orders provider
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;
  final String? _branchId;

  OrdersNotifier(this._orderService, this._branchId) : super(OrdersState());

  /// Load orders from API
  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_branchId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Branch not configured',
        );
        return;
      }

      print('🔄 Loading orders for branch: $_branchId');
      
      // ✅ OrderService.getOrders() already returns List<Order> (parsed objects)!
      final ordersList = await _orderService.getOrders(branchId: _branchId);
      
      print('📦 Response type: ${ordersList.runtimeType}');
      print('📦 Orders count: ${ordersList.length}');
      
      if (ordersList.isNotEmpty) {
        print('📋 Sample order:');
        final first = ordersList.first;
        print('   ID: ${first.id}');
        print('   Order Number: ${first.orderId}');
        print('   Status: ${first.status.name}');
        print('   Items: ${first.items.length}');
        print('   Total: ${first.pricing.total}');
      }
      
      print('✅ Successfully loaded ${ordersList.length} orders');

      state = state.copyWith(
        orders: ordersList,
        filteredOrders: ordersList,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      print('❌ Error loading orders: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Filter orders by status
  void filterByStatus(String? status) {
    if (status == null || status == 'all') {
      state = state.copyWith(
        filteredOrders: state.orders,
        statusFilter: null,
      );
    } else {
      final filtered = state.orders
          .where((order) => order.status.name.toLowerCase() == status.toLowerCase())
          .toList();
      state = state.copyWith(
        filteredOrders: filtered,
        statusFilter: status,
      );
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  final branchId = ref.watch(currentBranchIdProvider);
  return OrdersNotifier(orderService, branchId);
});

