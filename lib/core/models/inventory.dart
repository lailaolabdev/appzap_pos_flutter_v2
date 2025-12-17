import 'package:equatable/equatable.dart';

/// Inventory item model
class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? itemId;
  final String itemType;
  final int currentStock;
  final int lowStockThreshold;
  final bool isLowStock;
  final String unit;
  final double costPrice;
  final double averageCost;
  final double totalValue;
  final DateTime? lastStockUpdate;

  const InventoryItem({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.itemId,
    this.itemType = 'menu_item',
    required this.currentStock,
    this.lowStockThreshold = 10,
    this.isLowStock = false,
    this.unit = 'unit',
    required this.costPrice,
    required this.averageCost,
    required this.totalValue,
    this.lastStockUpdate,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      itemId: json['itemId'] as String?,
      itemType: json['itemType'] as String? ?? 'menu_item',
      currentStock: json['currentStock'] as int? ?? 0,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 10,
      isLowStock: json['isLowStock'] as bool? ?? false,
      unit: json['unit'] as String? ?? 'unit',
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      averageCost: (json['averageCost'] as num?)?.toDouble() ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0,
      lastStockUpdate:
          json['lastStockUpdate'] != null
              ? DateTime.tryParse(json['lastStockUpdate'] as String)
              : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    sku,
    barcode,
    itemId,
    itemType,
    currentStock,
    lowStockThreshold,
    isLowStock,
    unit,
    costPrice,
    averageCost,
    totalValue,
    lastStockUpdate,
  ];
}

/// Stock adjustment operation
enum StockOperation {
  add,
  remove,
  set;

  String toUpperCase() => name.toUpperCase();
}

/// Stock adjustment request
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

  Map<String, dynamic> toJson() {
    return {
      'inventoryItemId': inventoryItemId,
      'branchId': branchId,
      'operation': operation.toUpperCase(),
      'quantity': quantity,
      'reason': reason,
      if (notes != null) 'notes': notes,
      if (costPrice != null) 'costPrice': costPrice,
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
      transactionId: json['transactionId'] as String? ?? '',
      previousStock: json['previousStock'] as int? ?? 0,
      newStock: json['newStock'] as int? ?? 0,
      operation: json['operation'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
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
  final String itemName;
  final String alertType;
  final int currentStock;
  final int? threshold;
  final String severity;
  final DateTime createdAt;

  const InventoryAlert({
    required this.id,
    required this.inventoryItemId,
    required this.itemName,
    required this.alertType,
    required this.currentStock,
    this.threshold,
    this.severity = 'warning',
    required this.createdAt,
  });

  factory InventoryAlert.fromJson(Map<String, dynamic> json) {
    return InventoryAlert(
      id: json['_id'] as String? ?? '',
      inventoryItemId: json['inventoryItemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      alertType: json['alertType'] as String? ?? 'low_stock',
      currentStock: json['currentStock'] as int? ?? 0,
      threshold: json['threshold'] as int?,
      severity: json['severity'] as String? ?? 'warning',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
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
      id: json['_id'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      supplierId: json['supplierId'] as String?,
      items: json['items'] as List<dynamic>? ?? [],
      expectedDeliveryDate: json['expectedDeliveryDate'] as String?,
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
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
      totalItems: json['totalItems'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'LAK',
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'] as String)
              : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [totalValue, totalItems, currency, lastUpdated];
}

