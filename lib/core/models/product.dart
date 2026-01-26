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
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  /// Parse inventory data from backend format to ProductInventory
  static ProductInventory? _parseInventoryData(Map<String, dynamic> json) {
    print('🔍 Parsing inventory data for ${json['name']}:');
    print('   Available fields: ${json.keys.toList()}');

    // Check all possible locations for lowStockThreshold value
    print('🔍 Searching for lowStockThreshold in all locations:');
    print('   - json[lowStockThreshold]: ${json['lowStockThreshold']}');
    print('   - json[minStockLevel]: ${json['minStockLevel']}');
    print('   - json[inventory]: ${json['inventory']}');
    if (json['inventory'] is Map) {
      final inventoryMap = json['inventory'] as Map<String, dynamic>;
      print(
        '   - inventory[lowStockThreshold]: ${inventoryMap['lowStockThreshold']}',
      );
      print('   - inventory[minStockLevel]: ${inventoryMap['minStockLevel']}');
    }

    // ✅ NEW: Check for direct inventory fields first (from inventory API format)
    final hasDirectInventoryFields =
        json.containsKey('availableStock') ||
        json.containsKey('totalStock') ||
        json.containsKey('currentStock');

    if (hasDirectInventoryFields) {
      print('   📦 Found direct inventory fields in root level');

      // Parse stock from root level (inventory API format) - NO DEFAULTS
      final currentStock =
          (json['availableStock'] as num?)?.toInt() ??
          (json['totalStock'] as num?)?.toInt() ??
          (json['currentStock'] as num?)?.toInt();

      if (currentStock == null) {
        print('   ❌ No valid currentStock found in direct fields');
        return null;
      }

      final lowStockThreshold =
          (json['lowStockThreshold'] as num?)?.toInt() ??
          (json['minStockLevel'] as num?)?.toInt();

      if (lowStockThreshold == null) {
        print('   ❌ No valid lowStockThreshold found in direct fields');
        return null;
      }

      final isLowStock = currentStock <= lowStockThreshold;

      final unit =
          json['primaryUnit'] is Map<String, dynamic>
              ? (json['primaryUnit'] as Map<String, dynamic>)['name'] as String?
              : json['unit'] as String?;

      if (unit == null) {
        print('   ❌ No valid unit found in direct fields');
        return null;
      }

      print('   ✅ Parsed from root level:');
      print('      - currentStock: $currentStock');
      print('      - lowStockThreshold: $lowStockThreshold');
      print('      - isLowStock: $isLowStock');
      print('      - unit: $unit');

      return ProductInventory(
        trackStock: true,
        currentStock: currentStock,
        lowStockThreshold: lowStockThreshold,
        isLowStock: isLowStock,
        unit: unit,
      );
    }

    // ✅ FALLBACK: Check nested inventory structure (menu item API format)
    final inventoryData = json['inventory'] as Map<String, dynamic>?;
    final currentStockData = json['currentStock'];

    print('   Raw inventory: $inventoryData');
    print('   Raw currentStock: $currentStockData');

    // If no inventory tracking configuration, return null
    if (inventoryData == null) {
      print('   ❌ No inventory configuration found');
      return null;
    }

    // Check if inventory tracking is enabled
    final trackInventory =
        inventoryData['trackInventory'] as bool? ??
        inventoryData['trackStock'] as bool? ??
        false;

    if (!trackInventory) {
      print('   ❌ Inventory tracking disabled');
      return null;
    }

    // Parse current stock levels
    int? currentStock;
    bool isLowStock = false;

    // Parse stock data from nested structure
    if (currentStockData is Map<String, dynamic>) {
      // Backend format: currentStock: { total: 100, available: 95, ... }
      currentStock =
          (currentStockData['available'] as num?)?.toInt() ??
          (currentStockData['total'] as num?)?.toInt();

      if (currentStock == null) {
        print('   ❌ No valid stock data in currentStock object');
        return null;
      }

      isLowStock = currentStockData['isOutOfStock'] as bool? ?? false;
      print('   📦 Parsed from currentStock object: $currentStock (available)');
    } else if (currentStockData is num) {
      // Direct number format: currentStock: 95
      currentStock = currentStockData.toInt();
      print('   📦 Parsed from currentStock number: $currentStock');
    } else {
      // Try nested inventory fields
      currentStock =
          (inventoryData['availableStock'] as num?)?.toInt() ??
          (inventoryData['totalStock'] as num?)?.toInt() ??
          (inventoryData['currentStock'] as num?)?.toInt();

      if (currentStock == null) {
        print('   ❌ No current stock data found in inventory object');
        return null; // Return null if no real stock data found
      }

      print('   📦 Parsed from nested inventory fields: $currentStock');
    }

    // Try to read lowStockThreshold from various field names and locations - NO DEFAULTS
    final lowStockThreshold =
        // 1. Check nested inventory object
        (inventoryData['lowStockThreshold'] as num?)?.toInt() ??
        (inventoryData['minStockLevel'] as num?)?.toInt() ??
        // 2. Check parent item data (menu item level)
        (json['lowStockThreshold'] as num?)?.toInt() ??
        (json['minStockLevel'] as num?)?.toInt() ??
        // 3. Check if inventory field has lowStockThreshold directly
        (json['inventory']?['lowStockThreshold'] as num?)?.toInt() ??
        (json['inventory']?['minStockLevel'] as num?)?.toInt();

    if (lowStockThreshold == null) {
      print('   ❌ No lowStockThreshold data found in any location');
      return null; // Return null if no real threshold data found
    }

    print('   ✅ Found lowStockThreshold: $lowStockThreshold');

    final unit =
        inventoryData['unit'] as String? ??
        inventoryData['unitOfMeasure'] as String?;

    if (unit == null) {
      print('   ❌ No unit data found');
      return null; // Return null if no real unit data found
    }

    print('   ✅ Found unit: $unit');

    // Determine if low stock (now that we have confirmed non-null values)
    if (!isLowStock) {
      isLowStock = currentStock! <= lowStockThreshold!;
    }

    final result = ProductInventory(
      trackStock: true,
      currentStock: currentStock!,
      lowStockThreshold: lowStockThreshold!,
      isLowStock: isLowStock,
      unit: unit!,
    );

    print('   ✅ Final ProductInventory:');
    print('      - trackStock: ${result.trackStock}');
    print('      - currentStock: ${result.currentStock}');
    print('      - lowStockThreshold: ${result.lowStockThreshold}');
    print('      - isLowStock: ${result.isLowStock}');
    print('      - unit: ${result.unit}');

    return result;
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
    if (inventory == null) {
      print('🟢 ${name}: No inventory tracking - treating as IN STOCK');
      return true;
    }
    if (!inventory!.trackStock) {
      print('🟢 ${name}: Stock tracking disabled - treating as IN STOCK');
      return true;
    }

    final inStock = inventory!.currentStock > 0;
    print(
      '📦 ${name}: Stock check - currentStock: ${inventory!.currentStock}, isInStock: $inStock',
    );
    return inStock;
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
