# Reports API Documentation for Flutter Frontend

## Overview

This document provides comprehensive API documentation for all reporting endpoints available for your Flutter frontend. The system offers both unified (v2) and legacy (v1) APIs, with v2 being the recommended approach for new implementations.

## Base URL
```
http://your-server.com/api/v1/reports
```

## Authentication
All report endpoints require:
```http
Authorization: Bearer <your_jwt_token>
```

## Table of Contents

1. [Daily Sales Reports](#daily-sales-reports)
2. [Product Performance Reports](#product-performance-reports)
3. [Staff Performance Reports](#staff-performance-reports)
4. [End of Day Reports](#end-of-day-reports)
5. [Sales Trends Reports](#sales-trends-reports)
6. [Category Reports](#category-reports)
7. [Payment Method Reports](#payment-method-reports)
8. [Hourly Sales Reports](#hourly-sales-reports)
9. [Analytics APIs](#analytics-apis)
10. [Export Options](#export-options)
11. [Flutter Integration Examples](#flutter-integration-examples)

---

## Daily Sales Reports

### 1. Get Daily Sales Summary (Unified v2)
```http
GET /v2/sales?dimension=day&dateFrom={start}&dateTo={end}
```

**Query Parameters:**
- `dimension`: `"day"` (required)
- `dateFrom`: Start date (ISO 8601) - `2024-01-01`
- `dateTo`: End date (ISO 8601) - `2024-01-31`
- `branchId`: Filter by branch (optional)
- `timezone`: Timezone (optional, default: restaurant timezone)
- `groupBy`: `"day"`, `"week"`, `"month"` (default: `"day"`)
- `format`: `"json"`, `"excel"`, `"csv"`, `"pdf"` (default: `"json"`)

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getDailySales({
  required String dateFrom,
  required String dateTo,
  String? branchId,
  String? timezone,
}) async {
  final params = {
    'dimension': 'day',
    'dateFrom': dateFrom,
    'dateTo': dateTo,
    if (branchId != null) 'branchId': branchId,
    if (timezone != null) 'timezone': timezone,
  };
  
  final response = await dio.get(
    '/reports/v2/sales',
    queryParameters: params,
  );
  
  return response.data;
}
```

**Response Structure:**
```json
{
  "success": true,
  "data": {
    "report": {
      "summary": {
        "totalRevenue": { "amount": 15420.50, "currency": "USD" },
        "totalOrders": 145,
        "averageOrderValue": { "amount": 106.35, "currency": "USD" },
        "period": {
          "from": "2024-01-01T00:00:00.000Z",
          "to": "2024-01-31T23:59:59.999Z",
          "timezone": "UTC"
        }
      },
      "details": [
        {
          "date": "2024-01-01",
          "revenue": { "amount": 1250.75, "currency": "USD" },
          "orders": 12,
          "averageOrderValue": { "amount": 104.23, "currency": "USD" },
          "topPaymentMethod": "card",
          "breakdown": {
            "cash": { "amount": 450.00, "currency": "USD" },
            "card": { "amount": 800.75, "currency": "USD" }
          }
        }
      ]
    },
    "meta": {
      "totalDays": 31,
      "generatedAt": "2024-01-31T10:30:00.000Z"
    }
  }
}
```

### 2. Quick Daily Summary (Dashboard)
```http
GET /v2/sales/summary?dateFrom={date}&dateTo={date}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getDailySummary(String date) async {
  final response = await dio.get(
    '/reports/v2/sales/summary',
    queryParameters: {
      'dateFrom': date,
      'dateTo': date,
    },
  );
  
  return response.data;
}
```

---

## Product Performance Reports

### 1. Product Sales Report (Unified v2)
```http
GET /v2/sales?dimension=item&dateFrom={start}&dateTo={end}
```

**Query Parameters:**
- `dimension`: `"item"` (required)
- `dateFrom`, `dateTo`: Date range
- `categoryId`: Filter by category (optional)
- `sortBy`: `"revenue"`, `"quantity"`, `"profit"` (default: `"revenue"`)
- `limit`: Top N products (default: 20, max: 100)

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getProductPerformance({
  required String dateFrom,
  required String dateTo,
  String? categoryId,
  String sortBy = 'revenue',
  int limit = 20,
}) async {
  final params = {
    'dimension': 'item',
    'dateFrom': dateFrom,
    'dateTo': dateTo,
    'sortBy': sortBy,
    'limit': limit.toString(),
    if (categoryId != null) 'categoryId': categoryId,
  };
  
  final response = await dio.get(
    '/reports/v2/sales',
    queryParameters: params,
  );
  
  return response.data;
}
```

**Response Structure:**
```json
{
  "success": true,
  "data": {
    "report": {
      "summary": {
        "totalItems": 45,
        "totalQuantitySold": 1250,
        "totalRevenue": { "amount": 15420.50, "currency": "USD" }
      },
      "details": [
        {
          "itemId": "64f123abc456789012345678",
          "itemName": "Classic Burger",
          "category": "Main Dishes",
          "quantitySold": 89,
          "revenue": { "amount": 1245.60, "currency": "USD" },
          "averagePrice": { "amount": 14.00, "currency": "USD" },
          "profitMargin": 65.5,
          "trend": "up",
          "percentageOfTotal": 8.1
        }
      ]
    }
  }
}
```

### 2. Analytics Product Report
```http
GET /analytics/{restaurantId}/{branchId}/products?startDate={start}&endDate={end}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getAnalyticsProducts({
  required String restaurantId,
  required String branchId,
  required String startDate,
  required String endDate,
  String? category,
  String sortBy = 'revenue',
  int limit = 20,
}) async {
  final response = await dio.get(
    '/reports/analytics/$restaurantId/$branchId/products',
    queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
      'sortBy': sortBy,
      'limit': limit.toString(),
      if (category != null) 'category': category,
    },
  );
  
  return response.data;
}
```

---

## Staff Performance Reports

### 1. Staff Sales Report (Unified v2)
```http
GET /v2/sales?dimension=employee&dateFrom={start}&dateTo={end}
```

**Query Parameters:**
- `dimension`: `"employee"` (required)
- `dateFrom`, `dateTo`: Date range
- `staffId`: Filter by specific staff member (optional)
- `role`: Filter by role (optional)

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getStaffPerformance({
  required String dateFrom,
  required String dateTo,
  String? staffId,
  String? role,
}) async {
  final params = {
    'dimension': 'employee',
    'dateFrom': dateFrom,
    'dateTo': dateTo,
    if (staffId != null) 'staffId': staffId,
    if (role != null) 'role': role,
  };
  
  final response = await dio.get(
    '/reports/v2/sales',
    queryParameters: params,
  );
  
  return response.data;
}
```

**Response Structure:**
```json
{
  "success": true,
  "data": {
    "report": {
      "summary": {
        "totalStaff": 8,
        "totalSales": { "amount": 15420.50, "currency": "USD" },
        "averageSalesPerStaff": { "amount": 1927.56, "currency": "USD" }
      },
      "details": [
        {
          "staffId": "64f123abc456789012345678",
          "staffName": "John Smith",
          "role": "cashier",
          "totalSales": { "amount": 2845.75, "currency": "USD" },
          "totalOrders": 45,
          "averageOrderValue": { "amount": 63.24, "currency": "USD" },
          "hoursWorked": 35.5,
          "salesPerHour": { "amount": 80.16, "currency": "USD" },
          "performance": {
            "rank": 1,
            "percentageOfTotal": 18.5,
            "trend": "up"
          }
        }
      ]
    }
  }
}
```

### 2. Analytics Staff Report
```http
GET /analytics/{restaurantId}/{branchId}/staff?startDate={start}&endDate={end}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getAnalyticsStaff({
  required String restaurantId,
  required String branchId,
  required String startDate,
  required String endDate,
  String? staffId,
}) async {
  final response = await dio.get(
    '/reports/analytics/$restaurantId/$branchId/staff',
    queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
      if (staffId != null) 'staffId': staffId,
    },
  );
  
  return response.data;
}
```

---

## End of Day Reports

### 1. End of Day Report (Operational v2)
```http
GET /v2/operational?view=end_of_day&dateFrom={date}&dateTo={date}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getEndOfDayReport(String date) async {
  final response = await dio.get(
    '/reports/v2/operational',
    queryParameters: {
      'view': 'end_of_day',
      'dateFrom': date,
      'dateTo': date,
    },
  );
  
  return response.data;
}
```

**Response Structure:**
```json
{
  "success": true,
  "data": {
    "report": {
      "date": "2024-01-15",
      "branch": {
        "id": "64f123abc456789012345678",
        "name": "Main Branch"
      },
      "sales": {
        "totalRevenue": { "amount": 2845.75, "currency": "USD" },
        "totalOrders": 67,
        "averageOrderValue": { "amount": 42.48, "currency": "USD" }
      },
      "payments": {
        "cash": {
          "amount": { "amount": 1245.30, "currency": "USD" },
          "count": 28,
          "percentage": 43.7
        },
        "card": {
          "amount": { "amount": 1350.25, "currency": "USD" },
          "count": 32,
          "percentage": 47.5
        },
        "other": {
          "amount": { "amount": 250.20, "currency": "USD" },
          "count": 7,
          "percentage": 8.8
        }
      },
      "taxes": {
        "totalTax": { "amount": 184.50, "currency": "USD" },
        "taxRate": 6.5
      },
      "discounts": {
        "totalDiscounts": { "amount": 45.25, "currency": "USD" },
        "discountedOrders": 12
      },
      "voids": {
        "totalVoided": { "amount": 67.50, "currency": "USD" },
        "voidedOrders": 3
      },
      "cashDrawer": {
        "openingBalance": { "amount": 200.00, "currency": "USD" },
        "closingBalance": { "amount": 1445.30, "currency": "USD" },
        "netCash": { "amount": 1245.30, "currency": "USD" }
      }
    }
  }
}
```

---

## Sales Trends Reports

### 1. Sales Trends (Time-based)
```http
GET /v2/sales?dimension=day&dateFrom={start}&dateTo={end}&groupBy={period}
```

**Query Parameters:**
- `groupBy`: `"hour"`, `"day"`, `"week"`, `"month"`

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getSalesTrends({
  required String dateFrom,
  required String dateTo,
  String groupBy = 'day',
}) async {
  final response = await dio.get(
    '/reports/v2/sales',
    queryParameters: {
      'dimension': 'day',
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'groupBy': groupBy,
    },
  );
  
  return response.data;
}
```

### 2. Analytics Summary (with trends)
```http
GET /analytics/{restaurantId}/{branchId}/summary?startDate={start}&endDate={end}&groupBy={period}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getAnalyticsTrends({
  required String restaurantId,
  required String branchId,
  required String startDate,
  required String endDate,
  String groupBy = 'day',
}) async {
  final response = await dio.get(
    '/reports/analytics/$restaurantId/$branchId/summary',
    queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
      'groupBy': groupBy,
    },
  );
  
  return response.data;
}
```

---

## Category Reports

### 1. Sales by Category (Unified v2)
```http
GET /v2/sales?dimension=category&dateFrom={start}&dateTo={end}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getCategorySales({
  required String dateFrom,
  required String dateTo,
}) async {
  final response = await dio.get(
    '/reports/v2/sales',
    queryParameters: {
      'dimension': 'category',
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    },
  );
  
  return response.data;
}
```

**Response Structure:**
```json
{
  "success": true,
  "data": {
    "report": {
      "summary": {
        "totalCategories": 6,
        "totalRevenue": { "amount": 15420.50, "currency": "USD" }
      },
      "details": [
        {
          "categoryId": "64f123abc456789012345678",
          "categoryName": "Main Dishes",
          "revenue": { "amount": 8945.75, "currency": "USD" },
          "quantity": 234,
          "averagePrice": { "amount": 38.23, "currency": "USD" },
          "percentageOfTotal": 58.0,
          "itemCount": 12,
          "topItem": {
            "name": "Classic Burger",
            "revenue": { "amount": 1245.60, "currency": "USD" }
          }
        }
      ]
    }
  }
}
```

---

## Payment Method Reports

### 1. Payment Method Breakdown (Unified v2)
```http
GET /v2/sales?dimension=payment_method&dateFrom={start}&dateTo={end}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getPaymentMethodReport({
  required String dateFrom,
  required String dateTo,
}) async {
  final response = await dio.get(
    '/reports/v2/sales',
    queryParameters: {
      'dimension': 'payment_method',
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    },
  );
  
  return response.data;
}
```

**Response Structure:**
```json
{
  "success": true,
  "data": {
    "report": {
      "summary": {
        "totalAmount": { "amount": 15420.50, "currency": "USD" },
        "totalTransactions": 145
      },
      "details": [
        {
          "method": "card",
          "amount": { "amount": 9456.75, "currency": "USD" },
          "count": 89,
          "percentage": 61.3,
          "averageTransaction": { "amount": 106.25, "currency": "USD" },
          "breakdown": {
            "credit_card": { "amount": 7234.50, "currency": "USD" },
            "debit_card": { "amount": 2222.25, "currency": "USD" }
          }
        },
        {
          "method": "cash",
          "amount": { "amount": 4567.25, "currency": "USD" },
          "count": 42,
          "percentage": 29.6,
          "averageTransaction": { "amount": 108.74, "currency": "USD" }
        },
        {
          "method": "mobile_payment",
          "amount": { "amount": 1396.50, "currency": "USD" },
          "count": 14,
          "percentage": 9.1,
          "averageTransaction": { "amount": 99.75, "currency": "USD" }
        }
      ]
    }
  }
}
```

---

## Hourly Sales Reports

### 1. Hourly Sales Breakdown
```http
GET /v2/sales?dimension=hour&dateFrom={date}&dateTo={date}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getHourlySales(String date) async {
  final response = await dio.get(
    '/reports/v2/sales',
    queryParameters: {
      'dimension': 'hour',
      'dateFrom': date,
      'dateTo': date,
    },
  );
  
  return response.data;
}
```

**Response Structure:**
```json
{
  "success": true,
  "data": {
    "report": {
      "date": "2024-01-15",
      "summary": {
        "totalRevenue": { "amount": 2845.75, "currency": "USD" },
        "totalOrders": 67,
        "peakHour": "12:00",
        "slowestHour": "15:00"
      },
      "hourlyBreakdown": [
        {
          "hour": 8,
          "timeRange": "08:00-08:59",
          "revenue": { "amount": 145.50, "currency": "USD" },
          "orders": 4,
          "averageOrderValue": { "amount": 36.38, "currency": "USD" }
        },
        {
          "hour": 9,
          "timeRange": "09:00-09:59", 
          "revenue": { "amount": 234.75, "currency": "USD" },
          "orders": 7,
          "averageOrderValue": { "amount": 33.54, "currency": "USD" }
        }
      ]
    }
  }
}
```

---

## Analytics APIs

### 1. Analytics Summary
```http
GET /analytics/{restaurantId}/{branchId}/summary?startDate={start}&endDate={end}
```

### 2. Analytics Orders
```http
GET /analytics/{restaurantId}/{branchId}/orders?startDate={start}&endDate={end}
```

### 3. Analytics Operations
```http
GET /analytics/{restaurantId}/{branchId}/operations?startDate={start}&endDate={end}
```

**Flutter Service Class:**
```dart
class AnalyticsService {
  final Dio dio;
  
  AnalyticsService(this.dio);
  
  Future<Map<String, dynamic>> getOperationalMetrics({
    required String restaurantId,
    required String branchId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await dio.get(
      '/reports/analytics/$restaurantId/$branchId/operations',
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
      },
    );
    
    return response.data;
  }
}
```

---

## Export Options

All unified v2 endpoints support multiple export formats:

### 1. Excel Export
```dart
Future<void> exportToExcel({
  required String endpoint,
  required Map<String, String> params,
}) async {
  final exportParams = {...params, 'format': 'excel'};
  
  final response = await dio.get(
    endpoint,
    queryParameters: exportParams,
    options: Options(responseType: ResponseType.bytes),
  );
  
  // Save file to device
  await saveFile('report.xlsx', response.data);
}
```

### 2. CSV Export
```dart
Future<void> exportToCSV({
  required String endpoint,
  required Map<String, String> params,
}) async {
  final exportParams = {...params, 'format': 'csv'};
  
  final response = await dio.get(
    endpoint,
    queryParameters: exportParams,
  );
  
  // Response will be CSV text
  await saveFile('report.csv', response.data);
}
```

### 3. PDF Export
```dart
Future<void> exportToPDF({
  required String endpoint,
  required Map<String, String> params,
}) async {
  final exportParams = {...params, 'format': 'pdf'};
  
  final response = await dio.get(
    endpoint,
    queryParameters: exportParams,
    options: Options(responseType: ResponseType.bytes),
  );
  
  await saveFile('report.pdf', response.data);
}
```

---

## Flutter Integration Examples

### 1. Complete Reports Service
```dart
class ReportsService {
  final Dio dio;
  
  ReportsService(this.dio);
  
  // Daily sales
  Future<DailySalesReport> getDailySales({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    final response = await dio.get(
      '/reports/v2/sales',
      queryParameters: {
        'dimension': 'day',
        'dateFrom': startDate.toIso8601String(),
        'dateTo': endDate.toIso8601String(),
        if (branchId != null) 'branchId': branchId,
      },
    );
    
    return DailySalesReport.fromJson(response.data);
  }
  
  // End of day
  Future<EndOfDayReport> getEndOfDay(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    final response = await dio.get(
      '/reports/v2/operational',
      queryParameters: {
        'view': 'end_of_day',
        'dateFrom': dateStr,
        'dateTo': dateStr,
      },
    );
    
    return EndOfDayReport.fromJson(response.data);
  }
  
  // Staff performance
  Future<StaffPerformanceReport> getStaffPerformance({
    required DateTime startDate,
    required DateTime endDate,
    String? staffId,
  }) async {
    final response = await dio.get(
      '/reports/v2/sales',
      queryParameters: {
        'dimension': 'employee',
        'dateFrom': startDate.toIso8601String(),
        'dateTo': endDate.toIso8601String(),
        if (staffId != null) 'staffId': staffId,
      },
    );
    
    return StaffPerformanceReport.fromJson(response.data);
  }
}
```

### 2. Error Handling
```dart
class ReportsRepository {
  final ReportsService _service;
  
  ReportsRepository(this._service);
  
  Future<ApiResult<DailySalesReport>> getDailySales({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final report = await _service.getDailySales(
        startDate: startDate,
        endDate: endDate,
      );
      
      return ApiResult.success(report);
    } on DioException catch (e) {
      return ApiResult.failure(_handleDioError(e));
    } catch (e) {
      return ApiResult.failure('Unknown error occurred');
    }
  }
  
  String _handleDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request parameters';
      case 401:
        return 'Unauthorized access';
      case 403:
        return 'Insufficient permissions';
      case 404:
        return 'Report not found';
      case 500:
        return 'Server error. Please try again later';
      default:
        return 'Network error occurred';
    }
  }
}
```

### 3. Data Models
```dart
class DailySalesReport {
  final ReportSummary summary;
  final List<DailySalesDetail> details;
  final ReportMeta meta;
  
  DailySalesReport({
    required this.summary,
    required this.details,
    required this.meta,
  });
  
  factory DailySalesReport.fromJson(Map<String, dynamic> json) {
    return DailySalesReport(
      summary: ReportSummary.fromJson(json['data']['report']['summary']),
      details: (json['data']['report']['details'] as List)
          .map((item) => DailySalesDetail.fromJson(item))
          .toList(),
      meta: ReportMeta.fromJson(json['data']['meta']),
    );
  }
}

class ReportSummary {
  final Money totalRevenue;
  final int totalOrders;
  final Money averageOrderValue;
  final DateRange period;
  
  // ... constructor and fromJson
}

class Money {
  final double amount;
  final String currency;
  
  // ... constructor and fromJson
}
```

### 4. State Management (with Provider)
```dart
class ReportsProvider extends ChangeNotifier {
  final ReportsRepository _repository;
  
  // State
  DailySalesReport? _dailySales;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  DailySalesReport? get dailySales => _dailySales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  ReportsProvider(this._repository);
  
  Future<void> loadDailySales({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _error = null;
    
    final result = await _repository.getDailySales(
      startDate: startDate,
      endDate: endDate,
    );
    
    result.when(
      success: (report) {
        _dailySales = report;
        _setLoading(false);
      },
      failure: (error) {
        _error = error;
        _setLoading(false);
      },
    );
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
```

## Summary

This API documentation provides all the endpoints you need for your Flutter frontend reporting features:

✅ **Daily Sales** - `/v2/sales?dimension=day`  
✅ **Product Reports** - `/v2/sales?dimension=item` & `/analytics/.../products`  
✅ **Staff Reports** - `/v2/sales?dimension=employee` & `/analytics/.../staff`  
✅ **End of Day** - `/v2/operational?view=end_of_day`  
✅ **Sales Trends** - `/v2/sales` with `groupBy` parameter  
✅ **Categories** - `/v2/sales?dimension=category`  
✅ **Payment Methods** - `/v2/sales?dimension=payment_method`  
✅ **Hourly Sales** - `/v2/sales?dimension=hour`  

All endpoints support:
- Flexible date/time filtering with timezone support
- Multiple export formats (JSON, Excel, CSV, PDF)
- Comprehensive error handling
- Pagination and sorting options
- Branch-level filtering

Use the v2 unified endpoints for new development as they provide more flexibility and better performance.