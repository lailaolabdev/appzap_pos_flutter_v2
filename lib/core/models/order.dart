import 'package:equatable/equatable.dart';

import 'customer.dart';

/// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  completed,
  cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Order type enum
enum OrderType {
  takeaway,
  dineIn,
  delivery;

  static OrderType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'dinein':
      case 'dine_in':
        return OrderType.dineIn;
      case 'delivery':
        return OrderType.delivery;
      default:
        return OrderType.takeaway;
    }
  }
}

/// Order model
class Order extends Equatable {
  final String id;
  final String orderId;
  final int qNumber;
  final OrderType orderType;
  final OrderStatus status;
  final List<OrderItem> items;
  final OrderPricing pricing;
  final OrderCustomer? customer;
  final OrderStaff? createdBy;
  final String? branchId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;

  const Order({
    required this.id,
    required this.orderId,
    this.qNumber = 0,
    required this.orderType,
    required this.status,
    this.items = const [],
    required this.pricing,
    this.customer,
    this.createdBy,
    this.branchId,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus = 'synced',
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('\n📦 Parsing Order:');
    print('   Order keys: ${json.keys.toList()}');
    
    final id = json['_id'] as String? ?? '';
    final orderId = json['orderId'] as String? ?? json['orderCode'] as String? ?? '';
    print('   id: $id');
    print('   orderId: $orderId');
    
    // Handle both 'items' (Create response) and 'lineItems' (Get response)
    final itemsList = (json['lineItems'] ?? json['items']) as List<dynamic>?;
    print('   Items list length: ${itemsList?.length ?? 0}');
    
    return Order(
      id: id,
      orderId: orderId,
      qNumber: json['qNumber'] as int? ?? 0,
      orderType: OrderType.fromString(
        json['orderType'] as String? ?? 'takeaway',
      ),
      status: OrderStatus.fromString(
        json['orderStatus'] as String? ?? 'pending',
      ),
      items:
          itemsList
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pricing: OrderPricing.fromJson(
        json['pricing'] as Map<String, dynamic>? ?? {},
      ),
      customer:
          json['customer'] != null
              ? OrderCustomer.fromJson(json['customer'] as Map<String, dynamic>)
              : null,
      createdBy:
          json['createdBy'] != null
              ? OrderStaff.fromJson(json['createdBy'] as Map<String, dynamic>)
              : null,
      branchId: json['branchId'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderId': orderId,
      'qNumber': qNumber,
      'orderType': orderType.name,
      'orderStatus': status.name,
      'items': items.map((e) => e.toJson()).toList(),
      'pricing': pricing.toJson(),
      'customer': customer?.toJson(),
      'createdBy': createdBy?.toJson(),
      'branchId': branchId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  /// Check if order is paid
  bool get isPaid => status == OrderStatus.completed;

  /// Check if order can be modified
  bool get canModify =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Check if order is cancelled
  bool get isCancelled => status == OrderStatus.cancelled;

  /// Get total items count
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    String? orderId,
    int? qNumber,
    OrderType? orderType,
    OrderStatus? status,
    List<OrderItem>? items,
    OrderPricing? pricing,
    OrderCustomer? customer,
    OrderStaff? createdBy,
    String? branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Order(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      qNumber: qNumber ?? this.qNumber,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      items: items ?? this.items,
      pricing: pricing ?? this.pricing,
      customer: customer ?? this.customer,
      createdBy: createdBy ?? this.createdBy,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    qNumber,
    orderType,
    status,
    items,
    pricing,
    customer,
    createdBy,
    branchId,
    createdAt,
    updatedAt,
    syncStatus,
  ];
}

/// Order item
class OrderItem extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? notes;
  final double subtotal;
  final double tax;
  final double total;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.notes,
    required this.subtotal,
    this.tax = 0,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    print('  🛒 Parsing OrderItem:');
    print('     Keys: ${json.keys.toList()}');
    
    // Helper function to parse amount (handles both num and MoneyAmount object)
    double parseAmount(dynamic value, String fieldName) {
      print('     $fieldName type: ${value.runtimeType}');
      print('     $fieldName value: $value');
      
      if (value == null) {
        print('     → $fieldName is null, using 0.0');
        return 0.0;
      } else if (value is num) {
        print('     → $fieldName is num: ${value.toDouble()}');
        return value.toDouble();
      } else if (value is Map<String, dynamic>) {
        // MoneyAmount format: { amount: 10000, currency: "LAK" }
        final amount = value['amount'];
        print('     → $fieldName is MoneyAmount, amount: $amount');
        if (amount is num) {
          return amount.toDouble();
        }
        print('     → ⚠️ MoneyAmount.amount is not num!');
        return 0.0;
      } else {
        print('     → ⚠️ $fieldName is unexpected type: ${value.runtimeType}');
        return 0.0;
      }
    }
    
    final id = json['_id'] as String? ?? '';
    final menuItemId = json['menuItemId'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final quantity = json['quantity'] as int? ?? 0;
    final notes = json['notes'] as String?;
    
    print('     id: $id');
    print('     menuItemId: $menuItemId');
    print('     name: $name');
    print('     quantity: $quantity');
    
    final unitPrice = parseAmount(json['unitPrice'], 'unitPrice');
    final subtotal = parseAmount(json['subtotal'], 'subtotal');
    
    // Handle both 'tax' and 'totalTax' field names
    final taxValue = json['tax'] ?? json['totalTax'];
    final tax = parseAmount(taxValue, 'tax');
    
    // Handle both 'total' and 'totalPrice' field names
    final totalValue = json['total'] ?? json['totalPrice'];
    final total = parseAmount(totalValue, 'total');
    
    print('     ✅ OrderItem parsed successfully');
    
    return OrderItem(
      id: id,
      menuItemId: menuItemId,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      notes: notes,
      subtotal: subtotal,
      tax: tax,
      total: total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'notes': notes,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
    };
  }

  @override
  List<Object?> get props => [
    id,
    menuItemId,
    name,
    quantity,
    unitPrice,
    notes,
    subtotal,
    tax,
    total,
  ];
}

/// Order pricing
class OrderPricing extends Equatable {
  final double subtotal;
  final List<OrderDiscount> discounts;
  final double discountTotal;
  final double subtotalAfterDiscount;
  final double tax;
  final double total;
  final String currency;

  const OrderPricing({
    required this.subtotal,
    this.discounts = const [],
    this.discountTotal = 0,
    required this.subtotalAfterDiscount,
    this.tax = 0,
    required this.total,
    this.currency = 'LAK',
  });

  factory OrderPricing.fromJson(Map<String, dynamic> json) {
    print('  💰 Parsing OrderPricing:');
    print('     Keys: ${json.keys.toList()}');
    
    // Helper function to parse amount (handles both num and MoneyAmount object)
    double parseAmount(dynamic value, String fieldName) {
      print('     $fieldName type: ${value.runtimeType}');
      
      if (value == null) {
        return 0.0;
      } else if (value is num) {
        print('     → $fieldName: ${value.toDouble()}');
        return value.toDouble();
      } else if (value is Map<String, dynamic>) {
        // MoneyAmount format: { amount: 10000, currency: "LAK" }
        final amount = value['amount'];
        if (amount is num) {
          print('     → $fieldName (MoneyAmount): ${amount.toDouble()}');
          return amount.toDouble();
        }
        return 0.0;
      } else {
        print('     → ⚠️ $fieldName unexpected type: ${value.runtimeType}');
        return 0.0;
      }
    }
    
    final subtotal = parseAmount(json['subtotal'], 'subtotal');
    final discountTotal = parseAmount(json['discountTotal'], 'discountTotal');
    final subtotalAfterDiscount = parseAmount(json['subtotalAfterDiscount'], 'subtotalAfterDiscount');
    final tax = parseAmount(json['tax'], 'tax');
    final total = parseAmount(json['total'], 'total');
    final currency = json['currency'] as String? ?? 'LAK';
    
    print('     ✅ OrderPricing parsed successfully (total: $total)');
    
    return OrderPricing(
      subtotal: subtotal,
      discounts:
          (json['discounts'] as List<dynamic>?)
              ?.map((e) => OrderDiscount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      discountTotal: discountTotal,
      subtotalAfterDiscount: subtotalAfterDiscount,
      tax: tax,
      total: total,
      currency: currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'discounts': discounts.map((e) => e.toJson()).toList(),
      'discountTotal': discountTotal,
      'subtotalAfterDiscount': subtotalAfterDiscount,
      'tax': tax,
      'total': total,
      'currency': currency,
    };
  }

  @override
  List<Object?> get props => [
    subtotal,
    discounts,
    discountTotal,
    subtotalAfterDiscount,
    tax,
    total,
    currency,
  ];
}

/// Order discount
class OrderDiscount extends Equatable {
  final String type;
  final double value;
  final double amount;
  final String? reason;

  const OrderDiscount({
    required this.type,
    required this.value,
    required this.amount,
    this.reason,
  });

  factory OrderDiscount.fromJson(Map<String, dynamic> json) {
    return OrderDiscount(
      type: json['type'] as String? ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'value': value, 'amount': amount, 'reason': reason};
  }

  bool get isPercentage => type == 'percentage';
  bool get isFixed => type == 'fixed';

  @override
  List<Object?> get props => [type, value, amount, reason];
}

/// Order customer reference
class OrderCustomer extends Equatable {
  final String? customerId;
  final String? name;
  final String? phone;

  const OrderCustomer({this.customerId, this.name, this.phone});

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      customerId: json['customerId'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'customerId': customerId, 'name': name, 'phone': phone};
  }

  factory OrderCustomer.fromCustomer(Customer customer) {
    return OrderCustomer(
      customerId: customer.id,
      name: customer.name,
      phone: customer.phone,
    );
  }

  @override
  List<Object?> get props => [customerId, name, phone];
}

/// Order staff reference
class OrderStaff extends Equatable {
  final String staffId;
  final String name;

  const OrderStaff({required this.staffId, required this.name});

  factory OrderStaff.fromJson(Map<String, dynamic> json) {
    return OrderStaff(
      staffId: json['staffId'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'staffId': staffId, 'name': name};
  }

  @override
  List<Object?> get props => [staffId, name];
}
