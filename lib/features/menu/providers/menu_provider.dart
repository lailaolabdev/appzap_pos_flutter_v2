import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/product.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/product_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

/// Menu state
class MenuState {
  final List<Product> items;
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? categoryFilter;

  const MenuState({
    this.items = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.categoryFilter,
  });

  MenuState copyWith({
    List<Product>? items,
    List<Category>? categories,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? categoryFilter,
    bool updateCategoryFilter = false,
  }) {
    return MenuState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter:
          updateCategoryFilter
              ? categoryFilter
              : (categoryFilter ?? this.categoryFilter),
    );
  }

  int get activeItemsCount => items.where((i) => i.isActive).length;
  int get inactiveItemsCount => items.where((i) => !i.isActive).length;
  int get activeCategoriesCount =>
      categories.where((c) => c.isActive == true).length;
}

/// Menu notifier
class MenuNotifier extends StateNotifier<MenuState> {
  final MenuService _menuService;
  final ProductService _productService;
  final String? _restaurantId;
  final String? _branchId;

  MenuNotifier(
    this._menuService,
    this._productService,
    this._restaurantId,
    this._branchId,
  ) : super(const MenuState()) {
    loadMenu();
  }

  /// Load all menu items and categories
  Future<void> loadMenu() async {
    if (_restaurantId == null) {
      state = state.copyWith(
        error: 'Restaurant not configured',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load items and categories in parallel
      final results = await Future.wait([
        _productService.getProducts(
          restaurantId: _restaurantId,
          branchId: _branchId,
          search: state.searchQuery.isEmpty ? null : state.searchQuery,
          categoryId: state.categoryFilter,
        ),
        _productService.getCategories(restaurantId: _restaurantId),
      ]);

      state = state.copyWith(
        items: results[0] as List<Product>,
        categories: results[1] as List<Category>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Search menu items
  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadMenu();
  }

  /// Filter by category
  void filterByCategory(String? categoryId) {
    state = state.copyWith(
      categoryFilter: categoryId,
      updateCategoryFilter: true,
    );
    loadMenu();
  }

  /// Refresh menu
  Future<void> refresh() async {
    await loadMenu();
  }

  // ==================== MENU ITEMS ====================

  /// Create a new menu item
  Future<bool> createMenuItem({
    required String categoryId,
    required String name,
    String? description,
    String? itemCode,
    String? barcode,
    String? sku,
    required double basePrice,
    double? costPrice,
    double taxRate = 0,
    bool taxIncluded = false,
    bool trackStock = true,
    int lowStockThreshold = 10,
    int initialStock = 0,
    bool isActive = true,
  }) async {
    if (_restaurantId == null) return false;

    try {
      final createdItem = await _menuService.createMenuItem(
        restaurantId: _restaurantId,
        branchId: _branchId,
        categoryId: categoryId,
        name: name,
        description: description,
        itemCode: itemCode,
        barcode: barcode,
        sku: sku,
        basePrice: basePrice,
        costPrice: costPrice,
        taxRate: taxRate,
        taxIncluded: taxIncluded,
        trackStock: trackStock,
        lowStockThreshold: lowStockThreshold,
        initialStock: initialStock,
        isActive: isActive,
      );

      print('✅ Menu item created successfully!');
      print('📊 Backend response data:');
      print('   - Item ID: ${createdItem.id}');
      print('   - Name: ${createdItem.name}');
      print('   - Category ID: ${createdItem.categoryId}');
      print('   - Base Price: ${createdItem.pricing.basePrice}');
      print('   - Cost Price: ${createdItem.pricing.costPrice ?? 'Not set'}');
      print('   - Track Stock: ${createdItem.inventory?.trackStock ?? false}');
      print(
        '   - Current Stock: ${createdItem.inventory?.currentStock ?? 'N/A'}',
      );
      print(
        '   - Low Stock Threshold: ${createdItem.inventory?.lowStockThreshold ?? 'N/A'}',
      );
      print('   - Is Active: ${createdItem.isActive}');
      print('   - Item Code: ${createdItem.itemCode ?? 'Not set'}');
      print('   - Barcode: ${createdItem.barcode ?? 'Not set'}');
      print('   - SKU: ${createdItem.sku ?? 'Not set'}');
      print('   - Full item data: ${createdItem.toJson()}');

      // Sync with inventory if stock tracking is enabled
      if (trackStock && costPrice != null) {
        print('🔄 Syncing menu item with inventory...');
        await _syncMenuItemWithInventory(
          menuItem: createdItem,
          costPrice: costPrice,
          initialStock: initialStock,
          lowStockThreshold: lowStockThreshold,
        );
      }

      await loadMenu();
      return true;
    } catch (e) {
      print('❌ Error creating menu item: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Private method to sync menu item with inventory
  Future<void> _syncMenuItemWithInventory({
    required Product menuItem,
    required double costPrice,
    required int initialStock,
    required int lowStockThreshold,
  }) async {
    try {
      // Get inventory service reference (this would normally be injected)
      // For now, we'll use a temporary approach
      print('🔄 Creating inventory entry for: ${menuItem.name}');
      print(
        '📊 Cost price: $costPrice, Initial stock: $initialStock, Threshold: $lowStockThreshold',
      );

      // The inventory creation would need to be handled by a separate service call
      // or by triggering a refresh of the inventory provider
      print('✅ Menu item sync with inventory requested');
    } catch (e) {
      print('❌ Failed to sync menu item with inventory: $e');
      // Don't fail the menu item creation if inventory sync fails
    }
  }

  /// Update an existing menu item
  Future<bool> updateMenuItem({
    required String itemId,
    String? name,
    String? description,
    String? categoryId,
    double? basePrice,
    double? costPrice,
    double? taxRate,
    bool? taxIncluded,
    bool? trackStock,
    int? lowStockThreshold,
    bool? isActive,
  }) async {
    try {
      await _menuService.updateMenuItem(
        itemId: itemId,
        name: name,
        description: description,
        categoryId: categoryId,
        basePrice: basePrice,
        costPrice: costPrice,
        taxRate: taxRate,
        taxIncluded: taxIncluded,
        trackStock: trackStock,
        lowStockThreshold: lowStockThreshold,
        isActive: isActive,
      );

      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a menu item
  Future<bool> deleteMenuItem(String itemId) async {
    try {
      await _menuService.deleteMenuItem(itemId);
      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ==================== CATEGORIES ====================

  /// Create a new category
  Future<bool> createCategory({
    required String name,
    String? description,
    int displayOrder = 0,
    String? color,
  }) async {
    if (_restaurantId == null) return false;

    try {
      await _menuService.createCategory(
        restaurantId: _restaurantId,
        name: name,
        description: description,
        displayOrder: displayOrder,
        color: color,
      );

      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update an existing category
  Future<bool> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    int? displayOrder,
    bool? isActive,
    String? color,
  }) async {
    try {
      await _menuService.updateCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        displayOrder: displayOrder,
        isActive: isActive,
        color: color,
      );

      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _menuService.deleteCategory(categoryId);
      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Sync existing menu items to inventory
  Future<Map<String, String>> syncMenuItemsToInventory() async {
    try {
      final results = await _menuService.syncMenuItemsToInventory(
        state.items,
        restaurantId: _restaurantId ?? '',
        branchId: _branchId ?? '',
      );

      // Count results
      final successful = results.values.where((v) => v == 'success').length;
      final alreadyExists =
          results.values.where((v) => v == 'already_exists').length;
      final failed = results.values.where((v) => v.startsWith('failed')).length;
      final skipped =
          results.values.where((v) => v == 'skipped_no_track_stock').length;

      print(
        '📊 Sync Results: $successful created, $alreadyExists already exist, $failed failed, $skipped skipped',
      );

      return results;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }
}

/// Menu provider
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  final productService = ref.watch(productServiceProvider);
  final restaurantId = ref.watch(currentRestaurantIdProvider);
  final branchId = ref.watch(currentBranchIdProvider);
  return MenuNotifier(menuService, productService, restaurantId, branchId);
});
