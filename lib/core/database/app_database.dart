import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// ============ TABLE DEFINITIONS ============

/// Cached products table
class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  RealColumn get basePrice => real()();
  RealColumn get costPrice => real().nullable()();
  RealColumn get taxRate => real().withDefault(const Constant(0))();
  BoolColumn get taxIncluded => boolean().withDefault(const Constant(false))();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold =>
      integer().withDefault(const Constant(10))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached categories table
class CachedCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get itemCount => integer().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending orders table (offline orders waiting to sync)
class PendingOrders extends Table {
  TextColumn get localId => text()();
  TextColumn get branchId => text()();
  TextColumn get orderData => text()(); // JSON string of order data
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}

/// Cached customers table
class CachedCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  IntColumn get loyaltyPoints => integer().withDefault(const Constant(0))();
  TextColumn get tier => text().withDefault(const Constant('bronze'))();
  RealColumn get totalSpent => real().withDefault(const Constant(0))();
  IntColumn get visitCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastVisit => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync log table
class SyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // products, orders, customers
  TextColumn get action => text()(); // sync_from_server, sync_to_server
  TextColumn get status => text()(); // success, failed
  TextColumn get message => text().nullable()();
  IntColumn get recordCount => integer().nullable()();
  DateTimeColumn get syncedAt => dateTime()();
}

// ============ DATABASE CLASS ============

@DriftDatabase(
  tables: [
    CachedProducts,
    CachedCategories,
    PendingOrders,
    CachedCustomers,
    SyncLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ============ PRODUCT OPERATIONS ============

  /// Get all cached products
  Future<List<CachedProduct>> getAllProducts() async {
    return await select(cachedProducts).get();
  }

  /// Get products by category
  Future<List<CachedProduct>> getProductsByCategory(String categoryId) async {
    return await (select(cachedProducts)
      ..where((p) => p.categoryId.equals(categoryId))).get();
  }

  /// Search products
  Future<List<CachedProduct>> searchProducts(String query) async {
    final searchPattern = '%$query%';
    return await (select(cachedProducts)..where(
      (p) =>
          p.name.like(searchPattern) |
          p.barcode.like(searchPattern) |
          p.sku.like(searchPattern),
    )).get();
  }

  /// Get product by barcode
  Future<CachedProduct?> getProductByBarcode(String barcode) async {
    return await (select(cachedProducts)
      ..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
  }

  /// Cache products from server
  Future<void> cacheProducts(List<CachedProductsCompanion> products) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedProducts, products);
    });
  }

  /// Clear all cached products
  Future<void> clearProducts() async {
    await delete(cachedProducts).go();
  }

  // ============ CATEGORY OPERATIONS ============

  /// Get all cached categories
  Future<List<CachedCategory>> getAllCategories() async {
    return await (select(cachedCategories)
      ..orderBy([(c) => OrderingTerm.asc(c.displayOrder)])).get();
  }

  /// Cache categories from server
  Future<void> cacheCategories(
    List<CachedCategoriesCompanion> categories,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedCategories, categories);
    });
  }

  // ============ PENDING ORDER OPERATIONS ============

  /// Save pending order (offline)
  Future<void> savePendingOrder(PendingOrdersCompanion order) async {
    await into(pendingOrders).insertOnConflictUpdate(order);
  }

  /// Get all pending orders
  Future<List<PendingOrder>> getPendingOrders() async {
    return await (select(pendingOrders)
          ..where((o) => o.status.equals('pending'))
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
        .get();
  }

  /// Mark order as synced
  Future<void> markOrderSynced(String localId) async {
    await (update(pendingOrders)..where(
      (o) => o.localId.equals(localId),
    )).write(const PendingOrdersCompanion(status: Value('synced')));
  }

  /// Mark order sync failed
  Future<void> markOrderFailed(String localId, String error) async {
    final existing =
        await (select(pendingOrders)
          ..where((o) => o.localId.equals(localId))).getSingle();

    await (update(pendingOrders)
      ..where((o) => o.localId.equals(localId))).write(
      PendingOrdersCompanion(
        status: const Value('failed'),
        syncAttempts: Value(existing.syncAttempts + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Delete synced orders
  Future<void> deleteSyncedOrders() async {
    await (delete(pendingOrders)..where((o) => o.status.equals('synced'))).go();
  }

  // ============ CUSTOMER OPERATIONS ============

  /// Get all cached customers
  Future<List<CachedCustomer>> getAllCustomers() async {
    return await select(cachedCustomers).get();
  }

  /// Search customers
  Future<List<CachedCustomer>> searchCustomers(String query) async {
    final searchPattern = '%$query%';
    return await (select(cachedCustomers)..where(
      (c) => c.name.like(searchPattern) | c.phone.like(searchPattern),
    )).get();
  }

  /// Cache customers from server
  Future<void> cacheCustomers(List<CachedCustomersCompanion> customers) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedCustomers, customers);
    });
  }

  // ============ SYNC LOG OPERATIONS ============

  /// Log sync operation
  Future<void> logSync({
    required String entityType,
    required String action,
    required String status,
    String? message,
    int? recordCount,
  }) async {
    await into(syncLogs).insert(
      SyncLogsCompanion.insert(
        entityType: entityType,
        action: action,
        status: status,
        message: Value(message),
        recordCount: Value(recordCount),
        syncedAt: DateTime.now(),
      ),
    );
  }

  /// Get recent sync logs
  Future<List<SyncLog>> getRecentSyncLogs({int limit = 50}) async {
    return await (select(syncLogs)
          ..orderBy([(s) => OrderingTerm.desc(s.syncedAt)])
          ..limit(limit))
        .get();
  }

  /// Get last successful sync for entity type
  Future<SyncLog?> getLastSuccessfulSync(String entityType) async {
    return await (select(syncLogs)
          ..where(
            (s) => s.entityType.equals(entityType) & s.status.equals('success'),
          )
          ..orderBy([(s) => OrderingTerm.desc(s.syncedAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}

// ============ DATABASE CONNECTION ============

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'appzap_pos.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// ============ PROVIDER ============

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
