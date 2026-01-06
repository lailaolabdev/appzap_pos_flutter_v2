# Basic Inventory Management Feature

## Overview
This document outlines the core inventory management functionality available in the AppZap POS API system. The inventory feature provides essential stock tracking, item management, and reporting capabilities for restaurant operations.

## Core Features

### 1. Inventory Item Management
- **Create Items**: Add new inventory items with detailed information
- **View Items**: List and search inventory items with filtering
- **Update Items**: Modify item details, pricing, and configurations
- **Delete Items**: Remove items from inventory (with safety checks)

### 2. Stock Management
- **Stock Adjustment**: Add, remove, or set stock levels
- **Stock Transfer**: Move inventory between locations/branches
- **Real-time Tracking**: Live updates of stock levels
- **Reserved Stock**: Track pending/allocated inventory

### 3. Basic Reporting
- **Current Stock Levels**: View available inventory quantities
- **Stock Valuation**: Calculate total inventory value
- **Transaction History**: Track all stock movements
- **Low Stock Alerts**: Notifications for items below minimum levels

## API Endpoints

### Item Management
```
GET    /api/v1/inventory/items           # List all inventory items
POST   /api/v1/inventory/items           # Create new inventory item
GET    /api/v1/inventory/items/:id       # Get specific item details
PATCH  /api/v1/inventory/items/:id       # Update inventory item
DELETE /api/v1/inventory/items/:id       # Delete inventory item
```

### Stock Operations
```
POST   /api/v1/inventory/stock/adjust    # Adjust stock levels (ADD/REMOVE/SET)
POST   /api/v1/inventory/stock/transfer  # Transfer stock between locations
GET    /api/v1/inventory/transactions    # View stock transaction history
```

### Reporting & Analytics
```
GET    /api/v1/inventory/valuation       # Get inventory valuation report
GET    /api/v1/inventory/alerts          # Get low stock alerts
GET    /api/v1/inventory/health          # System health check
```

## Basic Inventory Item Structure

```javascript
{
  "id": "item_id",
  "name": "Item Name",
  "description": "Item description",
  "sku": "UNIQUE_SKU_CODE",
  "barcode": "1234567890",
  "category": "ingredient|finished_good|raw_material",
  "unitOfMeasure": {
    "name": "Kilogram",
    "abbreviation": "kg",
    "category": "weight"
  },
  "currentStock": 100,
  "availableStock": 85,
  "reservedStock": 15,
  "costPerUnit": 25.50,
  "sellingPrice": 35.00,
  "minStockLevel": 10,
  "maxStockLevel": 500,
  "status": "active|inactive",
  "restaurantId": "restaurant_id",
  "branchId": "branch_id"
}
```

## Basic Operations

### 1. Add New Inventory Item
```javascript
POST /api/v1/inventory/items
{
  "name": "Tomatoes",
  "sku": "TOM001",
  "description": "Fresh tomatoes for cooking",
  "category": "ingredient",
  "unitOfMeasure": {
    "name": "Kilogram",
    "abbreviation": "kg",
    "category": "weight"
  },
  "costPerUnit": 15.00,
  "minStockLevel": 5,
  "maxStockLevel": 100
}
```

### 2. Adjust Stock Levels
```javascript
POST /api/v1/inventory/stock/adjust
{
  "itemId": "item_id",
  "operation": "ADD", // ADD, REMOVE, SET
  "quantity": 50,
  "reason": "Purchase received",
  "notes": "Weekly supplier delivery"
}
```

### 3. Check Current Stock
```javascript
GET /api/v1/inventory/items?fields=name,sku,currentStock,availableStock,minStockLevel
```

### 4. Get Low Stock Alerts
```javascript
GET /api/v1/inventory/alerts?type=low_stock&status=active
```

## Stock Transaction Types
- **PURCHASE**: Stock received from supplier
- **SALE**: Stock consumed in sales/orders
- **ADJUSTMENT**: Manual stock corrections
- **TRANSFER**: Movement between locations
- **WASTE**: Stock write-offs/damage
- **COUNT**: Physical inventory count adjustments

## Key Features for Daily Operations

### Stock Monitoring
- Real-time stock level tracking
- Automatic low stock notifications
- Stock valuation calculations
- Movement history tracking

### Basic Reporting
- Current inventory status
- Stock movement reports
- Inventory valuation summaries
- Alert management

### Multi-Location Support
- Branch-specific inventory tracking
- Stock transfers between locations
- Location-based reporting
- Centralized inventory management

## Getting Started

1. **Setup Items**: Create your basic inventory items with SKUs
2. **Set Stock Levels**: Add initial stock quantities
3. **Configure Alerts**: Set minimum stock thresholds
4. **Monitor Daily**: Check stock levels and alerts regularly
5. **Track Movements**: Review transaction history for auditing

## Authentication & Authorization
All inventory endpoints require:
- Valid authentication token
- Appropriate role permissions (manager, staff)
- Restaurant/branch context validation

## Error Handling
The system provides standard HTTP status codes with detailed error messages:
- `400` - Bad Request (validation errors)
- `401` - Unauthorized
- `403` - Forbidden (insufficient permissions)
- `404` - Resource not found
- `409` - Conflict (duplicate SKU, etc.)
- `500` - Internal server error

## Support & Maintenance
- Regular stock count reconciliation recommended
- Monitor system alerts for inventory issues
- Review transaction logs for audit trails
- Backup inventory data regularly

---

*This basic inventory system provides essential functionality for restaurant stock management. For advanced features like purchase orders, supplier management, and detailed analytics, refer to the complete inventory documentation.*