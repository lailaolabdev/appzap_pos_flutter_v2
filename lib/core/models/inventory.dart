import 'package:equatable/equatable.dart';

/// Unit of measure model
class UnitOfMeasure extends Equatable {
  final String name;
  final String abbreviation;
  final String category; // weight, volume, count, length

  const UnitOfMeasure({
    required this.name,
    required this.abbreviation,
    required this.category,
  });

  factory UnitOfMeasure.fromJson(Map<String, dynamic> json) {
    return UnitOfMeasure(
      name: json['name']?.toString() ?? '',
      abbreviation: json['abbreviation']?.toString() ?? '',
      category: json['category']?.toString() ?? 'count',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'abbreviation': abbreviation, 'category': category};
  }

  @override
  List<Object?> get props => [name, abbreviation, category];
}

/// Inventory item model
class InventoryItem extends Equatable {
  final String id;
  final String? itemId; // ✅ Menu item ID (reference to the menu/product item)
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String category; // ingredient, finished_good, raw_material
  final UnitOfMeasure unitOfMeasure;
  final int currentStock;
  final int availableStock;
  final int reservedStock;
  final double costPerUnit;
  final double? sellingPrice;
  final int minStockLevel;
  final int maxStockLevel;
  final String status; // active, inactive
  final String restaurantId;
  final String branchId;
  final DateTime? lastStockUpdate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Legacy support
  double get costPrice => costPerUnit;
  double get averageCost => costPerUnit;
  double get totalValue => currentStock * costPerUnit;
  int get lowStockThreshold => minStockLevel;
  bool get isLowStock => currentStock <= minStockLevel;
  String get unit => unitOfMeasure.abbreviation;

  const InventoryItem({
    required this.id,
    this.itemId, // ✅ Menu item ID (optional for backward compatibility)
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    this.category = 'ingredient',
    required this.unitOfMeasure,
    required this.currentStock,
    required this.availableStock,
    this.reservedStock = 0,
    required this.costPerUnit,
    this.sellingPrice,
    this.minStockLevel = 10,
    this.maxStockLevel = 500,
    this.status = 'active',
    required this.restaurantId,
    required this.branchId,
    this.lastStockUpdate,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Handle unit of measure
    UnitOfMeasure unitOfMeasure;
    if (json['unitOfMeasure'] != null && json['unitOfMeasure'] is Map) {
      unitOfMeasure = UnitOfMeasure.fromJson(
        json['unitOfMeasure'] as Map<String, dynamic>,
      );
    } else {
      // Fallback for legacy format
      final unitStr = json['unit']?.toString() ?? 'unit';
      unitOfMeasure = UnitOfMeasure(
        name: unitStr,
        abbreviation: unitStr,
        category: 'count',
      );
    }

    // Debug parsing for minStockLevel
    final minStockFromJson = (json['minStockLevel'] as num?)?.toInt();
    final lowStockFromJson = (json['lowStockThreshold'] as num?)?.toInt();
    final finalMinStock = minStockFromJson ?? lowStockFromJson ?? 10;


    return InventoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString(), // ✅ Parse the menu item ID
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      category: json['category']?.toString() ?? 'ingredient',
      unitOfMeasure: unitOfMeasure,
      currentStock:
          (json['currentStock'] as num?)?.toInt() ??
          (json['availableStock'] as num?)?.toInt() ??
          (json['totalStock'] as num?)?.toInt() ??
          0,
      availableStock:
          (json['availableStock'] as num?)?.toInt() ??
          (json['currentStock'] as num?)?.toInt() ??
          0,
      reservedStock: (json['reservedStock'] as num?)?.toInt() ?? 0,
      costPerUnit:
          (json['costPerUnit'] as num?)?.toDouble() ??
          (json['standardCost'] as num?)?.toDouble() ??
          (json['averageCost'] as num?)?.toDouble() ??
          (json['lastPurchaseCost'] as num?)?.toDouble() ??
          (json['costPrice'] as num?)?.toDouble() ??
          0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
      minStockLevel: finalMinStock,
      maxStockLevel: (json['maxStockLevel'] as num?)?.toInt() ?? 500,
      status: json['status']?.toString() ?? 'active',
      restaurantId: json['restaurantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      lastStockUpdate:
          json['lastStockUpdate'] != null
              ? DateTime.tryParse(json['lastStockUpdate'].toString())
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (itemId != null) 'itemId': itemId, // ✅ Include the menu item ID
      'name': name,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      'category': category,
      'unitOfMeasure': unitOfMeasure.toJson(),
      'currentStock': currentStock,
      'availableStock': availableStock,
      'reservedStock': reservedStock,
      'costPerUnit': costPerUnit,
      if (sellingPrice != null) 'sellingPrice': sellingPrice,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'status': status,
      'restaurantId': restaurantId,
      'branchId': branchId,
      if (lastStockUpdate != null)
        'lastStockUpdate': lastStockUpdate!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    itemId, // ✅ Include the menu item ID in equality comparison
    name,
    description,
    sku,
    barcode,
    category,
    unitOfMeasure,
    currentStock,
    availableStock,
    reservedStock,
    costPerUnit,
    sellingPrice,
    minStockLevel,
    maxStockLevel,
    status,
    restaurantId,
    branchId,
    lastStockUpdate,
    createdAt,
    updatedAt,
  ];
}

/// Stock adjustment operation
enum StockOperation {
  add,
  remove,
  set;

  String toUpperCase() => name.toUpperCase();
}

/// Stock adjustment request - Fixed for backend compatibility
class StockAdjustment {
  final String inventoryItemId;
  final String branchId;
  final StockOperation operation;
  final int quantity;
  final String reason;
  final String? notes;
  final double? costPrice;

  const StockAdjustment({
    required this.inventoryItemId,
    required this.branchId,
    required this.operation,
    required this.quantity,
    required this.reason,
    this.notes,
    this.costPrice,
  });

  /// Fixed JSON format based on API documentation
  Map<String, dynamic> toJson() {
    return {
      'inventoryItemId': inventoryItemId, // Direct field, not in items array
      'branchId': branchId,
      'operation': operation.name.toUpperCase(),
      'quantity': quantity,
      'reason': reason,
      if (notes != null) 'notes': notes,
      if (costPrice != null) 'unitCost': costPrice,
    };
  }
}

/// Stock adjustment result
class StockAdjustmentResult extends Equatable {
  final String transactionId;
  final int previousStock;
  final int newStock;
  final String operation;
  final int quantity;

  const StockAdjustmentResult({
    required this.transactionId,
    required this.previousStock,
    required this.newStock,
    required this.operation,
    required this.quantity,
  });

  factory StockAdjustmentResult.fromJson(Map<String, dynamic> json) {
    return StockAdjustmentResult(
      transactionId: json['transactionId']?.toString() ?? '',
      previousStock: (json['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (json['newStock'] as num?)?.toInt() ?? 0,
      operation: json['operation']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    transactionId,
    previousStock,
    newStock,
    operation,
    quantity,
  ];
}

/// Inventory alert
class InventoryAlert extends Equatable {
  final String id;
  final String inventoryItemId;
  final String? itemName; // Made nullable since API might not always provide it
  final String alertType;
  final int currentStock;
  final int? threshold;
  final String severity;
  final DateTime createdAt;

  const InventoryAlert({
    required this.id,
    required this.inventoryItemId,
    this.itemName, // Now optional
    required this.alertType,
    required this.currentStock,
    this.threshold,
    this.severity = 'warning',
    required this.createdAt,
  });

  factory InventoryAlert.fromJson(Map<String, dynamic> json) {
    return InventoryAlert(
      id: json['_id']?.toString() ?? '',
      inventoryItemId: json['inventoryItemId']?.toString() ?? '',
      itemName: json['itemName']?.toString(), // Keep as null if not provided
      alertType: json['alertType']?.toString() ?? 'low_stock',
      currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
      threshold: (json['threshold'] as num?)?.toInt(),
      severity: json['severity']?.toString() ?? 'warning',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  // Helper getter for display name
  String get displayName {
    if (itemName != null && itemName!.isNotEmpty) {
      return itemName!;
    }

    if (inventoryItemId.isEmpty) {
      return 'Unknown Item';
    }

    // Safely substring to avoid RangeError
    final idLength = inventoryItemId.length;
    final substringLength = idLength >= 8 ? 8 : idLength;
    return 'Item ${inventoryItemId.substring(0, substringLength)}${idLength > 8 ? '...' : ''}';
  }

  bool get isLowStock => alertType == 'low_stock';
  bool get isOutOfStock => alertType == 'out_of_stock';
  bool get isExpiringSoon => alertType == 'expiring_soon';

  @override
  List<Object?> get props => [
    id,
    inventoryItemId,
    itemName,
    alertType,
    currentStock,
    threshold,
    severity,
    createdAt,
  ];
}

/// Purchase order item
class PurchaseOrderItem {
  final String inventoryItemId;
  final int quantity;
  final double unitCost;

  const PurchaseOrderItem({
    required this.inventoryItemId,
    required this.quantity,
    required this.unitCost,
  });

  Map<String, dynamic> toJson() {
    return {
      'inventoryItemId': inventoryItemId,
      'quantity': quantity,
      'unitCost': unitCost,
    };
  }
}

/// Purchase order
class PurchaseOrder extends Equatable {
  final String id;
  final String branchId;
  final String? supplierId;
  final List<dynamic> items;
  final String? expectedDeliveryDate;
  final String status;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;

  const PurchaseOrder({
    required this.id,
    required this.branchId,
    this.supplierId,
    this.items = const [],
    this.expectedDeliveryDate,
    this.status = 'pending',
    this.totalAmount = 0,
    this.notes,
    required this.createdAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['_id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      supplierId: json['supplierId']?.toString(),
      items: json['items'] as List<dynamic>? ?? [],
      expectedDeliveryDate: json['expectedDeliveryDate']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    branchId,
    supplierId,
    items,
    expectedDeliveryDate,
    status,
    totalAmount,
    notes,
    createdAt,
  ];
}

/// Inventory valuation
class InventoryValuation extends Equatable {
  final double totalValue;
  final int totalItems;
  final String currency;
  final DateTime lastUpdated;

  const InventoryValuation({
    required this.totalValue,
    required this.totalItems,
    this.currency = 'LAK',
    required this.lastUpdated,
  });

  factory InventoryValuation.fromJson(Map<String, dynamic> json) {
    return InventoryValuation(
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'LAK',
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.tryParse(json['lastUpdated'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [totalValue, totalItems, currency, lastUpdated];
}

/// Request model for creating new inventory items
class CreateInventoryItemRequest {
  final String? itemId; // ✅ Menu item ID reference
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String category;
  final UnitOfMeasure unitOfMeasure;
  final double costPerUnit;
  final double? sellingPrice;
  final int minStockLevel;
  final int maxStockLevel;
  final String status;

  const CreateInventoryItemRequest({
    this.itemId, // ✅ Menu item ID reference
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    this.category = 'ingredient',
    required this.unitOfMeasure,
    required this.costPerUnit,
    this.sellingPrice,
    this.minStockLevel = 10,
    this.maxStockLevel = 500,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'itemId': itemId, // ✅ Include menu item ID
      'name': name,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      'category': category,
      'unitOfMeasure': unitOfMeasure.toJson(),
      'costPerUnit': costPerUnit,
      if (sellingPrice != null) 'sellingPrice': sellingPrice,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'status': status,
    };
  }
}

/// Request model for updating inventory items
class UpdateInventoryItemRequest {
  final String? name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? category;
  final UnitOfMeasure? unitOfMeasure;
  final double? costPerUnit;
  final double? sellingPrice;
  final int? minStockLevel;
  final int? maxStockLevel;
  final String? status;

  const UpdateInventoryItemRequest({
    this.name,
    this.description,
    this.sku,
    this.barcode,
    this.category,
    this.unitOfMeasure,
    this.costPerUnit,
    this.sellingPrice,
    this.minStockLevel,
    this.maxStockLevel,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (sku != null) data['sku'] = sku;
    if (barcode != null) data['barcode'] = barcode;
    if (category != null) data['category'] = category;
    if (unitOfMeasure != null) data['unitOfMeasure'] = unitOfMeasure!.toJson();
    if (costPerUnit != null) data['costPerUnit'] = costPerUnit;
    if (sellingPrice != null) data['sellingPrice'] = sellingPrice;
    if (minStockLevel != null) data['minStockLevel'] = minStockLevel;
    if (maxStockLevel != null) data['maxStockLevel'] = maxStockLevel;
    if (status != null) data['status'] = status;
    return data;
  }
}

/// Stock transfer request
class StockTransferRequest {
  final String itemId;
  final String fromBranchId;
  final String toBranchId;
  final int quantity;
  final String reason;
  final String? notes;

  const StockTransferRequest({
    required this.itemId,
    required this.fromBranchId,
    required this.toBranchId,
    required this.quantity,
    required this.reason,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'fromBranchId': fromBranchId,
      'toBranchId': toBranchId,
      'quantity': quantity,
      'reason': reason,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Stock transfer result
class StockTransferResult extends Equatable {
  final String transactionId;
  final String itemId;
  final String fromBranchId;
  final String toBranchId;
  final int quantity;
  final String status;
  final DateTime transferredAt;

  const StockTransferResult({
    required this.transactionId,
    required this.itemId,
    required this.fromBranchId,
    required this.toBranchId,
    required this.quantity,
    required this.status,
    required this.transferredAt,
  });

  factory StockTransferResult.fromJson(Map<String, dynamic> json) {
    return StockTransferResult(
      transactionId: json['transactionId']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      fromBranchId: json['fromBranchId']?.toString() ?? '',
      toBranchId: json['toBranchId']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'completed',
      transferredAt:
          json['transferredAt'] != null
              ? DateTime.tryParse(json['transferredAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    transactionId,
    itemId,
    fromBranchId,
    toBranchId,
    quantity,
    status,
    transferredAt,
  ];
}

/// Stock transaction history
class StockTransaction extends Equatable {
  final String id;
  final String itemId;
  final String? itemName;
  final String branchId;
  final String type; // PURCHASE, SALE, ADJUSTMENT, TRANSFER, WASTE, COUNT
  final String operation; // ADD, REMOVE, SET
  final int quantity;
  final int? previousStock;
  final int? newStock;
  final String reason;
  final String? notes;
  final String? userId;
  final DateTime createdAt;

  const StockTransaction({
    required this.id,
    required this.itemId,
    this.itemName,
    required this.branchId,
    required this.type,
    required this.operation,
    required this.quantity,
    this.previousStock,
    this.newStock,
    required this.reason,
    this.notes,
    this.userId,
    required this.createdAt,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString(),
      branchId: json['branchId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ADJUSTMENT',
      operation: json['operation']?.toString() ?? 'SET',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (json['previousStock'] as num?)?.toInt(),
      newStock: (json['newStock'] as num?)?.toInt(),
      reason: json['reason']?.toString() ?? '',
      notes: json['notes']?.toString(),
      userId: json['userId']?.toString(),
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemId,
    itemName,
    branchId,
    type,
    operation,
    quantity,
    previousStock,
    newStock,
    reason,
    notes,
    userId,
    createdAt,
  ];
}

/// System health check result
class InventoryHealthCheck extends Equatable {
  final String status; // healthy, warning, critical
  final String message;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  const InventoryHealthCheck({
    required this.status,
    required this.message,
    this.details,
    required this.timestamp,
  });

  factory InventoryHealthCheck.fromJson(Map<String, dynamic> json) {
    return InventoryHealthCheck(
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      details: json['details'] as Map<String, dynamic>?,
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now(),
    );
  }

  bool get isHealthy => status == 'healthy';
  bool get hasWarning => status == 'warning';
  bool get isCritical => status == 'critical';

  @override
  List<Object?> get props => [status, message, details, timestamp];
}
