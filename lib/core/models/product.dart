import 'package:equatable/equatable.dart';

/// Product/Menu Item model
class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? itemCode;
  final String? barcode;
  final String? sku;
  final String? categoryId;
  final String? categoryName;
  final ProductPricing pricing;
  final List<ProductImage> images;
  final ProductInventory? inventory;
  final bool isActive;
  final int displayOrder;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.itemCode,
    this.barcode,
    this.sku,
    this.categoryId,
    this.categoryName,
    required this.pricing,
    this.images = const [],
    this.inventory,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      itemCode: json['itemCode'] as String?,
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      pricing: ProductPricing.fromJson(
        json['pricing'] as Map<String, dynamic>? ?? {},
      ),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inventory:
          json['inventory'] != null
              ? ProductInventory.fromJson(
                json['inventory'] as Map<String, dynamic>,
              )
              : null,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'itemCode': itemCode,
      'barcode': barcode,
      'sku': sku,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'pricing': pricing.toJson(),
      'images': images.map((e) => e.toJson()).toList(),
      'inventory': inventory?.toJson(),
      'isActive': isActive,
      'displayOrder': displayOrder,
    };
  }

  /// Get the primary image URL
  String? get primaryImageUrl => images.isNotEmpty ? images.first.url : null;

  /// Check if product is in stock
  bool get isInStock {
    if (inventory == null) return true;
    if (!inventory!.trackStock) return true;
    return inventory!.currentStock > 0;
  }

  /// Check if product is low stock
  bool get isLowStock => inventory?.isLowStock ?? false;

  /// Get price with tax
  double get priceWithTax {
    if (pricing.taxIncluded) return pricing.basePrice;
    return pricing.basePrice * (1 + pricing.taxRate / 100);
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? itemCode,
    String? barcode,
    String? sku,
    String? categoryId,
    String? categoryName,
    ProductPricing? pricing,
    List<ProductImage>? images,
    ProductInventory? inventory,
    bool? isActive,
    int? displayOrder,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      itemCode: itemCode ?? this.itemCode,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      pricing: pricing ?? this.pricing,
      images: images ?? this.images,
      inventory: inventory ?? this.inventory,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    itemCode,
    barcode,
    sku,
    categoryId,
    categoryName,
    pricing,
    images,
    inventory,
    isActive,
    displayOrder,
  ];
}

/// Product pricing information
class ProductPricing extends Equatable {
  final double basePrice;
  final double? costPrice;
  final double taxRate;
  final bool taxIncluded;
  final String currency;

  const ProductPricing({
    required this.basePrice,
    this.costPrice,
    this.taxRate = 0,
    this.taxIncluded = false,
    this.currency = 'LAK',
  });

  factory ProductPricing.fromJson(Map<String, dynamic> json) {
    return ProductPricing(
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      taxIncluded: json['taxIncluded'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'LAK',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basePrice': basePrice,
      'costPrice': costPrice,
      'taxRate': taxRate,
      'taxIncluded': taxIncluded,
      'currency': currency,
    };
  }

  @override
  List<Object?> get props => [
    basePrice,
    costPrice,
    taxRate,
    taxIncluded,
    currency,
  ];
}

/// Product image
class ProductImage extends Equatable {
  final String url;
  final String? size;

  const ProductImage({required this.url, this.size});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] as String? ?? '',
      size: json['size'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'size': size};
  }

  @override
  List<Object?> get props => [url, size];
}

/// Product inventory information
class ProductInventory extends Equatable {
  final bool trackStock;
  final int currentStock;
  final int lowStockThreshold;
  final bool isLowStock;
  final String unit;

  const ProductInventory({
    this.trackStock = true,
    required this.currentStock,
    this.lowStockThreshold = 10,
    this.isLowStock = false,
    this.unit = 'unit',
  });

  factory ProductInventory.fromJson(Map<String, dynamic> json) {
    return ProductInventory(
      trackStock: json['trackStock'] as bool? ?? true,
      currentStock: json['currentStock'] as int? ?? 0,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 10,
      isLowStock: json['isLowStock'] as bool? ?? false,
      unit: json['unit'] as String? ?? 'unit',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackStock': trackStock,
      'currentStock': currentStock,
      'lowStockThreshold': lowStockThreshold,
      'isLowStock': isLowStock,
      'unit': unit,
    };
  }

  @override
  List<Object?> get props => [
    trackStock,
    currentStock,
    lowStockThreshold,
    isLowStock,
    unit,
  ];
}

/// Product Category model
class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final int? itemCount;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
    this.itemCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      itemCount: json['itemCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'itemCount': itemCount,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    displayOrder,
    isActive,
    itemCount,
  ];
}
