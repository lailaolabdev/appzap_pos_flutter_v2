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
    bool isActive = true,
  }) async {
    if (_restaurantId == null) return false;

    try {
      await _menuService.createMenuItem(
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
        isActive: isActive,
      );

      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
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
}

/// Menu provider
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  final productService = ref.watch(productServiceProvider);
  final restaurantId = ref.watch(currentRestaurantIdProvider);
  final branchId = ref.watch(currentBranchIdProvider);
  return MenuNotifier(menuService, productService, restaurantId, branchId);
});
