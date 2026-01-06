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
      final ordersList = await _orderService.getOrders(branchId: _branchId);
      state = state.copyWith(
        orders: ordersList,
        filteredOrders: ordersList,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Filter orders by status
  void filterByStatus(String? status) {
    if (status == null || status == 'all') {
      state = state.copyWith(filteredOrders: state.orders, statusFilter: null);
    } else {
      final filtered =
          state.orders
              .where(
                (order) =>
                    order.status.name.toLowerCase() == status.toLowerCase(),
              )
              .toList();
      state = state.copyWith(filteredOrders: filtered, statusFilter: status);
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final orderService = ref.watch(orderServiceProvider);
  final branchId = ref.watch(currentBranchIdProvider);
  return OrdersNotifier(orderService, branchId);
});
