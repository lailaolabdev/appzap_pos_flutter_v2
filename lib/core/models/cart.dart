import 'package:equatable/equatable.dart';

import 'product.dart';
import 'customer.dart';

/// A single selected modifier option within a cart item
class SelectedModifier extends Equatable {
  final String customizationId;
  final String customizationName;
  final String optionId;
  final String optionName;
  final double price;

  const SelectedModifier({
    required this.customizationId,
    required this.customizationName,
    required this.optionId,
    required this.optionName,
    this.price = 0,
  });

  Map<String, dynamic> toJson() => {
    'customizationId': customizationId,
    'optionId': optionId,
    'price': price,
  };

  @override
  List<Object?> get props => [customizationId, optionId, price];
}

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
  final List<SelectedModifier> selectedModifiers;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1,
    this.notes,
    this.taxRate = 0,
    this.taxIncluded = false,
    this.imageUrl,
    this.selectedModifiers = const [],
  });

  /// Create from Product with optional modifier selections
  factory CartItem.fromProduct(
    Product product, {
    int quantity = 1,
    List<SelectedModifier> selectedModifiers = const [],
  }) {
    return CartItem(
      productId: product.id,
      productName: product.name,
      unitPrice: product.pricing.basePrice,
      quantity: quantity,
      taxRate: product.pricing.taxRate,
      taxIncluded: product.pricing.taxIncluded,
      imageUrl: product.primaryImageUrl,
      selectedModifiers: selectedModifiers,
    );
  }

  /// Total price of selected modifiers
  double get modifiersTotal =>
      selectedModifiers.fold(0, (sum, m) => sum + m.price);

  /// Unit price including modifier extras
  double get effectiveUnitPrice => unitPrice + modifiersTotal;

  /// Calculate subtotal (effective price * quantity)
  double get subtotal => effectiveUnitPrice * quantity;

  /// Calculate tax amount
  double get taxAmount {
    if (taxIncluded) return 0;
    return subtotal * (taxRate / 100);
  }

  /// Calculate total (subtotal + tax)
  double get total => subtotal + taxAmount;

  /// Summary text of selected modifiers for display
  String get modifiersSummary {
    if (selectedModifiers.isEmpty) return '';
    return selectedModifiers.map((m) => m.optionName).join(', ');
  }

  /// Unique key combining productId + modifier selections for cart dedup
  String get cartKey {
    if (selectedModifiers.isEmpty) return productId;
    final modKey = selectedModifiers.map((m) => m.optionId).toList()..sort();
    return '$productId|${modKey.join(",")}';
  }

  CartItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    String? notes,
    double? taxRate,
    bool? taxIncluded,
    String? imageUrl,
    List<SelectedModifier>? selectedModifiers,
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
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
    );
  }

  Map<String, dynamic> toOrderItemJson() {
    return {
      'menuItemId': productId,
      'quantity': quantity,
      'unitPrice': effectiveUnitPrice,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (selectedModifiers.isNotEmpty)
        'customizations': selectedModifiers.map((m) => m.toJson()).toList(),
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
    selectedModifiers,
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

  /// Add item to cart (merges if same product + same modifiers)
  Cart addItem(CartItem item) {
    final existingIndex = items.indexWhere(
      (i) => i.cartKey == item.cartKey && i.notes == item.notes,
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

  /// Add product to cart with optional modifier selections
  Cart addProduct(
    Product product, {
    int quantity = 1,
    List<SelectedModifier> selectedModifiers = const [],
  }) {
    return addItem(CartItem.fromProduct(
      product,
      quantity: quantity,
      selectedModifiers: selectedModifiers,
    ));
  }

  /// Remove item from cart by cartKey or productId
  Cart removeItem(String id) {
    return copyWith(
      items: items.where((item) => item.cartKey != id && item.productId != id).toList(),
    );
  }

  /// Update item quantity by cartKey or productId
  Cart updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      return removeItem(id);
    }

    final updatedItems =
        items.map((item) {
          if (item.cartKey == id || item.productId == id) {
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
