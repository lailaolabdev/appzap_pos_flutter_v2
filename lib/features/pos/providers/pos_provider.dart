import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cart.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/product.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/inventory_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

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
      print('\\n📦 === LOADING PRODUCTS ===');
      print('   Restaurant ID: $_restaurantId');
      print('   Branch ID: $_branchId');

      final results = await Future.wait([
        _productService.getProducts(
          restaurantId: _restaurantId,
          branchId: _branchId,
        ),
        _productService.getCategories(restaurantId: _restaurantId),
      ]);

      final products = results[0] as List<Product>;
      final categories = results[1] as List<Category>;

      print('   Loaded ${products.length} products:');
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        print(
          '      [$i] ${product.name} (ID: ${product.id}) - In Stock: ${product.isInStock}',
        );
      }
      print('   Loaded ${categories.length} categories');

      // ✅ NEW: Merge with inventory data
      print('\\n📦 === MERGING INVENTORY DATA ===');
      final mergedProducts = await _mergeWithInventoryData(products);
      print('=== END MERGING INVENTORY DATA ===\\n');

      print('=== END LOADING PRODUCTS ===\\n');

      state = state.copyWith(
        products: mergedProducts,
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Error loading products: $e');
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

      print(
        '   📊 Loaded ${inventoryItems.length} inventory items for merging',
      );

      // Create a map for quick lookup: itemId -> inventory data
      final inventoryMap = <String, dynamic>{};
      print('   🔍 Building inventory lookup map:');
      for (final item in inventoryItems) {
        if (item.itemId != null) {
          print(
            '      - ${item.name}: itemId=${item.itemId}, stock=${item.currentStock}, threshold=${item.lowStockThreshold}',
          );
          inventoryMap[item.itemId!] = {
            'currentStock': item.currentStock,
            'lowStockThreshold': item.lowStockThreshold,
            'isLowStock': item.isLowStock,
            'unit': item.unit,
          };
        } else {
          print('      - ${item.name}: ❌ No itemId found');
        }
      }
      print('   📊 Inventory map has ${inventoryMap.length} entries');

      // Merge inventory data with products
      final mergedProducts =
          products.map((product) {
            print(
              '   🔍 Looking for inventory data for ${product.name} (ID: ${product.id})',
            );
            final inventoryData = inventoryMap[product.id];

            if (inventoryData != null) {
              print(
                '   ✅ Found inventory for ${product.name}: stock=${inventoryData['currentStock']}, threshold=${inventoryData['lowStockThreshold']}',
              );

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
              print(
                '   ⚠️  No inventory data found for ${product.name} (ID: ${product.id})',
              );
              print(
                '      Available inventory itemIds: ${inventoryMap.keys.toList()}',
              );
              return product;
            }
          }).toList();

      container.dispose();
      return mergedProducts;
    } catch (e) {
      print('❌ Error merging inventory data: $e');
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
    print('🔄 Force refreshing products from API...');
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
        print('🔍 Searching for barcode via API: $barcode');

        if (_branchId == null || _restaurantId == null) {
          print('❌ No branch ID or restaurant ID available for barcode search');
          return null;
        }

        final product = await _productService.getProductByBarcode(
          restaurantId: _restaurantId,
          branchId: _branchId,
          barcode: barcode,
        );

        if (product != null) {
          print('✅ Found product via API: ${product.name}');

          // Add the product to local state for future use
          state = state.copyWith(products: [...state.products, product]);

          return product;
        } else {
          print('❌ Product not found via API for barcode: $barcode');
          return null;
        }
      }
    } catch (e) {
      print('❌ Error searching for product by barcode: $e');
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
    print('🔄 Updating product inventory for ID: $productId');
    print('   - New stock level: $newStockLevel');

    final updatedProducts =
        state.products.map((product) {
          if (product.id == productId) {
            print('   - Found matching product: ${product.name}');
            print(
              '   - Current inventory stock: ${product.inventory?.currentStock ?? "NULL"}',
            );

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

            print(
              '   - Updated inventory stock: ${updatedProduct.inventory?.currentStock}',
            );
            print('   - Updated isInStock: ${updatedProduct.isInStock}');

            return updatedProduct;
          }
          return product;
        }).toList();

    state = state.copyWith(products: updatedProducts);
    print('✅ Product inventory updated successfully');
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

/// Cart notifier with stock validation
class CartNotifier extends StateNotifier<Cart> {
  final StateNotifierProviderRef<CartNotifier, Cart> _ref;

  CartNotifier(this._ref) : super(const Cart());

  /// Add product to cart with stock validation
  bool addProduct(Product product, {int quantity = 1}) {
    print('\n🛒 === ADDING PRODUCT TO CART ===');
    print('   Product: ${product.name}');
    print('   Product ID: ${product.id}');
    print('   Requested quantity: $quantity');
    print('   Product.isInStock: ${product.isInStock}');

    // First check if product is in stock from product model
    if (!product.isInStock) {
      print(
        '❌ REJECTED: Product ${product.name} is marked as out of stock in product model',
      );
      print('   product.isInStock = ${product.isInStock}');
      return false;
    }
    print(
      '✅ Product model check passed: ${product.name} is marked as in stock',
    );

    // Check detailed stock levels from inventory
    print('\n🏪 Checking inventory stock levels...');
    final inventoryNotifier = _ref.read(inventoryProvider.notifier);
    final inventoryState = _ref.read(inventoryProvider);

    print('   Inventory state:');
    print('      Total inventory items loaded: ${inventoryState.items.length}');
    print('      Inventory loading: ${inventoryState.isLoading}');
    print('      Inventory error: ${inventoryState.error}');

    // ✅ ALLOW IMMEDIATE ADDITION: If inventory is loading or has no items yet,
    // allow addition based on product model and defer detailed stock checking
    if (inventoryState.isLoading || inventoryState.items.isEmpty) {
      print(
        '⏳ DEFERRED VALIDATION: Inventory loading or empty, allowing addition based on product model',
      );
      print('   Product shows in stock: ${product.isInStock}');
      print(
        '   Adding ${product.name} to cart (will validate stock when inventory loads)',
      );
      print('=== END CART DEBUG ===\n');

      state = state.addProduct(product, quantity: quantity);
      return true;
    }

    // Look for matching inventory item
    final matchingInventoryItems =
        inventoryState.items
            .where(
              (inv) =>
                  inv.itemId ==
                      product.id || // ✅ Use itemId field for menu item linking
                  inv.id == product.id || // Fallback: direct ID match
                  inv.name.toLowerCase() ==
                      product.name.toLowerCase(), // Fallback: name match
            )
            .toList();

    print('   Searching for inventory item:');
    print('      Looking for ID: ${product.id}');
    print('      Looking for name: ${product.name}');
    print(
      '      Found ${matchingInventoryItems.length} matching inventory items:',
    );

    for (int i = 0; i < matchingInventoryItems.length; i++) {
      final inv = matchingInventoryItems[i];
      print(
        '         [$i] ID: ${inv.id}, Name: ${inv.name}, Stock: ${inv.currentStock}',
      );
    }

    // Calculate total requested quantity (existing in cart + new quantity)
    final currentCartItem =
        state.items.where((item) => item.productId == product.id).firstOrNull;
    final existingQuantityInCart = currentCartItem?.quantity ?? 0;
    final totalRequestedQuantity = existingQuantityInCart + quantity;

    print('   Cart calculations:');
    print('      Existing in cart: $existingQuantityInCart');
    print('      New quantity: $quantity');
    print('      Total requested: $totalRequestedQuantity');

    // Check if we have sufficient stock
    final hasStock = inventoryNotifier.checkStock(
      product.id,
      totalRequestedQuantity,
    );
    final availableStock = inventoryNotifier.getStockLevel(product.id);

    print('   Stock validation results:');
    print(
      '      inventoryNotifier.checkStock(${product.id}, $totalRequestedQuantity): $hasStock',
    );
    print(
      '      inventoryNotifier.getStockLevel(${product.id}): $availableStock',
    );

    if (!hasStock) {
      print('❌ REJECTED: Insufficient stock for ${product.name}');
      print(
        '   Available stock: ${availableStock ?? "NULL (item not found in inventory)"}',
      );
      print('   Requested quantity: $totalRequestedQuantity');
      print('   Reason: Inventory provider checkStock returned false');
      print('   ');
      print('   🔍 DIAGNOSIS:');
      if (availableStock == null) {
        print('      - Item not found in inventory system');
        print('      - Menu item exists but no corresponding inventory item');
        print(
          '      - Check if inventory was created when menu item was added',
        );
      } else if (availableStock == 0) {
        print('      - Item exists in inventory but has 0 stock');
        print('      - Initial stock may not have been set properly');
      } else {
        print(
          '      - Item has $availableStock stock but requesting $totalRequestedQuantity',
        );
        print('      - Not enough stock available');
      }
      print('=== END CART DEBUG ===\n');
      return false;
    }

    print('✅ ACCEPTED: Adding ${product.name} to cart');
    print('   Available stock: ${availableStock ?? "Unknown"}');
    print('   Adding quantity: $quantity');
    print('=== END CART DEBUG ===\n');

    state = state.addProduct(product, quantity: quantity);
    return true;
  }

  /// Remove item from cart
  void removeItem(String productId) {
    state = state.removeItem(productId);
  }

  /// Update item quantity with stock validation
  bool updateQuantity(String productId, int quantity) {
    final currentItem =
        state.items.where((item) => item.productId == productId).firstOrNull;
    if (currentItem == null) return false;

    // Check stock for the new quantity
    final inventoryNotifier = _ref.read(inventoryProvider.notifier);
    if (!inventoryNotifier.checkStock(productId, quantity)) {
      final availableStock = inventoryNotifier.getStockLevel(productId) ?? 0;
      print(
        '❌ Insufficient stock for ${currentItem.productName}: Available $availableStock, Requested $quantity',
      );
      return false;
    }

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
  return CartNotifier(ref);
});

/// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItemsCount;
});

/// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).total;
});
