import 'package:equatable/equatable.dart';

import 'product.dart';
import 'customer.dart';

/// Cart item model
class CartItem extends Equatable {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? notes;
  final double taxRate;
  final bool taxIncluded;
  final String? imageUrl;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1,
    this.notes,
    this.taxRate = 0,
    this.taxIncluded = false,
    this.imageUrl,
  });

  /// Create from Product
  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      productId: product.id,
      productName: product.name,
      unitPrice: product.pricing.basePrice,
      quantity: quantity,
      taxRate: product.pricing.taxRate,
      taxIncluded: product.pricing.taxIncluded,
      imageUrl: product.primaryImageUrl,
    );
  }

  /// Calculate subtotal (price * quantity)
  double get subtotal => unitPrice * quantity;

  /// Calculate tax amount
  double get taxAmount {
    if (taxIncluded) return 0;
    return subtotal * (taxRate / 100);
  }

  /// Calculate total (subtotal + tax)
  double get total => subtotal + taxAmount;

  CartItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    String? notes,
    double? taxRate,
    bool? taxIncluded,
    String? imageUrl,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      taxRate: taxRate ?? this.taxRate,
      taxIncluded: taxIncluded ?? this.taxIncluded,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toOrderItemJson() {
    return {
      'menuItemId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    unitPrice,
    quantity,
    notes,
    taxRate,
    taxIncluded,
    imageUrl,
  ];
}

/// Cart discount model
class CartDiscount extends Equatable {
  final DiscountType type;
  final double value;
  final String? reason;

  const CartDiscount({required this.type, required this.value, this.reason});

  bool get isPercentage => type == DiscountType.percentage;
  bool get isFixed => type == DiscountType.fixed;

  /// Calculate discount amount based on subtotal
  double calculateAmount(double subtotal) {
    if (type == DiscountType.percentage) {
      return subtotal * (value / 100);
    }
    return value;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'value': value,
      if (reason != null) 'reason': reason,
    };
  }

  @override
  List<Object?> get props => [type, value, reason];
}

enum DiscountType { percentage, fixed }

/// Shopping Cart model
class Cart extends Equatable {
  final List<CartItem> items;
  final List<CartDiscount> discounts;
  final Customer? customer;
  final String? notes;

  const Cart({
    this.items = const [],
    this.discounts = const [],
    this.customer,
    this.notes,
  });

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get total items count (sum of all quantities)
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Get unique items count
  int get uniqueItemsCount => items.length;

  /// Calculate subtotal (before discounts and taxes)
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Calculate total tax
  double get totalTax => items.fold(0, (sum, item) => sum + item.taxAmount);

  /// Calculate total discount amount
  double get discountAmount {
    return discounts.fold(0, (sum, discount) {
      return sum + discount.calculateAmount(subtotal);
    });
  }

  /// Calculate subtotal after discount
  double get subtotalAfterDiscount => subtotal - discountAmount;

  /// Calculate final total
  double get total => subtotalAfterDiscount + totalTax;

  /// Get customer ID if available
  String? get customerId => customer?.id;

  /// Get customer name if available
  String? get customerName => customer?.name;

  /// Get customer phone if available
  String? get customerPhone => customer?.phone;

  /// Add item to cart
  Cart addItem(CartItem item) {
    final existingIndex = items.indexWhere(
      (i) => i.productId == item.productId && i.notes == item.notes,
    );

    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
      return copyWith(items: updatedItems);
    }

    return copyWith(items: [...items, item]);
  }

  /// Add product to cart
  Cart addProduct(Product product, {int quantity = 1}) {
    return addItem(CartItem.fromProduct(product, quantity: quantity));
  }

  /// Remove item from cart
  Cart removeItem(String productId) {
    return copyWith(
      items: items.where((item) => item.productId != productId).toList(),
    );
  }

  /// Update item quantity
  Cart updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final updatedItems =
        items.map((item) {
          if (item.productId == productId) {
            return item.copyWith(quantity: quantity);
          }
          return item;
        }).toList();

    return copyWith(items: updatedItems);
  }

  /// Increment item quantity
  Cart incrementQuantity(String productId) {
    final item = items.firstWhere(
      (i) => i.productId == productId,
      orElse: () => throw Exception('Item not found'),
    );
    return updateQuantity(productId, item.quantity + 1);
  }

  /// Decrement item quantity
  Cart decrementQuantity(String productId) {
    final item = items.firstWhere(
      (i) => i.productId == productId,
      orElse: () => throw Exception('Item not found'),
    );
    return updateQuantity(productId, item.quantity - 1);
  }

  /// Update item notes
  Cart updateItemNotes(String productId, String? notes) {
    final updatedItems =
        items.map((item) {
          if (item.productId == productId) {
            return item.copyWith(notes: notes);
          }
          return item;
        }).toList();

    return copyWith(items: updatedItems);
  }

  /// Add discount
  Cart addDiscount(CartDiscount discount) {
    return copyWith(discounts: [...discounts, discount]);
  }

  /// Remove discount
  Cart removeDiscount(int index) {
    final updatedDiscounts = List<CartDiscount>.from(discounts);
    updatedDiscounts.removeAt(index);
    return copyWith(discounts: updatedDiscounts);
  }

  /// Clear all discounts
  Cart clearDiscounts() {
    return copyWith(discounts: []);
  }

  /// Set customer
  Cart setCustomer(Customer? customer) {
    return copyWith(customer: customer);
  }

  /// Set notes
  Cart setNotes(String? notes) {
    return copyWith(notes: notes);
  }

  /// Clear cart
  Cart clear() {
    return const Cart();
  }

  /// Get item by product ID
  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if product is in cart
  bool containsProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  /// Get quantity for product
  int getQuantityForProduct(String productId) {
    final item = getItem(productId);
    return item?.quantity ?? 0;
  }

  Cart copyWith({
    List<CartItem>? items,
    List<CartDiscount>? discounts,
    Customer? customer,
    String? notes,
  }) {
    return Cart(
      items: items ?? this.items,
      discounts: discounts ?? this.discounts,
      customer: customer ?? this.customer,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to order create request
  Map<String, dynamic> toOrderRequest(String branchId) {
    return {
      'branchId': branchId,
      'orderType': 'takeaway',
      if (customer != null)
        'customer': {
          'customerId': customer!.id,
          'name': customer!.name,
          'phone': customer!.phone,
        },
      'items': items.map((item) => item.toOrderItemJson()).toList(),
      if (discounts.isNotEmpty)
        'discounts': discounts.map((d) => d.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [items, discounts, customer, notes];
}
