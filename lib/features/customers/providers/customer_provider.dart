import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/customer.dart';
import '../../../core/services/customer_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Customers state
class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Customers notifier
class CustomersNotifier extends StateNotifier<CustomersState> {
  final CustomerService _customerService;
  final String? _restaurantId;

  CustomersNotifier(this._customerService, this._restaurantId)
    : super(const CustomersState()) {
    loadCustomers();
  }

  /// Load all customers
  Future<void> loadCustomers() async {
    if (_restaurantId == null) {
      state = state.copyWith(
        error: 'Restaurant not configured',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final customers = await _customerService.getCustomers(
        restaurantId: _restaurantId,
        search: state.searchQuery,
      );

      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Search customers
  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadCustomers();
  }

  /// Refresh customers
  Future<void> refresh() async {
    await loadCustomers();
  }
}

/// Customers provider
final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
      final customerService = ref.watch(customerServiceProvider);
      final restaurantId = ref.watch(currentRestaurantIdProvider);
      return CustomersNotifier(customerService, restaurantId);
    });
