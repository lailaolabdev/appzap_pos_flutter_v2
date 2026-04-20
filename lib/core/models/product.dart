import 'package:equatable/equatable.dart';

import 'modifier.dart';

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
  final List<Modifier> customizations;
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
    this.customizations = const [],
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle populated categoryId (can be String or Object with _id and name)
    String? categoryId;
    String? categoryName;

    final categoryData = json['categoryId'];
    if (categoryData is Map<String, dynamic>) {
      // Populated object: { _id: "...", name: "..." }
      categoryId = categoryData['_id'] as String?;
      categoryName = categoryData['name'] as String?;
    } else if (categoryData is String) {
      // Direct string ID
      categoryId = categoryData;
      categoryName = json['categoryName'] as String?;
    } else {
      // Fallback
      categoryName = json['categoryName'] as String?;
    }

    return Product(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      itemCode: json['itemCode'] as String?,
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      categoryId: categoryId,
      categoryName: categoryName,
      pricing: ProductPricing.fromJson(
        json['pricing'] as Map<String, dynamic>? ?? {},
      ),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inventory: _parseInventoryData(json),
      customizations: _parseCustomizations(json['customizations']),
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  /// Parse customizations array — each entry can be a populated Modifier object or just an ID string
  static List<Modifier> _parseCustomizations(dynamic raw) {
    if (raw == null || raw is! List) return [];
    final results = <Modifier>[];
    for (final entry in raw) {
      if (entry is Map<String, dynamic>) {
        results.add(Modifier.fromJson(entry));
      }
      // Skip string-only IDs — we need populated data
    }
    return results;
  }

  /// Parse inventory data from backend format to ProductInventory
  static ProductInventory? _parseInventoryData(Map<String, dynamic> json) {
    // Check for direct inventory fields first (from inventory API format)
    final hasDirectFields =
        json.containsKey('availableStock') ||
        json.containsKey('totalStock') ||
        json.containsKey('currentStock');

    if (hasDirectFields) {
      final currentStock =
          (json['availableStock'] as num?)?.toInt() ??
          (json['totalStock'] as num?)?.toInt() ??
          (json['currentStock'] as num?)?.toInt();
      final lowStockThreshold =
          (json['lowStockThreshold'] as num?)?.toInt() ??
          (json['minStockLevel'] as num?)?.toInt() ??
          0;
      final unit =
          json['primaryUnit'] is Map<String, dynamic>
              ? (json['primaryUnit'] as Map<String, dynamic>)['name']
                    as String? ??
                  'unit'
              : json['unit'] as String? ?? 'unit';

      if (currentStock == null) {
        return null;
      }

      return ProductInventory(
        trackStock: true,
        currentStock: currentStock,
        lowStockThreshold: lowStockThreshold,
        isLowStock: currentStock <= lowStockThreshold,
        unit: unit,
      );
    }

    // Fallback: nested inventory structure (menu item API format)
    final inventoryData = json['inventory'] as Map<String, dynamic>?;
    if (inventoryData == null) return null;

    final trackInventory =
        inventoryData['trackInventory'] as bool? ??
        inventoryData['trackStock'] as bool? ??
        false;
    if (!trackInventory) return null;

    // Parse current stock
    final currentStockData = json['currentStock'];
    int? currentStock;
    bool isLowStock = false;

    if (currentStockData is Map<String, dynamic>) {
      currentStock =
          (currentStockData['available'] as num?)?.toInt() ??
          (currentStockData['total'] as num?)?.toInt();
      isLowStock = currentStockData['isOutOfStock'] as bool? ?? false;
    } else if (currentStockData is num) {
      currentStock = currentStockData.toInt();
    } else {
      currentStock =
          (inventoryData['availableStock'] as num?)?.toInt() ??
          (inventoryData['totalStock'] as num?)?.toInt() ??
          (inventoryData['currentStock'] as num?)?.toInt();
    }
    if (currentStock == null) return null;

    // Parse threshold — default to 0 if not set
    final lowStockThreshold =
        (inventoryData['lowStockThreshold'] as num?)?.toInt() ??
        (inventoryData['minStockLevel'] as num?)?.toInt() ??
        (json['lowStockThreshold'] as num?)?.toInt() ??
        (json['minStockLevel'] as num?)?.toInt() ??
        0;

    final unit =
        inventoryData['unit'] as String? ??
        inventoryData['unitOfMeasure'] as String? ??
        'unit';

    if (!isLowStock) isLowStock = currentStock <= lowStockThreshold;

    return ProductInventory(
      trackStock: true,
      currentStock: currentStock,
      lowStockThreshold: lowStockThreshold,
      isLowStock: isLowStock,
      unit: unit,
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
      if (customizations.isNotEmpty)
        'customizations': customizations.map((c) => c.id).toList(),
      'isActive': isActive,
      'displayOrder': displayOrder,
    };
  }

  /// Get the primary image URL
  String? get primaryImageUrl => images.isNotEmpty ? images.first.url : null;

  /// Check if product is in stock
  bool get isInStock {
    if (inventory == null) {
      return true;
    }
    if (!inventory!.trackStock) {
      return true;
    }

    final inStock = inventory!.currentStock > 0;
    return inStock;
  }

  /// Check if product is low stock
  bool get isLowStock => inventory?.isLowStock ?? false;

  /// Get price with tax
  double get priceWithTax {
    if (pricing.taxIncluded) return pricing.basePrice;
    return pricing.basePrice * (1 + pricing.taxRate / 100);
  }

  /// Whether this product has any modifier groups assigned
  bool get hasCustomizations => customizations.isNotEmpty;

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
    List<Modifier>? customizations,
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
      customizations: customizations ?? this.customizations,
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
    customizations,
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
  final String? smallUrl;
  final String? mediumUrl;

  const ProductImage({required this.url, this.smallUrl, this.mediumUrl});

  static const _s3Base =
      'https://appzap-v2-restaurant-menu-images.s3.ap-southeast-1.amazonaws.com';

  /// Build full S3 URL from key or nested image data
  static String? _buildUrl(dynamic imageData) {
    if (imageData == null) return null;
    if (imageData is String && imageData.isNotEmpty) return imageData;
    if (imageData is Map<String, dynamic>) {
      final key = imageData['key'] as String?;
      if (key != null && key.isNotEmpty) return '$_s3Base/$key';
      final filename = imageData['filename'] as String?;
      if (filename != null && filename.isNotEmpty) return '$_s3Base/original/$filename';
    }
    return null;
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    // Try pre-built URL first (from endpoints that call getImageUrls)
    final directUrl = json['url'] as String?;
    final directSmall = json['smallUrl'] as String?;
    final directMedium = json['mediumUrl'] as String?;

    // Fallback: build from raw S3 data (from getMenuItems with .lean())
    final originalUrl = directUrl ?? _buildUrl(json['original']);
    final smallUrl = directSmall ?? _buildUrl(json['small']);
    final mediumUrl = directMedium ?? _buildUrl(json['medium']);

    return ProductImage(
      url: originalUrl ?? '',
      smallUrl: smallUrl,
      mediumUrl: mediumUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      if (smallUrl != null) 'smallUrl': smallUrl,
      if (mediumUrl != null) 'mediumUrl': mediumUrl,
    };
  }

  @override
  List<Object?> get props => [url, smallUrl, mediumUrl];
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
    this.lowStockThreshold = 0,
    this.isLowStock = false,
    this.unit = 'unit',
  });

  factory ProductInventory.fromJson(Map<String, dynamic> json) {
    return ProductInventory(
      trackStock: json['trackStock'] as bool? ?? true,
      currentStock: json['currentStock'] as int? ?? 0,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 0,
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

  ProductInventory copyWith({
    bool? trackStock,
    int? currentStock,
    int? lowStockThreshold,
    bool? isLowStock,
    String? unit,
  }) {
    return ProductInventory(
      trackStock: trackStock ?? this.trackStock,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isLowStock: isLowStock ?? this.isLowStock,
      unit: unit ?? this.unit,
    );
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
  final String? color;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
    this.itemCount,
    this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      itemCount: json['itemCount'] as int?,
      color: json['color'] as String?,
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
      if (color != null) 'color': color,
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
    color,
  ];
}
