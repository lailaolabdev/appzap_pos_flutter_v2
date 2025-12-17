import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/order_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../screens/orders_screen.dart';

/// Orders state
class OrdersState {
  final List<Order> orders;
  final List<Order> filteredOrders;
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
    List<Order>? orders,
    List<Order>? filteredOrders,
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

      final response = await _orderService.getOrders(branchId: _branchId);
      
      // Extract data array from response
      final List<dynamic> ordersData;
      if (response is Map) {
        final map = response as Map<String, dynamic>;
        ordersData = map['data'] as List<dynamic>? ?? [];
      } else {
        ordersData = response as List<dynamic>? ?? [];
      }
      
      // Convert to Order model (placeholder)
      final ordersList = ordersData.map((orderData) {
        final data = orderData as Map<String, dynamic>;
        return Order(
          id: data['_id'] as String? ?? '',
          orderNumber: data['orderId'] as String? ?? 'N/A',
          status: data['orderStatus'] as String? ?? 'pending',
          customerName: (data['customer'] as Map<String, dynamic>?)?['name'] as String?,
          createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
          itemCount: (data['items'] as List?)?.length ?? 0,
          total: ((data['pricing'] as Map<String, dynamic>?)?['total'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      state = state.copyWith(
        orders: ordersList,
        filteredOrders: ordersList,
        isLoading: false,
      );
    } catch (e) {
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
          .where((order) => order.status.toLowerCase() == status.toLowerCase())
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

