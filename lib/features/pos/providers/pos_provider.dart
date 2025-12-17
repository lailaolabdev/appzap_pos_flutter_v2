import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cart.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/product.dart';
import '../../../core/services/product_service.dart';
import '../../auth/providers/auth_provider.dart';

// ============ PRODUCTS PROVIDER ============

/// Products state
class ProductsState {
  final List<Product> products;
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final String? selectedCategoryId;
  final String searchQuery;

  const ProductsState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategoryId,
    this.searchQuery = '',
  });

  ProductsState copyWith({
    List<Product>? products,
    List<Category>? categories,
    bool? isLoading,
    String? error,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return ProductsState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Get filtered products based on category and search
  List<Product> get filteredProducts {
    var filtered = products;

    if (selectedCategoryId != null) {
      filtered =
          filtered.where((p) => p.categoryId == selectedCategoryId).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered =
          filtered.where((p) {
            return p.name.toLowerCase().contains(query) ||
                (p.barcode?.contains(query) ?? false) ||
                (p.sku?.toLowerCase().contains(query) ?? false);
          }).toList();
    }

    return filtered;
  }
}

/// Products notifier
class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductService _productService;
  final String? _branchId;
  final String? _restaurantId;

  ProductsNotifier(this._productService, this._branchId, this._restaurantId)
    : super(const ProductsState()) {
    loadProducts();
  }

  /// Load products and categories
  Future<void> loadProducts() async {
    if (_branchId == null || _restaurantId == null) {
      state = state.copyWith(
        error: 'Branch or restaurant not configured',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _productService.getProducts(
          restaurantId: _restaurantId,
          branchId: _branchId,
        ),
        _productService.getCategories(restaurantId: _restaurantId),
      ]);

      state = state.copyWith(
        products: results[0] as List<Product>,
        categories: results[1] as List<Category>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Select category
  void selectCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  /// Update search query
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// Find product by barcode
  Product? findByBarcode(String barcode) {
    try {
      return state.products.firstWhere((p) => p.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  /// Refresh products
  Future<void> refresh() async {
    await loadProducts();
  }
}

/// Products provider
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>(
  (ref) {
    final productService = ref.watch(productServiceProvider);
    final branchId = ref.watch(currentBranchIdProvider);
    final restaurantId = ref.watch(currentRestaurantIdProvider);
    return ProductsNotifier(productService, branchId, restaurantId);
  },
);

// ============ CART PROVIDER ============

/// Cart notifier
class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(const Cart());

  /// Add product to cart
  void addProduct(Product product, {int quantity = 1}) {
    if (!product.isInStock) return;
    state = state.addProduct(product, quantity: quantity);
  }

  /// Remove item from cart
  void removeItem(String productId) {
    state = state.removeItem(productId);
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    state = state.updateQuantity(productId, quantity);
  }

  /// Increment item quantity
  void incrementQuantity(String productId) {
    state = state.incrementQuantity(productId);
  }

  /// Decrement item quantity
  void decrementQuantity(String productId) {
    state = state.decrementQuantity(productId);
  }

  /// Update item notes
  void updateItemNotes(String productId, String? notes) {
    state = state.updateItemNotes(productId, notes);
  }

  /// Add discount
  void addDiscount(CartDiscount discount) {
    state = state.addDiscount(discount);
  }

  /// Remove discount
  void removeDiscount(int index) {
    state = state.removeDiscount(index);
  }

  /// Clear discounts
  void clearDiscounts() {
    state = state.clearDiscounts();
  }

  /// Set customer
  void setCustomer(Customer? customer) {
    state = state.setCustomer(customer);
  }

  /// Set notes
  void setNotes(String? notes) {
    state = state.setNotes(notes);
  }

  /// Clear cart
  void clear() {
    state = state.clear();
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});

/// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItemsCount;
});

/// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).total;
});
