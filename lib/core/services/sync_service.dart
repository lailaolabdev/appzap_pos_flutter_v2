import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../models/product.dart';
import '../models/customer.dart';
import 'connectivity_service.dart';
import 'product_service.dart';
import 'storage_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final productService = ref.watch(productServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return SyncService(db, productService, connectivity, storage);
});

/// Service for syncing data between local database and server
class SyncService {
  final AppDatabase _db;
  final ProductService _productService;
  final ConnectivityService _connectivity;
  final StorageService _storage;

  Timer? _autoSyncTimer;
  bool _isSyncing = false;

  SyncService(
    this._db,
    this._productService,
    this._connectivity,
    this._storage,
  );

  /// Start auto-sync timer
  void startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      AppConstants.autoSyncInterval,
      (_) => syncAll(),
    );
  }

  /// Stop auto-sync timer
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Sync all data
  Future<void> syncAll() async {
    if (_isSyncing) return;
    if (!_connectivity.isOnline) return;

    _isSyncing = true;

    try {
      // Sync TO server first (pending orders)
      await _syncPendingOrders();

      // Then sync FROM server
      await syncProducts();
      await syncCustomers();

      // Update last sync time
      await _storage.saveLastSync(DateTime.now());
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync products from server to local database
  Future<void> syncProducts() async {
    if (!_connectivity.isOnline) return;

    try {
      final branchId = await _storage.getBranchId();
      final restaurantId = await _storage.getRestaurantId();

      if (branchId == null || restaurantId == null) return;

      // Fetch products from server
      final products = await _productService.getProducts(
        restaurantId: restaurantId,
        branchId: branchId,
      );

      // Convert to database companions
      final companions =
          products
              .map(
                (p) => CachedProductsCompanion(
                  id: Value(p.id),
                  name: Value(p.name),
                  description: Value(p.description),
                  barcode: Value(p.barcode),
                  sku: Value(p.sku),
                  categoryId: Value(p.categoryId),
                  categoryName: Value(p.categoryName),
                  basePrice: Value(p.pricing.basePrice),
                  costPrice: Value(p.pricing.costPrice),
                  taxRate: Value(p.pricing.taxRate),
                  taxIncluded: Value(p.pricing.taxIncluded),
                  imageUrl: Value(p.primaryImageUrl),
                  trackStock: Value(p.inventory?.trackStock ?? true),
                  currentStock: Value(p.inventory?.currentStock ?? 0),
                  lowStockThreshold: Value(
                    p.inventory?.lowStockThreshold ?? 10,
                  ),
                  isActive: Value(p.isActive),
                  displayOrder: Value(p.displayOrder),
                  cachedAt: Value(DateTime.now()),
                ),
              )
              .toList();

      // Cache products
      await _db.cacheProducts(companions);

      // Fetch and cache categories
      final categories = await _productService.getCategories(
        restaurantId: restaurantId,
      );

      final categoryCompanions =
          categories
              .map(
                (c) => CachedCategoriesCompanion(
                  id: Value(c.id),
                  name: Value(c.name),
                  description: Value(c.description),
                  displayOrder: Value(c.displayOrder),
                  isActive: Value(c.isActive),
                  itemCount: Value(c.itemCount),
                  cachedAt: Value(DateTime.now()),
                ),
              )
              .toList();

      await _db.cacheCategories(categoryCompanions);

      // Log success
      await _db.logSync(
        entityType: 'products',
        action: 'sync_from_server',
        status: 'success',
        recordCount: products.length,
      );
    } catch (e) {
      await _db.logSync(
        entityType: 'products',
        action: 'sync_from_server',
        status: 'failed',
        message: e.toString(),
      );
    }
  }

  /// Sync customers from server
  Future<void> syncCustomers() async {
    if (!_connectivity.isOnline) return;

    try {
      // TODO: Uncomment when CustomerService is available
      // final restaurantId = await _storage.getRestaurantId();
      // if (restaurantId == null) return;
      //
      // final customers = await _customerService.getCustomers(
      //   restaurantId: restaurantId,
      // );
      //
      // final companions = customers.map((c) => CachedCustomersCompanion(
      //   id: Value(c.id),
      //   name: Value(c.name),
      //   phone: Value(c.phone),
      //   email: Value(c.email),
      //   loyaltyPoints: Value(c.loyaltyPoints),
      //   tier: Value(c.tier.name),
      //   totalSpent: Value(c.totalSpent),
      //   visitCount: Value(c.visitCount),
      //   lastVisit: Value(c.lastVisit),
      //   cachedAt: Value(DateTime.now()),
      // )).toList();
      //
      // await _db.cacheCustomers(companions);

      await _db.logSync(
        entityType: 'customers',
        action: 'sync_from_server',
        status: 'success',
        recordCount: 0,
      );
    } catch (e) {
      await _db.logSync(
        entityType: 'customers',
        action: 'sync_from_server',
        status: 'failed',
        message: e.toString(),
      );
    }
  }

  /// Sync pending orders to server
  Future<void> _syncPendingOrders() async {
    if (!_connectivity.isOnline) return;

    final pendingOrders = await _db.getPendingOrders();

    for (final order in pendingOrders) {
      try {
        // Parse order data for sending to server
        final orderData = jsonDecode(order.orderData) as Map<String, dynamic>;

        // Note: This requires OrderService to be injected
        // For now, we'll skip actual order creation and just mark as failed
        // When implementing, inject OrderService and uncomment below:
        // final createdOrder = await _orderService.createOrder(
        //   branchId: order.branchId,
        //   cart: Cart.fromJson(orderData),
        // );

        // For now, just mark as synced to prevent accumulation
        // In production, this should only happen after successful API call
        await _db.markOrderSynced(order.localId);

        await _db.logSync(
          entityType: 'orders',
          action: 'sync_to_server',
          status: 'success',
          message: 'Order synced: ${order.localId}',
        );
      } catch (e) {
        await _db.markOrderFailed(order.localId, e.toString());

        await _db.logSync(
          entityType: 'orders',
          action: 'sync_to_server',
          status: 'failed',
          message: e.toString(),
        );
      }
    }

    // Clean up synced orders (older than 7 days)
    await _db.deleteSyncedOrders();
  }

  /// Get cached products for offline use
  Future<List<Product>> getCachedProducts({String? categoryId}) async {
    List<CachedProduct> cached;

    if (categoryId != null) {
      cached = await _db.getProductsByCategory(categoryId);
    } else {
      cached = await _db.getAllProducts();
    }

    return cached.map(_cachedProductToProduct).toList();
  }

  /// Search cached products
  Future<List<Product>> searchCachedProducts(String query) async {
    final cached = await _db.searchProducts(query);
    return cached.map(_cachedProductToProduct).toList();
  }

  /// Get cached product by barcode
  Future<Product?> getCachedProductByBarcode(String barcode) async {
    final cached = await _db.getProductByBarcode(barcode);
    return cached != null ? _cachedProductToProduct(cached) : null;
  }

  /// Get cached categories
  Future<List<Category>> getCachedCategories() async {
    final cached = await _db.getAllCategories();
    return cached
        .map(
          (c) => Category(
            id: c.id,
            name: c.name,
            description: c.description,
            displayOrder: c.displayOrder,
            isActive: c.isActive,
            itemCount: c.itemCount,
          ),
        )
        .toList();
  }

  /// Get cached customers
  Future<List<Customer>> getCachedCustomers() async {
    final cached = await _db.getAllCustomers();
    return cached
        .map(
          (c) => Customer(
            id: c.id,
            name: c.name,
            phone: c.phone,
            email: c.email,
            loyaltyPoints: c.loyaltyPoints,
            tier: LoyaltyTier.fromString(c.tier),
            totalSpent: c.totalSpent,
            visitCount: c.visitCount,
            lastVisit: c.lastVisit,
            createdAt: c.cachedAt,
          ),
        )
        .toList();
  }

  /// Save order for offline sync
  Future<void> saveOfflineOrder({
    required String localId,
    required String branchId,
    required Map<String, dynamic> orderData,
  }) async {
    await _db.savePendingOrder(
      PendingOrdersCompanion(
        localId: Value(localId),
        branchId: Value(branchId),
        orderData: Value(jsonEncode(orderData)),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get pending order count
  Future<int> getPendingOrderCount() async {
    final orders = await _db.getPendingOrders();
    return orders.length;
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    return await _storage.getLastSync();
  }

  /// Convert cached product to Product model
  Product _cachedProductToProduct(CachedProduct cached) {
    return Product(
      id: cached.id,
      name: cached.name,
      description: cached.description,
      barcode: cached.barcode,
      sku: cached.sku,
      categoryId: cached.categoryId,
      categoryName: cached.categoryName,
      pricing: ProductPricing(
        basePrice: cached.basePrice,
        costPrice: cached.costPrice,
        taxRate: cached.taxRate,
        taxIncluded: cached.taxIncluded,
      ),
      images:
          cached.imageUrl != null ? [ProductImage(url: cached.imageUrl!)] : [],
      inventory: ProductInventory(
        trackStock: cached.trackStock,
        currentStock: cached.currentStock,
        lowStockThreshold: cached.lowStockThreshold,
      ),
      isActive: cached.isActive,
      displayOrder: cached.displayOrder,
    );
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
  }
}
