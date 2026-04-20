import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cart.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/product.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/inventory_service.dart';
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
    bool updateSelectedCategory = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategoryId:
          updateSelectedCategory
              ? selectedCategoryId
              : (selectedCategoryId ?? this.selectedCategoryId),
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

      final products = results[0] as List<Product>;
      final categories = results[1] as List<Category>;

      // ✅ NEW: Merge with inventory data
      final mergedProducts = await _mergeWithInventoryData(products);

      state = state.copyWith(
        products: mergedProducts,
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Merge products with inventory data
  Future<List<Product>> _mergeWithInventoryData(List<Product> products) async {
    try {
      // Get inventory service from Riverpod
      final container = ProviderContainer();
      final inventoryService = container.read(inventoryServiceProvider);

      // Load inventory items
      final inventoryItems = await inventoryService.getInventoryItems(
        restaurantId: _restaurantId!,
        branchId: _branchId!,
      );

      // Create a map for quick lookup: itemId -> inventory data
      final inventoryMap = <String, dynamic>{};
      for (final item in inventoryItems) {
        if (item.itemId != null) {
          inventoryMap[item.itemId!] = {
            'currentStock': item.currentStock,
            'lowStockThreshold': item.lowStockThreshold,
            'isLowStock': item.isLowStock,
            'unit': item.unit,
          };
        }
      }

      // Merge inventory data with products
      final mergedProducts =
          products.map((product) {
            final inventoryData = inventoryMap[product.id];

            if (inventoryData != null) {
              // Create updated product with merged inventory
              return product.copyWith(
                inventory: ProductInventory(
                  trackStock: true,
                  currentStock: inventoryData['currentStock'] as int,
                  lowStockThreshold: inventoryData['lowStockThreshold'] as int,
                  isLowStock: inventoryData['isLowStock'] as bool,
                  unit: inventoryData['unit'] as String,
                ),
              );
            } else {
              return product;
            }
          }).toList();

      container.dispose();
      return mergedProducts;
    } catch (e) {
      return products; // Return original products if merging fails
    }
  }

  /// Select category
  void selectCategory(String? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      updateSelectedCategory: true,
    );
  }

  /// Update search query
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Refresh products (force reload from API)
  Future<void> refresh() async {
    await loadProducts();
  }

  /// Find product by barcode (local first, then API)
  Product? findByBarcode(String barcode) {
    try {
      // First, search in local products
      return state.products.firstWhere((p) => p.barcode == barcode);
    } catch (e) {
      // Not found locally - return null for now
      // The API search will be handled asynchronously
      return null;
    }
  }

  /// Find product by barcode with API fallback
  Future<Product?> findByBarcodeAsync(String barcode) async {
    try {
      // First, search in local products
      try {
        return state.products.firstWhere((p) => p.barcode == barcode);
      } catch (e) {
        // Not found locally, search via API

        if (_branchId == null || _restaurantId == null) {
          return null;
        }

        final product = await _productService.getProductByBarcode(
          restaurantId: _restaurantId,
          branchId: _branchId,
          barcode: barcode,
        );

        if (product != null) {
          // Add the product to local state for future use
          state = state.copyWith(products: [...state.products, product]);

          return product;
        } else {
          return null;
        }
      }
    } catch (e) {
      return null;
    }
  }

  /// Update product inventory data after stock adjustment
  void updateProductInventory(
    String productId,
    int newStockLevel, {
    int? lowStockThreshold,
    String? unit,
  }) {
    final updatedProducts =
        state.products.map((product) {
          if (product.id == productId) {
            final updatedProduct = product.copyWith(
              inventory:
                  product.inventory?.copyWith(
                    currentStock: newStockLevel,
                    isLowStock:
                        lowStockThreshold != null
                            ? newStockLevel <= lowStockThreshold
                            : null,
                  ) ??
                  ProductInventory(
                    trackStock: true,
                    currentStock: newStockLevel,
                    lowStockThreshold: lowStockThreshold ?? 10,
                    unit: unit ?? 'unit',
                    isLowStock:
                        lowStockThreshold != null
                            ? newStockLevel <= lowStockThreshold
                            : false,
                  ),
            );

            return updatedProduct;
          }
          return product;
        }).toList();

    state = state.copyWith(products: updatedProducts);
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

  /// Add product to cart with optional modifier selections
  void addProduct(
    Product product, {
    int quantity = 1,
    List<SelectedModifier> selectedModifiers = const [],
  }) {
    state = state.addProduct(
      product,
      quantity: quantity,
      selectedModifiers: selectedModifiers,
    );
  }

  /// Remove item from cart
  void removeItem(String productId) {
    state = state.removeItem(productId);
  }

  /// Update item quantity
  bool updateQuantity(String productId, int quantity) {
    final currentItem =
        state.items.where((item) => item.productId == productId).firstOrNull;
    if (currentItem == null) return false;

    state = state.updateQuantity(productId, quantity);
    return true;
  }

  /// Increment item quantity with stock validation
  bool incrementQuantity(String productId) {
    final currentItem =
        state.items.where((item) => item.productId == productId).firstOrNull;
    if (currentItem == null) return false;

    final newQuantity = currentItem.quantity + 1;
    return updateQuantity(productId, newQuantity);
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

/// Cart provider with dependency injection
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
