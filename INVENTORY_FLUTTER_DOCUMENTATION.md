# 🏪 **Inventory Management System Documentation for Flutter Development**

## 📋 Table of Contents

1. [Overview & Concepts](#overview--concepts)
2. [System Architecture](#system-architecture)
3. [Core Features](#core-features)
4. [API Reference](#api-reference)
5. [Flutter Implementation Guide](#flutter-implementation-guide)
6. [Data Models](#data-models)
7. [Business Logic Flows](#business-logic-flows)
8. [Best Practices](#best-practices)
9. [Error Handling](#error-handling)
10. [Testing Guide](#testing-guide)

---

## 🎯 **Overview & Concepts**

### What is Inventory Management?

Inventory management is the systematic control and monitoring of goods, materials, and supplies in your restaurant. It helps you:

- **Track Stock**: Know exactly how much of each item you have
- **Control Costs**: Monitor spending and prevent waste
- **Prevent Shortages**: Avoid running out of essential items
- **Optimize Operations**: Make data-driven purchasing decisions
- **Ensure Quality**: Track expiry dates and storage conditions

### Key Concepts You Need to Know

#### 1. **Inventory Items**
- **Ingredients**: Raw materials used in recipes (tomatoes, flour, meat)
- **Menu Items**: Finished products sold to customers (pizza, burger)

#### 2. **Stock Levels**
- **Current Stock**: Total quantity available
- **Available Stock**: Stock minus reserved/allocated quantities
- **Reserved Stock**: Stock allocated for pending orders
- **Minimum Level**: Alert threshold for reordering

#### 3. **Stock Operations**
- **Stock In**: Adding inventory (purchases, returns)
- **Stock Out**: Removing inventory (sales, waste)
- **Adjustments**: Correcting stock levels (audits, corrections)
- **Transfers**: Moving stock between locations

#### 4. **Cost Tracking**
- **Unit Cost**: Cost per item unit
- **Total Value**: Current stock × unit cost
- **Cost Methods**: FIFO, LIFO, Weighted Average

---

## 🏗️ **System Architecture**

### Multi-Tenant Structure
```
Restaurant (Tenant)
└── Branch 1
    ├── Inventory Items (Ingredients)
    ├── Inventory Items (Menu Items)
    └── Stock Transactions
└── Branch 2
    ├── Inventory Items (Ingredients)
    ├── Inventory Items (Menu Items)
    └── Stock Transactions
```

### Data Relationships
```
MenuItem → Recipe → Ingredient → InventoryItem
Order → OrderItem → Recipe Deduction → Stock Adjustment
```

---

## ✨ **Core Features**

### 1. **Inventory Item Management**
- ✅ Create, update, delete inventory items
- ✅ SKU and barcode support
- ✅ Category organization
- ✅ Unit of measure management
- ✅ Multi-location tracking
- ✅ Cost tracking with history

### 2. **Stock Operations**
- ✅ Stock adjustments (Add/Remove/Set)
- ✅ Stock transfers between locations
- ✅ Real-time stock tracking
- ✅ Reservation management
- ✅ Automatic recipe deductions

### 3. **Advanced Features**
- ✅ Cost layer management (FIFO/LIFO)
- ✅ Batch/lot tracking
- ✅ Expiry date monitoring
- ✅ Low stock alerts
- ✅ Purchase order management
- ✅ Comprehensive reporting

### 4. **Integration Features**
- ✅ Auto-sync with menu items
- ✅ Recipe integration
- ✅ Order processing integration
- ✅ Financial reporting integration

---

## 🚀 **API Reference**

### Base URL
```
https://your-api-domain.com/api/v1/inventory
```

### Authentication
All endpoints require authentication:
```dart
final headers = {
  'Authorization': 'Bearer $authToken',
  'Content-Type': 'application/json',
  'Restaurant-ID': restaurantId,
  'Branch-ID': branchId,
};
```

### Core Endpoints

#### 🔍 **Health Check**
```http
GET /health
```

**Response:**
```json
{
  "success": true,
  "service": "Inventory Management API",
  "version": "2.0.0",
  "status": "healthy",
  "timestamp": "2026-01-05T10:30:00.000Z"
}
```

#### 📦 **Inventory Items**

##### Get All Items
```http
GET /items?page=1&limit=20&search=tomato&category=ingredient&status=active
```

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 20, max: 100)
- `search` (string): Search by name, SKU, or description
- `category` (string): Filter by category ID
- `status` (string): `active`, `inactive`, `discontinued`, `seasonal`
- `itemType` (string): `ingredient`, `menu_item`
- `lowStock` (boolean): Show only low stock items

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "item_id_123",
        "name": "Fresh Tomatoes",
        "description": "Red ripe tomatoes for cooking",
        "sku": "TOM001",
        "barcode": "1234567890",
        "itemType": "ingredient",
        "status": "active",
        "primaryUnit": {
          "name": "Kilogram",
          "abbreviation": "kg",
          "category": "weight"
        },
        "totalStock": 45.5,
        "availableStock": 40.0,
        "reservedStock": 5.5,
        "lowStockThreshold": 10,
        "standardCost": 2.50,
        "averageCost": 2.45,
        "currency": "USD",
        "totalStockValue": 111.38,
        "stockStatus": "normal",
        "lastStockUpdate": "2026-01-05T08:30:00.000Z",
        "createdAt": "2026-01-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 45,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

##### Create Item
```http
POST /items
```

**Request Body:**
```json
{
  "name": "Fresh Onions",
  "description": "White onions for cooking",
  "sku": "ONI001",
  "barcode": "1234567891",
  "itemType": "ingredient",
  "primaryUnit": {
    "name": "Kilogram",
    "abbreviation": "kg",
    "category": "weight"
  },
  "standardCost": 1.50,
  "lowStockThreshold": 15,
  "reorderPoint": 30,
  "reorderQuantity": 100,
  "currency": "USD"
}
```

##### Get Single Item
```http
GET /items/:id
```

##### Update Item
```http
PATCH /items/:id
```

##### Delete Item
```http
DELETE /items/:id
```

#### 📊 **Stock Management**

##### Adjust Stock (Bulk Operation)
```http
POST /stock/adjust
```

**Request Body (Multiple Formats - Try These):**

**Format 1 - Standard Format:**
```json
{
  "items": [
    {
      "itemId": "item_id_123",
      "operation": "ADD",
      "quantity": 25,
      "reason": "Purchase received",
      "notes": "Weekly supplier delivery - Invoice #INV-2026-001",
      "unitCost": 2.60,
      "supplierReference": "SUP-001",
      "expiryDate": "2026-02-15T00:00:00.000Z"
    }
  ]
}
```

**Format 2 - Alternative Field Names (Try if Format 1 fails):**
```json
{
  "items": [
    {
      "inventoryItemId": "item_id_123",
      "branchId": "branch_id_456", 
      "operation": "ADD",
      "quantity": 25,
      "reason": "Purchase received",
      "notes": "Weekly supplier delivery - Invoice #INV-2026-001",
      "costPrice": 2.60
    }
  ]
}
```

**Format 3 - Simplified Format (Minimal required fields):**
```json
{
  "items": [
    {
      "itemId": "item_id_123",
      "operation": "ADD", 
      "quantity": 25,
      "reason": "Purchase received"
    }
  ]
}
```

**Operation Types:**
- `ADD`: Add stock (purchases, returns)
- `REMOVE`: Remove stock (sales, waste, usage)
- `SET`: Set exact stock level (audits, corrections)

##### Transfer Stock
```http
POST /stock/transfer
```

**Request Body:**
```json
{
  "fromLocationId": "branch_1",
  "toLocationId": "branch_2",
  "items": [
    {
      "itemId": "item_id_123",
      "quantity": 10,
      "notes": "Transfer for weekend rush"
    }
  ],
  "reason": "Stock rebalancing",
  "transferDate": "2026-01-05T10:00:00.000Z"
}
```

#### 📈 **Transactions & History**

##### Get Transactions
```http
GET /transactions?page=1&limit=20&itemId=item_id_123&type=purchase&dateFrom=2026-01-01&dateTo=2026-01-31
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": "txn_id_456",
        "transactionNumber": "TXN-1735985400-abc123def",
        "type": "purchase",
        "status": "executed",
        "totalAmount": 65.00,
        "currency": "USD",
        "lines": [
          {
            "inventoryItem": "item_id_123",
            "itemName": "Fresh Tomatoes",
            "quantity": 25,
            "unitCost": 2.60,
            "totalCost": 65.00,
            "operation": "ADD"
          }
        ],
        "reason": "Weekly supplier purchase",
        "createdBy": "staff_id_789",
        "createdAt": "2026-01-05T10:30:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 87
    }
  }
}
```

#### 🔔 **Alerts & Monitoring**

##### Get Alerts
```http
GET /alerts?type=low_stock&severity=high&status=active
```

**Response:**
```json
{
  "success": true,
  "data": {
    "alerts": [
      {
        "id": "alert_id_789",
        "type": "low_stock",
        "severity": "high",
        "status": "active",
        "item": {
          "id": "item_id_456",
          "name": "Premium Beef",
          "sku": "BEEF001",
          "currentStock": 2.5,
          "lowStockThreshold": 10,
          "primaryUnit": "kg"
        },
        "message": "Premium Beef is critically low (2.5 kg remaining, threshold: 10 kg)",
        "actionRequired": "Reorder immediately",
        "estimatedStockoutDate": "2026-01-07T00:00:00.000Z",
        "suggestedOrderQuantity": 50,
        "createdAt": "2026-01-05T09:00:00.000Z"
      }
    ]
  }
}
```

#### 💰 **Valuation & Reports**

##### Get Inventory Valuation
```http
GET /valuation
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalValue": 15750.25,
    "currency": "USD",
    "lastUpdated": "2026-01-05T10:30:00.000Z",
    "breakdown": {
      "ingredients": {
        "totalValue": 12500.00,
        "itemCount": 45
      },
      "menuItems": {
        "totalValue": 3250.25,
        "itemCount": 15
      }
    },
    "topValueItems": [
      {
        "id": "item_id_999",
        "name": "Premium Wagyu Beef",
        "currentStock": 15,
        "unitCost": 85.00,
        "totalValue": 1275.00
      }
    ]
  }
}
```

---

## 📱 **Flutter Implementation Guide**

### 1. **Project Structure**

```
lib/
├── features/
│   └── inventory/
│       ├── data/
│       │   ├── models/
│       │   ├── repositories/
│       │   └── services/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── pages/
│           ├── widgets/
│           └── providers/
```

### 2. **Data Models**

#### InventoryItem Model
```dart
class InventoryItem {
  final String id;
  final String name;
  final String description;
  final String sku;
  final String? barcode;
  final String itemType;
  final String status;
  final UnitOfMeasure primaryUnit;
  final double totalStock;
  final double availableStock;
  final double reservedStock;
  final double lowStockThreshold;
  final double standardCost;
  final double averageCost;
  final String currency;
  final double totalStockValue;
  final String stockStatus;
  final DateTime lastStockUpdate;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.sku,
    this.barcode,
    required this.itemType,
    required this.status,
    required this.primaryUnit,
    required this.totalStock,
    required this.availableStock,
    required this.reservedStock,
    required this.lowStockThreshold,
    required this.standardCost,
    required this.averageCost,
    required this.currency,
    required this.totalStockValue,
    required this.stockStatus,
    required this.lastStockUpdate,
    required this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      barcode: json['barcode'],
      itemType: json['itemType'] ?? 'ingredient',
      status: json['status'] ?? 'active',
      primaryUnit: UnitOfMeasure.fromJson(json['primaryUnit'] ?? {}),
      totalStock: (json['totalStock'] ?? 0).toDouble(),
      availableStock: (json['availableStock'] ?? 0).toDouble(),
      reservedStock: (json['reservedStock'] ?? 0).toDouble(),
      lowStockThreshold: (json['lowStockThreshold'] ?? 0).toDouble(),
      standardCost: (json['standardCost'] ?? 0).toDouble(),
      averageCost: (json['averageCost'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      totalStockValue: (json['totalStockValue'] ?? 0).toDouble(),
      stockStatus: json['stockStatus'] ?? 'normal',
      lastStockUpdate: DateTime.parse(json['lastStockUpdate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'itemType': itemType,
      'status': status,
      'primaryUnit': primaryUnit.toJson(),
      'totalStock': totalStock,
      'availableStock': availableStock,
      'reservedStock': reservedStock,
      'lowStockThreshold': lowStockThreshold,
      'standardCost': standardCost,
      'averageCost': averageCost,
      'currency': currency,
      'totalStockValue': totalStockValue,
      'stockStatus': stockStatus,
      'lastStockUpdate': lastStockUpdate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isLowStock => stockStatus == 'low_stock';
  bool get isOutOfStock => stockStatus == 'out_of_stock';
  bool get isActive => status == 'active';
  
  Color get stockStatusColor {
    switch (stockStatus) {
      case 'out_of_stock':
        return Colors.red;
      case 'low_stock':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData get stockStatusIcon {
    switch (stockStatus) {
      case 'out_of_stock':
        return Icons.error;
      case 'low_stock':
        return Icons.warning;
      default:
        return Icons.check_circle;
    }
  }
}
```

#### UnitOfMeasure Model
```dart
class UnitOfMeasure {
  final String name;
  final String abbreviation;
  final String category;
  final double baseConversionFactor;
  final int precision;

  UnitOfMeasure({
    required this.name,
    required this.abbreviation,
    required this.category,
    this.baseConversionFactor = 1.0,
    this.precision = 2,
  });

  factory UnitOfMeasure.fromJson(Map<String, dynamic> json) {
    return UnitOfMeasure(
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      category: json['category'] ?? 'count',
      baseConversionFactor: (json['baseConversionFactor'] ?? 1.0).toDouble(),
      precision: json['precision'] ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'category': category,
      'baseConversionFactor': baseConversionFactor,
      'precision': precision,
    };
  }
}
```

### 3. **API Service**

```dart
class InventoryApiService {
  final Dio _dio;
  final String baseUrl;

  InventoryApiService({
    required this.baseUrl,
    required String authToken,
    required String restaurantId,
    required String branchId,
  }) : _dio = Dio() {
    _dio.options.baseUrl = '$baseUrl/api/v1/inventory';
    _dio.options.headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
      'Restaurant-ID': restaurantId,
      'Branch-ID': branchId,
    };
  }

  // Get inventory items with pagination and filtering
  Future<PaginatedResponse<InventoryItem>> getItems({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? status,
    String? itemType,
    bool? lowStock,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      if (itemType != null) queryParams['itemType'] = itemType;
      if (lowStock != null) queryParams['lowStock'] = lowStock;

      final response = await _dio.get('/items', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final items = (data['items'] as List)
            .map((json) => InventoryItem.fromJson(json))
            .toList();
        
        return PaginatedResponse<InventoryItem>(
          items: items,
          pagination: Pagination.fromJson(data['pagination']),
        );
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to fetch items');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Create new inventory item
  Future<InventoryItem> createItem(CreateInventoryItemRequest request) async {
    try {
      final response = await _dio.post('/items', data: request.toJson());
      
      if (response.data['success'] == true) {
        return InventoryItem.fromJson(response.data['data']);
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to create item');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Update inventory item
  Future<InventoryItem> updateItem(String id, UpdateInventoryItemRequest request) async {
    try {
      final response = await _dio.patch('/items/$id', data: request.toJson());
      
      if (response.data['success'] == true) {
        return InventoryItem.fromJson(response.data['data']);
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to update item');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Adjust stock (supports single or multiple items)
  Future<StockAdjustmentResult> adjustStock(List<StockAdjustmentRequest> items) async {
    try {
      final requestData = {
        'items': items.map((item) => item.toJson()).toList(),
      };
      
      final response = await _dio.post('/stock/adjust', data: requestData);
      
      if (response.data['success'] == true) {
        return StockAdjustmentResult.fromJson(response.data['data']);
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to adjust stock');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Convenience method for single item adjustment
  Future<StockAdjustmentResult> adjustSingleItem({
    required String itemId,
    required String operation,
    required double quantity,
    required String reason,
    String? notes,
    double? unitCost,
  }) async {
    final request = StockAdjustmentRequest(
      itemId: itemId,
      operation: operation,
      quantity: quantity,
      reason: reason,
      notes: notes,
      unitCost: unitCost,
    );
    
    return adjustStock([request]); // Wrap single item in array
  }

  // Get low stock alerts
  Future<List<InventoryAlert>> getAlerts({
    String? type,
    String? severity,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (severity != null) queryParams['severity'] = severity;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get('/alerts', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        final alerts = (response.data['data']['alerts'] as List)
            .map((json) => InventoryAlert.fromJson(json))
            .toList();
        return alerts;
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to fetch alerts');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get inventory valuation
  Future<InventoryValuation> getValuation() async {
    try {
      final response = await _dio.get('/valuation');
      
      if (response.data['success'] == true) {
        return InventoryValuation.fromJson(response.data['data']);
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get valuation');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException('Connection timeout');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data['message'] ?? 'Server error';
          return ApiException(message, statusCode: statusCode);
        case DioExceptionType.cancel:
          return ApiException('Request cancelled');
        case DioExceptionType.unknown:
        default:
          return NetworkException('Network error occurred');
      }
    }
    return ApiException(error.toString());
  }
}
```

### 4. **State Management (Provider)**

```dart
class InventoryProvider extends ChangeNotifier {
  final InventoryApiService _apiService;
  
  // State variables
  List<InventoryItem> _items = [];
  List<InventoryAlert> _alerts = [];
  InventoryValuation? _valuation;
  Pagination? _pagination;
  
  bool _isLoading = false;
  String? _error;
  
  // Current filters
  String _searchQuery = '';
  String? _selectedCategory;
  String _selectedStatus = 'active';
  String? _selectedItemType;
  bool _showLowStockOnly = false;

  InventoryProvider(this._apiService);

  // Getters
  List<InventoryItem> get items => _items;
  List<InventoryAlert> get alerts => _alerts;
  InventoryValuation? get valuation => _valuation;
  Pagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Filter getters
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;
  String? get selectedItemType => _selectedItemType;
  bool get showLowStockOnly => _showLowStockOnly;
  
  // Computed getters
  List<InventoryItem> get lowStockItems => 
      _items.where((item) => item.isLowStock).toList();
  
  List<InventoryItem> get outOfStockItems => 
      _items.where((item) => item.isOutOfStock).toList();
  
  double get totalInventoryValue => 
      _items.fold(0.0, (sum, item) => sum + item.totalStockValue);

  // Load inventory items
  Future<void> loadItems({
    int page = 1,
    bool refresh = false,
  }) async {
    if (refresh) {
      _items.clear();
      _pagination = null;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getItems(
        page: page,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        status: _selectedStatus,
        itemType: _selectedItemType,
        lowStock: _showLowStockOnly ? true : null,
      );

      if (page == 1 || refresh) {
        _items = response.items;
      } else {
        _items.addAll(response.items);
      }
      
      _pagination = response.pagination;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load next page
  Future<void> loadMoreItems() async {
    if (_pagination?.hasNext == true && !_isLoading) {
      await loadItems(page: (_pagination?.currentPage ?? 0) + 1);
    }
  }

  // Create item
  Future<bool> createItem(CreateInventoryItemRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final newItem = await _apiService.createItem(request);
      _items.insert(0, newItem);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update item
  Future<bool> updateItem(String id, UpdateInventoryItemRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedItem = await _apiService.updateItem(id, request);
      final index = _items.indexWhere((item) => item.id == id);
      
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Adjust stock
  Future<bool> adjustStock(StockAdjustmentRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.adjustStock(request);
      // Refresh the specific item or reload items
      await loadItems(refresh: true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load alerts
  Future<void> loadAlerts() async {
    try {
      _alerts = await _apiService.getAlerts(
        type: 'low_stock',
        status: 'active',
      );
      notifyListeners();
    } catch (e) {
      // Handle silently for alerts
      print('Failed to load alerts: $e');
    }
  }

  // Load valuation
  Future<void> loadValuation() async {
    try {
      _valuation = await _apiService.getValuation();
      notifyListeners();
    } catch (e) {
      print('Failed to load valuation: $e');
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      loadItems(refresh: true);
    });
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    loadItems(refresh: true);
    notifyListeners();
  }

  void setStatus(String status) {
    _selectedStatus = status;
    loadItems(refresh: true);
    notifyListeners();
  }

  void setItemType(String? itemType) {
    _selectedItemType = itemType;
    loadItems(refresh: true);
    notifyListeners();
  }

  void toggleLowStockFilter() {
    _showLowStockOnly = !_showLowStockOnly;
    loadItems(refresh: true);
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedStatus = 'active';
    _selectedItemType = null;
    _showLowStockOnly = false;
    loadItems(refresh: true);
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

### 5. **UI Examples**

#### Inventory List Screen
```dart
class InventoryListScreen extends StatefulWidget {
  @override
  _InventoryListScreenState createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadItems(refresh: true);
      context.read<InventoryProvider>().loadAlerts();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<InventoryProvider>().loadMoreItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Management'),
        actions: [
          Consumer<InventoryProvider>(
            builder: (context, provider, _) {
              final alertCount = provider.alerts.length;
              return Badge(
                count: alertCount,
                showBadge: alertCount > 0,
                child: IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () => _showAlertsDialog(context),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFiltersDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildQuickFilters(),
          Expanded(child: _buildInventoryList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateItemDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Add Inventory Item',
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search items, SKU, or description...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          context.read<InventoryProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(
                label: 'All Items',
                selected: !provider.showLowStockOnly,
                onTap: () => provider.toggleLowStockFilter(),
              ),
              SizedBox(width: 8),
              _buildFilterChip(
                label: 'Low Stock',
                selected: provider.showLowStockOnly,
                onTap: () => provider.toggleLowStockFilter(),
              ),
              SizedBox(width: 8),
              _buildFilterChip(
                label: 'Ingredients',
                selected: provider.selectedItemType == 'ingredient',
                onTap: () => provider.setItemType(
                  provider.selectedItemType == 'ingredient' ? null : 'ingredient'
                ),
              ),
              SizedBox(width: 8),
              _buildFilterChip(
                label: 'Menu Items',
                selected: provider.selectedItemType == 'menu_item',
                onTap: () => provider.setItemType(
                  provider.selectedItemType == 'menu_item' ? null : 'menu_item'
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildInventoryList() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.items.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.items.isEmpty) {
          return _buildErrorState(provider.error!);
        }

        if (provider.items.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadItems(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: provider.items.length + 
                       (provider.pagination?.hasNext == true ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.items.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final item = provider.items[index];
              return _buildInventoryItemCard(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildInventoryItemCard(InventoryItem item) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.stockStatusColor,
          child: Icon(
            item.stockStatusIcon,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${item.sku}'),
            Text(
              '${item.availableStock.toStringAsFixed(2)} ${item.primaryUnit.abbreviation} available',
              style: TextStyle(
                color: item.stockStatusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.currency} ${item.totalStockValue.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Unit: ${item.currency} ${item.averageCost.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => _showItemDetails(item),
        onLongPress: () => _showItemActions(item),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No inventory items found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first inventory item to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateItemDialog(context),
            icon: Icon(Icons.add),
            label: Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load inventory',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<InventoryProvider>().loadItems(refresh: true),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showAlertsDialog(BuildContext context) {
    // Implementation for showing alerts dialog
  }

  void _showFiltersDialog(BuildContext context) {
    // Implementation for showing filters dialog
  }

  void _showCreateItemDialog(BuildContext context) {
    // Implementation for creating new item
  }

  void _showItemDetails(InventoryItem item) {
    // Navigate to item details screen
  }

  void _showItemActions(InventoryItem item) {
    // Show action sheet for item operations
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

---

## 📊 **Business Logic Flows**

### 1. **Order Processing Flow**
```
Order Created → Recipe Analysis → Ingredient Deduction → Stock Update → Alert Check
```

1. **Order Received**: Customer places order
2. **Recipe Lookup**: System finds recipes for ordered items
3. **Ingredient Calculation**: Calculate required quantities
4. **Stock Deduction**: Reduce ingredient stock levels
5. **Alert Generation**: Check for low stock conditions
6. **Transaction Recording**: Log all stock movements

### 2. **Stock Adjustment Flow**
```
Adjustment Request → Validation → Cost Layer Update → Transaction Record → Alert Check
```

1. **Request Validation**: Verify user permissions and data
2. **Stock Calculation**: Apply operation (ADD/REMOVE/SET)
3. **Cost Layer Management**: Update cost layers (FIFO/LIFO)
4. **Transaction Creation**: Record stock movement
5. **Alert Processing**: Check thresholds and generate alerts

### 3. **Purchase Order Flow**
```
Low Stock Alert → Purchase Order → Goods Receipt → Stock Adjustment → Cost Update
```

1. **Alert Trigger**: System detects low stock
2. **PO Creation**: Generate purchase order
3. **Supplier Communication**: Send PO to supplier
4. **Goods Receipt**: Receive and verify goods
5. **Stock Update**: Add received inventory
6. **Cost Calculation**: Update average costs

---

## ✅ **Best Practices**

### 1. **Data Management**
- Always validate stock operations before execution
- Implement optimistic locking for concurrent updates
- Use transactions for multi-step operations
- Cache frequently accessed data locally
- Implement proper error handling and retry logic

### 2. **UI/UX Guidelines**
- Show real-time stock status with color coding
- Implement pull-to-refresh for data updates
- Use infinite scrolling for large item lists
- Provide clear visual feedback for operations
- Include confirmation dialogs for critical actions

### 3. **Performance Optimization**
- Implement pagination for large datasets
- Use debouncing for search inputs
- Cache API responses appropriately
- Optimize list rendering with proper keys
- Lazy load non-critical data

### 4. **Security Considerations**
- Validate all inputs on both client and server
- Implement proper authentication and authorization
- Use HTTPS for all API communications
- Sanitize data before display
- Log all critical operations for audit

---

## 🚨 **Error Handling**

### Common Error Scenarios

#### 1. **Network Errors**
```dart
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

// Handle in UI
try {
  await inventoryProvider.loadItems();
} catch (e) {
  if (e is NetworkException) {
    _showSnackBar('Network error: Check your connection');
  }
}
```

#### 2. **Validation Errors**
```dart
class ValidationException implements Exception {
  final Map<String, String> errors;
  ValidationException(this.errors);
}

// Handle form validation
if (e is ValidationException) {
  e.errors.forEach((field, message) {
    _showFieldError(field, message);
  });
}
```

#### 3. **Business Logic Errors**
```dart
// Insufficient stock
if (e is ApiException && e.statusCode == 409) {
  _showDialog(
    title: 'Insufficient Stock',
    content: 'Not enough stock available for this operation',
  );
}
```

---

## 🧪 **Testing Guide**

### Unit Tests Example
```dart
void main() {
  group('InventoryProvider Tests', () {
    late InventoryProvider provider;
    late MockInventoryApiService mockApiService;

    setUp(() {
      mockApiService = MockInventoryApiService();
      provider = InventoryProvider(mockApiService);
    });

    test('should load items successfully', () async {
      // Arrange
      final mockResponse = PaginatedResponse<InventoryItem>(
        items: [InventoryItem(id: '1', name: 'Test Item', ...)],
        pagination: Pagination(...),
      );
      when(mockApiService.getItems()).thenAnswer((_) async => mockResponse);

      // Act
      await provider.loadItems();

      // Assert
      expect(provider.items.length, 1);
      expect(provider.isLoading, false);
      expect(provider.error, null);
      verify(mockApiService.getItems()).called(1);
    });

    test('should handle API errors gracefully', () async {
      // Arrange
      when(mockApiService.getItems())
          .thenThrow(ApiException('Network error'));

      // Act
      await provider.loadItems();

      // Assert
      expect(provider.items.length, 0);
      expect(provider.isLoading, false);
      expect(provider.error, 'Network error');
    });
  });
}
```

### Integration Tests Example
```dart
void main() {
  group('Inventory Integration Tests', () {
    testWidgets('should display inventory items', (tester) async {
      // Arrange
      final mockProvider = MockInventoryProvider();
      when(mockProvider.items).thenReturn([
        InventoryItem(id: '1', name: 'Test Item', ...),
      ]);

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<InventoryProvider>.value(
          value: mockProvider,
          child: MaterialApp(home: InventoryListScreen()),
        ),
      );

      // Assert
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });
  });
}
```

---

## 📈 **Advanced Features Integration**

### Real-time Updates with WebSocket
```dart
class InventoryWebSocketService {
  late WebSocketChannel _channel;

  void connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://your-api-domain/inventory-updates'),
    );

    _channel.stream.listen((data) {
      final update = jsonDecode(data);
      _handleInventoryUpdate(update);
    });
  }

  void _handleInventoryUpdate(Map<String, dynamic> update) {
    switch (update['type']) {
      case 'stock_changed':
        _updateItemStock(update['itemId'], update['newStock']);
        break;
      case 'low_stock_alert':
        _showLowStockAlert(update['item']);
        break;
      case 'item_created':
        _addNewItem(update['item']);
        break;
    }
  }
}
```

### Offline Support
```dart
class OfflineInventoryService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> syncOfflineData() async {
    final pendingOperations = await _db.getPendingOperations();
    
    for (final operation in pendingOperations) {
      try {
        await _syncOperation(operation);
        await _db.markOperationSynced(operation.id);
      } catch (e) {
        print('Failed to sync operation ${operation.id}: $e');
      }
    }
  }
}
```

---

This comprehensive documentation provides everything you need to understand and implement inventory management in your Flutter application. The system is designed to be robust, scalable, and user-friendly, with advanced features for professional restaurant operations.