# AppZap Universal POS - Complete API Documentation
**Version:** 1.0 (Phase 1 - Basic POS)  
**Target:** Flutter Mobile POS Application  
**Date:** January 2025  
**Industries:** Mini Marts, Cafes, Shops, Retail Stores, Takeaway Restaurants

---

## 📋 Table of Contents

1. [Overview & Getting Started](#1-overview--getting-started)
2. [Authentication](#2-authentication)
3. [Product Management](#3-product-management)
4. [Sales & Checkout](#4-sales--checkout)
5. [Payment Processing](#5-payment-processing-usp)
6. [Inventory Management](#6-inventory-management-usp)
7. [Customer & Loyalty](#7-customer--loyalty-usp)
8. [Reports](#8-reports)
9. [WebSocket Real-time](#9-websocket-real-time)
10. [Error Handling](#10-error-handling)
11. [Flutter Implementation Guide](#11-flutter-implementation-guide)
12. [Offline Mode Strategy](#12-offline-mode-strategy)

---

## 1. Overview & Getting Started

### 1.1 API Base URL

```
Production: https://api.appzap.la/api/v1
Staging: https://staging-api.appzap.la/api/v1
WebSocket: wss://ws.appzap.la
```

### 1.2 Key Features (Phase 1)

**✅ Loyverse Parity Features:**
- Product/Inventory management
- Sales & Checkout
- Staff management
- Customer database
- Basic reports
- Multi-branch support

**🏆 3 Winning Features (Better than Loyverse):**

1. **PhayPay Built-in Payment** - Native integration with Laos banking
2. **Advanced Inventory** - Purchase orders, batch tracking, multi-location
3. **Customer Loyalty Program** - Points, tiers, rewards (FREE!)

### 1.3 Request/Response Format

All API requests must include:

**Headers:**
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer {jwt_token}
```

**Standard Response Format:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message",
  "pagination": {
    "page": 1,
    "limit": 50,
    "totalPages": 10,
    "totalResults": 500
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "code": "ERROR_CODE",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

---

## 2. Authentication

> **📱 Laos-First Design:** Phone number + PIN authentication for fast, local-friendly POS experience

### 2.1 Send OTP (Sign Up / Verification)

Start the registration or verification process by sending an OTP to the phone number.

```http
POST /auth/phone/send-otp
Content-Type: application/json

{
  "phone": "020 12345678",
  "userType": "staff",
  "purpose": "registration"
}
```

**Purpose Options:**
- `registration` - New user signup
- `login` - Login verification (optional)
- `forgot_pin` - Reset PIN

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP sent to 020 12345678",
  "expiresIn": 300
}
```

**Error Response (Rate Limited):**
```json
{
  "success": false,
  "message": "Too many OTP requests. Please try again in 1 hour.",
  "code": "RATE_LIMIT_EXCEEDED"
}
```

---

### 2.2 Verify OTP

Verify the OTP code received via SMS.

```http
POST /auth/phone/verify-otp
Content-Type: application/json

{
  "phone": "020 12345678",
  "otp": "123456"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "verified": true,
  "message": "Phone number verified successfully",
  "tempToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 900
}
```

**Note:** `tempToken` is valid for 15 minutes and must be used to complete registration.

**Error Response (Invalid OTP):**
```json
{
  "success": false,
  "verified": false,
  "message": "Invalid OTP. 2 attempts remaining.",
  "code": "INVALID_OTP",
  "remainingAttempts": 2
}
```

---

### 2.3 Register with Phone (After OTP Verification)

Complete registration after OTP verification.

```http
POST /auth/phone/register
Content-Type: application/json

{
  "tempToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "phone": "020 12345678",
  "name": "John Doe",
  "pin": "1234",
  "restaurantId": "60d5ec854b24c72d88c4e120",
  "branchId": "60d5ec954b24c72d88c4e121",
  "role": "cashier"
}
```

**Fields:**
- `tempToken` (required) - Token from OTP verification
- `phone` (required) - Phone number (must match verification)
- `name` (required) - Staff member name
- `pin` (required) - 4-6 digit PIN for quick login
- `restaurantId` (required) - Restaurant ID
- `branchId` (optional) - Branch ID
- `role` (optional) - Default: "cashier"

**Response (201 Created):**
```json
{
  "success": true,
  "user": {
    "_id": "60d5ec954b24c72d88c4e123",
    "name": "John Doe",
    "phone": "020 12345678",
    "userId": "STORE01-345678",
    "role": "cashier",
    "isPhoneVerified": true,
    "restaurantId": "60d5ec854b24c72d88c4e120",
    "branchId": "60d5ec954b24c72d88c4e121",
    "permissions": [
      "manage_sales",
      "view_reports",
      "manage_customers"
    ]
  },
  "tokens": {
    "access": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires": "2025-01-15T12:00:00Z"
    },
    "refresh": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires": "2025-02-14T10:00:00Z"
    }
  }
}
```

---

### 2.4 Login with Phone + PIN 🚀 (Recommended for POS)

Fast login for daily POS usage - just phone number + 4-digit PIN.

```http
POST /auth/phone/login
Content-Type: application/json

{
  "phone": "020 12345678",
  "pin": "1234",
  "userType": "staff"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "user": {
    "_id": "60d5ec954b24c72d88c4e123",
    "name": "John Doe",
    "phone": "020 12345678",
    "userId": "STORE01-345678",
    "role": "cashier",
    "restaurantId": {
      "_id": "60d5ec854b24c72d88c4e120",
      "name": "My Store",
      "currency": "LAK"
    },
    "branchId": {
      "_id": "60d5ec954b24c72d88c4e121",
      "name": "Main Branch"
    },
    "permissions": [
      "manage_sales",
      "view_reports",
      "manage_customers"
    ]
  },
  "tokens": {
    "access": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires": "2025-01-15T12:00:00Z"
    },
    "refresh": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires": "2025-02-14T10:00:00Z"
    }
  }
}
```

**Why Phone + PIN?**
- ⚡ **Super Fast:** 2 seconds to login
- 🧠 **Easy to Remember:** Just 4 digits
- 📱 **Local-Friendly:** Phone numbers are universal in Laos
- 🔒 **Secure Enough:** For POS staff access

---

### 2.5 Forgot PIN

Reset PIN using OTP verification.

**Step 1: Request OTP**
```http
POST /auth/phone/forgot-pin
Content-Type: application/json

{
  "phone": "020 12345678",
  "userType": "staff"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent to your phone number",
  "expiresIn": 300
}
```

**Step 2: Reset PIN with OTP**
```http
POST /auth/phone/reset-pin
Content-Type: application/json

{
  "phone": "020 12345678",
  "otp": "123456",
  "newPin": "5678",
  "userType": "staff"
}
```

**Response:**
```json
{
  "success": true,
  "message": "PIN reset successfully"
}
```

---

### 2.6 Setup/Change PIN (Authenticated)

Change PIN while logged in (requires current PIN).

```http
POST /auth/phone/setup-pin
Authorization: Bearer {token}
Content-Type: application/json

{
  "pin": "5678",
  "oldPin": "1234"
}
```

**Response:**
```json
{
  "success": true,
  "message": "PIN setup successfully"
}
```

---

### 2.7 Refresh Tokens

Get new access token using refresh token.

```http
POST /auth/refresh-tokens
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## 3. Product Management

### 3.1 Get Products/Menu Items

```http
GET /menu/items
Authorization: Bearer {token}

Query Parameters:
  branchId (required) - Current branch ID
  isActive (optional) - Filter active items (default: true)
  categoryId (optional) - Filter by category
  search (optional) - Search by name, SKU, or barcode
  limit (optional) - Results per page (default: 100, max: 500)
  page (optional) - Page number (default: 1)
```

**Example Request:**
```http
GET /menu/items?branchId=60d5ec954b24c72d88c4e121&isActive=true&limit=500
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "60d5ecb74b24c72d88c4e125",
      "name": "Coca Cola 330ml",
      "description": "Refreshing soft drink",
      "itemCode": "COKE330",
      "barcode": "8851959132012",
      "sku": "COKE-330ML",
      
      "categoryId": "60d5eca74b24c72d88c4e124",
      "categoryName": "Beverages",
      
      "pricing": {
        "basePrice": 8000,
        "costPrice": 6000,
        "taxRate": 10,
        "taxIncluded": false,
        "currency": "LAK"
      },
      
      "images": [
        {
          "url": "https://cdn.appzap.la/images/coke-330ml.jpg",
          "size": "medium"
        }
      ],
      
      "inventory": {
        "trackStock": true,
        "currentStock": 150,
        "lowStockThreshold": 20,
        "isLowStock": false,
        "unit": "unit"
      },
      
      "isActive": true,
      "displayOrder": 1
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 500,
    "totalPages": 1,
    "totalResults": 45
  }
}
```

### 3.2 Get Product by ID

```http
GET /menu/items/:itemId
Authorization: Bearer {token}
```

### 3.3 Get Categories

```http
GET /menu/categories
Authorization: Bearer {token}

Query Parameters:
  restaurantId (required)
  isActive (optional) - default: true
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "60d5eca74b24c72d88c4e124",
      "name": "Beverages",
      "description": "Soft drinks, juices, water",
      "displayOrder": 1,
      "isActive": true,
      "itemCount": 25
    },
    {
      "_id": "60d5eca84b24c72d88c4e125",
      "name": "Snacks",
      "description": "Chips, crackers, cookies",
      "displayOrder": 2,
      "isActive": true,
      "itemCount": 40
    }
  ]
}
```

### 3.4 Search Product by Barcode

```http
GET /menu/items?branchId={branchId}&search={barcode}
Authorization: Bearer {token}
```

---

## 4. Sales & Checkout

### 4.1 Create Sale/Order (Takeaway/Quick Sale)

```http
POST /orders/takeaway
Authorization: Bearer {token}
Content-Type: application/json

{
  "branchId": "60d5ec954b24c72d88c4e121",
  "orderType": "takeaway",
  "customer": {
    "customerId": "60d5ecb84b24c72d88c4e126",
    "name": "John Doe",
    "phone": "020 12345678"
  },
  "items": [
    {
      "menuItemId": "60d5ecb74b24c72d88c4e125",
      "quantity": 2,
      "unitPrice": 8000,
      "notes": ""
    },
    {
      "menuItemId": "60d5ecb94b24c72d88c4e127",
      "quantity": 1,
      "unitPrice": 15000,
      "notes": "Extra ice"
    }
  ],
  "discounts": [
    {
      "type": "percentage",
      "value": 10,
      "reason": "Member discount"
    }
  ]
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "orderId": "ORD-20250115-00045",
    "_id": "60d5ecc04b24c72d88c4e128",
    "qNumber": 45,
    "orderType": "takeaway",
    "orderStatus": "pending",
    
    "items": [
      {
        "_id": "item1",
        "menuItemId": "60d5ecb74b24c72d88c4e125",
        "name": "Coca Cola 330ml",
        "quantity": 2,
        "unitPrice": 8000,
        "subtotal": 16000,
        "tax": 1600,
        "total": 17600
      },
      {
        "_id": "item2",
        "menuItemId": "60d5ecb94b24c72d88c4e127",
        "name": "Iced Coffee",
        "quantity": 1,
        "unitPrice": 15000,
        "notes": "Extra ice",
        "subtotal": 15000,
        "tax": 1500,
        "total": 16500
      }
    ],
    
    "pricing": {
      "subtotal": 31000,
      "discounts": [
        {
          "type": "percentage",
          "value": 10,
          "amount": 3100,
          "reason": "Member discount"
        }
      ],
      "discountTotal": 3100,
      "subtotalAfterDiscount": 27900,
      "tax": 2790,
      "total": 30690,
      "currency": "LAK"
    },
    
    "customer": {
      "customerId": "60d5ecb84b24c72d88c4e126",
      "name": "John Doe",
      "phone": "020 12345678"
    },
    
    "createdAt": "2025-01-15T10:30:00Z",
    "createdBy": {
      "staffId": "60d5ec954b24c72d88c4e123",
      "name": "Cashier 1"
    }
  }
}
```

### 4.2 Get Order by ID

```http
GET /orders/:orderId
Authorization: Bearer {token}
```

### 4.3 Update Order Status

```http
PATCH /orders/:orderId/status
Authorization: Bearer {token}
Content-Type: application/json

{
  "orderStatus": "completed"
}
```

**Available Statuses:**
- `pending` - Order created, not paid
- `confirmed` - Order confirmed
- `preparing` - Being prepared
- `ready` - Ready for pickup
- `completed` - Completed and paid
- `cancelled` - Cancelled

---

## 5. Payment Processing (🔥 USP!)

### 5.1 Calculate Pricing (Before Payment)

```http
POST /checkout/calculate-pricing
Authorization: Bearer {token}
Content-Type: application/json

{
  "orderId": "60d5ecc04b24c72d88c4e128"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "pricing": {
      "subtotal": 31000,
      "discounts": [...],
      "discountTotal": 3100,
      "subtotalAfterDiscount": 27900,
      "tax": 2790,
      "total": 30690,
      "currency": "LAK"
    }
  }
}
```

### 5.2 Process Cash Payment

```http
POST /checkout/process-payment
Authorization: Bearer {token}
Content-Type: application/json

{
  "orderId": "60d5ecc04b24c72d88c4e128",
  "branchId": "60d5ec954b24c72d88c4e121",
  "paymentMethod": "cash",
  "amount": {
    "total": 30690,
    "tendered": 50000,
    "change": 19310,
    "currency": "LAK"
  },
  "paymentDetails": {
    "cash": {
      "denominationBreakdown": [
        {
          "denomination": 50000,
          "count": 1,
          "total": 50000
        }
      ]
    }
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "transactionId": "TXN-20250115-00123",
    "paymentId": "PAY-20250115-00456",
    "orderId": "ORD-20250115-00045",
    "status": "completed",
    "paymentMethod": "cash",
    "amount": {
      "total": 30690,
      "tendered": 50000,
      "change": 19310,
      "currency": "LAK"
    },
    "completedAt": "2025-01-15T10:35:00Z"
  }
}
```

### 5.3 PhayPay Payment (🎯 KILLER FEATURE!)

#### 5.3.1 Create PhayPay Payment

```http
POST /payments/phajay/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "orderId": "60d5ecc04b24c72d88c4e128",
  "branchId": "60d5ec954b24c72d88c4e121",
  "amount": 30690,
  "currency": "LAK",
  "bankMethod": "bank_qr_jdb",
  "description": "Order #ORD-20250115-00045",
  "customer": {
    "name": "John Doe",
    "phone": "020 12345678"
  }
}
```

**Bank Methods Available:**
- `bank_qr_jdb` - Joint Development Bank
- `bank_qr_bcel` - BCEL
- `bank_qr_ib` - Indochina Bank
- `bank_qr_ldb` - Lao Development Bank
- `payment_link` - Universal payment link (customer chooses bank)

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "paymentId": "PHAJAY-20250115-00789",
    "orderId": "ORD-20250115-00045",
    "qrCode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...",
    "qrCodeUrl": "https://api.appzap.la/payments/qr/PHAJAY-20250115-00789",
    "paymentLink": "https://pay.phajay.la/p/PHAJAY-20250115-00789",
    "amount": 30690,
    "currency": "LAK",
    "bankMethod": "bank_qr_jdb",
    "status": "pending",
    "expiresAt": "2025-01-15T10:45:00Z",
    "createdAt": "2025-01-15T10:35:00Z"
  }
}
```

#### 5.3.2 Check PhayPay Payment Status

```http
GET /payments/phajay/status/:paymentId
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "paymentId": "PHAJAY-20250115-00789",
    "status": "completed",
    "paidAt": "2025-01-15T10:36:30Z",
    "amount": 30690,
    "transactionId": "TXN-20250115-00123",
    "bankReference": "JDB20250115103630"
  }
}
```

**Payment Statuses:**
- `pending` - Waiting for payment
- `completed` - Payment successful
- `failed` - Payment failed
- `expired` - QR code expired (10 minutes)

---

## 6. Inventory Management (🏆 USP #2)

### 6.1 Get Inventory Items

```http
GET /inventory/items
Authorization: Bearer {token}

Query Parameters:
  branchId (required)
  search (optional)
  categoryId (optional)
  status (optional) - active, low_stock, out_of_stock
  limit (optional) - default: 100
  page (optional) - default: 1
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "60d5ecd04b24c72d88c4e129",
      "name": "Coca Cola 330ml - Inventory",
      "sku": "COKE-330ML-INV",
      "barcode": "8851959132012",
      "itemId": "60d5ecb74b24c72d88c4e125",
      "itemType": "menu_item",
      "currentStock": 150,
      "lowStockThreshold": 20,
      "isLowStock": false,
      "unit": "unit",
      "costPrice": 6000,
      "averageCost": 6000,
      "totalValue": 900000,
      "lastStockUpdate": "2025-01-15T08:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 100,
    "totalResults": 45
  }
}
```

### 6.2 Adjust Stock

```http
POST /inventory/stock/adjust
Authorization: Bearer {token}
Content-Type: application/json

{
  "inventoryItemId": "60d5ecd04b24c72d88c4e129",
  "branchId": "60d5ec954b24c72d88c4e121",
  "operation": "ADD",
  "quantity": 50,
  "reason": "Purchase from supplier",
  "notes": "PO#12345",
  "costPrice": 6000
}
```

**Operations:**
- `ADD` - Add stock (purchase, return)
- `REMOVE` - Remove stock (damage, theft, waste)
- `SET` - Set exact stock level (physical count)

**Response:**
```json
{
  "success": true,
  "data": {
    "transactionId": "INV-TXN-20250115-00234",
    "previousStock": 150,
    "newStock": 200,
    "operation": "ADD",
    "quantity": 50
  }
}
```

### 6.3 Get Low Stock Alerts

```http
GET /inventory/alerts
Authorization: Bearer {token}

Query Parameters:
  branchId (required)
  alertType (optional) - low_stock, out_of_stock, expiring_soon
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "alert1",
      "inventoryItemId": "60d5ecd14b24c72d88c4e130",
      "itemName": "Pepsi 330ml",
      "alertType": "low_stock",
      "currentStock": 15,
      "threshold": 20,
      "severity": "warning",
      "createdAt": "2025-01-15T09:00:00Z"
    }
  ]
}
```

### 6.4 Create Purchase Order

```http
POST /inventory/purchase-orders
Authorization: Bearer {token}
Content-Type: application/json

{
  "branchId": "60d5ec954b24c72d88c4e121",
  "supplierId": "60d5ece04b24c72d88c4e131",
  "items": [
    {
      "inventoryItemId": "60d5ecd04b24c72d88c4e129",
      "quantity": 100,
      "unitCost": 6000
    }
  ],
  "expectedDeliveryDate": "2025-01-20",
  "notes": "Urgent order"
}
```

### 6.5 Get Inventory Valuation

```http
GET /inventory/valuation
Authorization: Bearer {token}

Query Parameters:
  branchId (required)
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalValue": 45000000,
    "totalItems": 45,
    "currency": "LAK",
    "lastUpdated": "2025-01-15T10:00:00Z"
  }
}
```

---

## 7. Customer & Loyalty (🏆 USP #3)

### 7.1 Get Customers

```http
GET /crm/customers
Authorization: Bearer {token}

Query Parameters:
  restaurantId (required)
  search (optional)
  limit (optional)
  page (optional)
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "60d5ecb84b24c72d88c4e126",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "020 12345678",
      "loyaltyPoints": 1250,
      "tier": "silver",
      "totalSpent": 5000000,
      "visitCount": 45,
      "lastVisit": "2025-01-15T10:30:00Z",
      "createdAt": "2024-06-15T08:00:00Z"
    }
  ]
}
```

### 7.2 Create Customer

```http
POST /crm/customers
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Jane Smith",
  "phone": "020 98765432",
  "email": "jane@example.com",
  "dateOfBirth": "1990-05-15"
}
```

### 7.3 Get Customer Loyalty Points

```http
GET /crm/customers/:customerId/points
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "customerId": "60d5ecb84b24c72d88c4e126",
    "currentPoints": 1250,
    "tier": "silver",
    "nextTier": "gold",
    "pointsToNextTier": 250,
    "history": [
      {
        "type": "earned",
        "points": 100,
        "orderId": "ORD-20250115-00045",
        "date": "2025-01-15T10:35:00Z",
        "description": "Purchase LAK 100,000"
      }
    ]
  }
}
```

### 7.4 Redeem Loyalty Points

```http
POST /crm/loyalty-program/redeem
Authorization: Bearer {token}
Content-Type: application/json

{
  "customerId": "60d5ecb84b24c72d88c4e126",
  "points": 100,
  "orderId": "60d5ecc04b24c72d88c4e128"
}
```

---

## 8. Reports

### 8.1 Daily Sales Summary

```http
GET /reports/daily-summary
Authorization: Bearer {token}

Query Parameters:
  branchId (required)
  startDate (required) - YYYY-MM-DD
  endDate (required) - YYYY-MM-DD
```

**Response:**
```json
{
  "success": true,
  "data": {
    "period": {
      "startDate": "2025-01-15",
      "endDate": "2025-01-15"
    },
    "sales": {
      "totalSales": 15000000,
      "totalOrders": 120,
      "averageOrderValue": 125000,
      "totalTax": 1500000
    },
    "payments": {
      "cash": 8000000,
      "card": 2000000,
      "phaypay": 5000000
    },
    "topProducts": [
      {
        "productId": "60d5ecb74b24c72d88c4e125",
        "productName": "Coca Cola 330ml",
        "quantity": 150,
        "revenue": 1200000
      }
    ]
  }
}
```

### 8.2 End of Day Report

```http
GET /reports/end-of-day
Authorization: Bearer {token}

Query Parameters:
  branchId (required)
  date (required) - YYYY-MM-DD
```

### 8.3 Sales by Product

```http
GET /reports/sales-items-report
Authorization: Bearer {token}

Query Parameters:
  branchId (required)
  startDate (required)
  endDate (required)
```

### 8.4 Sales by Staff

```http
GET /reports/sales-by-employee
Authorization: Bearer {token}

Query Parameters:
  branchId (required)
  startDate (required)
  endDate (required)
```

---

## 9. WebSocket Real-time

### 9.1 Connection Setup

```javascript
// Flutter: socket_io_client package
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io('wss://ws.appzap.la', {
  'transports': ['websocket'],
  'auth': {
    'token': jwtToken
  }
});

socket.on('connect', (_) {
  print('Connected to WebSocket');
  
  // Join room for your branch
  socket.emit('join', {
    'room': 'branch:${branchId}'
  });
});
```

### 9.2 Event Subscriptions

**Order Events:**
```javascript
socket.on('order:created', (data) {
  print('New order created: ${data['orderId']}');
  // Update UI
});

socket.on('order:updated', (data) {
  print('Order updated: ${data['orderId']}');
  // Refresh order
});

socket.on('order:completed', (data) {
  print('Order completed: ${data['orderId']}');
  // Show notification
});
```

**Payment Events:**
```javascript
socket.on('payment:completed', (data) {
  print('Payment completed: ${data['paymentId']}');
  // Update payment status
});

socket.on('payment:failed', (data) {
  print('Payment failed: ${data['paymentId']}');
  // Show error
});
```

**Inventory Events:**
```javascript
socket.on('inventory:low_stock', (data) {
  print('Low stock alert: ${data['itemName']}');
  // Show alert badge
});

socket.on('inventory:out_of_stock', (data) {
  print('Out of stock: ${data['itemName']}');
  // Disable product
});
```

---

## 10. Error Handling

### 10.1 Standard Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Invalid or expired token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `DUPLICATE_ENTRY` | 409 | Resource already exists |
| `LOW_STOCK` | 400 | Insufficient stock |
| `PAYMENT_FAILED` | 402 | Payment processing failed |
| `INTERNAL_ERROR` | 500 | Server error |

### 10.2 Error Response Format

```json
{
  "success": false,
  "message": "Validation error",
  "code": "VALIDATION_ERROR",
  "errors": [
    {
      "field": "quantity",
      "message": "Quantity must be greater than 0"
    }
  ]
}
```

### 10.3 Flutter Error Handling

```dart
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final List<ValidationError>? errors;
  
  ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.errors,
  });
  
  factory ApiException.fromResponse(Response response) {
    final data = response.data;
    return ApiException(
      message: data['message'] ?? 'Unknown error',
      code: data['code'],
      statusCode: response.statusCode,
      errors: (data['errors'] as List?)
          ?.map((e) => ValidationError.fromJson(e))
          .toList(),
    );
  }
  
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => code == 'VALIDATION_ERROR';
  bool get isLowStock => code == 'LOW_STOCK';
}

// Usage in service
try {
  final response = await dio.post('/orders/takeaway', data: {...});
  return Order.fromJson(response.data['data']);
} on DioError catch (e) {
  if (e.response != null) {
    throw ApiException.fromResponse(e.response!);
  } else {
    throw ApiException(message: 'Network error');
  }
}
```

---

## 11. Flutter Implementation Guide

### 11.1 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── routes.dart
│   └── theme.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_config.dart
│   │   └── api_exception.dart
│   ├── models/
│   │   ├── product.dart
│   │   ├── order.dart
│   │   ├── customer.dart
│   │   └── payment.dart
│   └── services/
│       ├── auth_service.dart
│       ├── product_service.dart
│       ├── order_service.dart
│       ├── payment_service.dart
│       └── websocket_service.dart
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── pin_login_screen.dart
│   ├── pos/
│   │   ├── pos_screen.dart
│   │   ├── widgets/
│   │   │   ├── product_grid.dart
│   │   │   ├── cart_panel.dart
│   │   │   └── category_bar.dart
│   │   └── payment_dialog.dart
│   ├── inventory/
│   │   └── inventory_screen.dart
│   ├── customers/
│   │   └── customers_screen.dart
│   └── reports/
│       └── reports_screen.dart
└── utils/
    ├── currency_formatter.dart
    ├── date_formatter.dart
    └── validators.dart
```

### 11.2 API Client Setup

```dart
// core/api/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio dio;
  
  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
  
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<T> post<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(dynamic error) {
    if (error is DioError) {
      if (error.response != null) {
        return ApiException.fromResponse(error.response!);
      } else {
        return ApiException(message: 'Network error');
      }
    }
    return Exception('Unknown error');
  }
}

// Auth interceptor
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage().read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

### 11.3 Complete POS Screen Example

```dart
// features/pos/pos_screen.dart
class POSScreen extends StatefulWidget {
  @override
  _POSScreenState createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();
  
  Cart cart = Cart();
  List<Product> products = [];
  List<Category> categories = [];
  String? selectedCategoryId;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _productService.getProducts(),
        _productService.getCategories(),
      ]);
      setState(() {
        products = results[0] as List<Product>;
        categories = results[1] as List<Category>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }
  
  void _addToCart(Product product) {
    if (product.inventory != null && !product.isInStock) {
      _showError('Product out of stock');
      return;
    }
    setState(() {
      cart.addItem(product);
    });
  }
  
  Future<void> _checkout() async {
    if (cart.isEmpty) {
      _showError('Cart is empty');
      return;
    }
    
    // Show payment method dialog
    final paymentMethod = await showDialog<PaymentMethod>(
      context: context,
      builder: (_) => PaymentDialog(totalAmount: cart.total),
    );
    
    if (paymentMethod == null) return;
    
    try {
      _showLoading();
      
      // Create order
      final order = await _orderService.createOrder(
        branchId: getCurrentBranchId(),
        cart: cart,
      );
      
      // Process payment
      PaymentResult? paymentResult;
      
      if (paymentMethod.isCash) {
        paymentResult = await _paymentService.processCashPayment(
          orderId: order.id,
          branchId: getCurrentBranchId(),
          total: order.pricing.total,
          tendered: paymentMethod.tenderedAmount!,
        );
      } else if (paymentMethod.isPhayPay) {
        // Show PhayPay QR dialog
        _hideLoading();
        final completed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PhayPayQRDialog(
            orderId: order.id,
            amount: order.pricing.total,
            bankMethod: paymentMethod.bankMethod!,
          ),
        );
        
        if (completed == true) {
          paymentResult = PaymentResult(
            status: 'completed',
            orderId: order.id,
          );
        }
      }
      
      _hideLoading();
      
      if (paymentResult?.status == 'completed') {
        // Show success
        await _showSuccessDialog(order, paymentResult!);
        
        // Print receipt (if printer available)
        await _printReceipt(order, paymentResult);
        
        // Clear cart
        setState(() {
          cart = Cart();
        });
      }
      
    } catch (e) {
      _hideLoading();
      _showError(e.toString());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AppZap POS'),
        actions: [
          IconButton(
            icon: Icon(Icons.inventory),
            onPressed: () => Navigator.pushNamed(context, '/inventory'),
          ),
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () => Navigator.pushNamed(context, '/customers'),
          ),
          IconButton(
            icon: Icon(Icons.assessment),
            onPressed: () => Navigator.pushNamed(context, '/reports'),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left: Products
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      CategoryBar(
                        categories: categories,
                        selectedId: selectedCategoryId,
                        onSelected: (id) {
                          setState(() => selectedCategoryId = id);
                          _loadData();
                        },
                      ),
                      SearchBar(
                        onSearch: (query) {
                          // Search products
                        },
                        onScan: (barcode) {
                          // Add by barcode
                          _addByBarcode(barcode);
                        },
                      ),
                      Expanded(
                        child: ProductGrid(
                          products: products,
                          onProductTap: _addToCart,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right: Cart
                Expanded(
                  flex: 1,
                  child: CartPanel(
                    cart: cart,
                    onUpdateQuantity: (productId, quantity) {
                      setState(() {
                        cart.updateQuantity(productId, quantity);
                      });
                    },
                    onRemoveItem: (productId) {
                      setState(() {
                        cart.removeItem(productId);
                      });
                    },
                    onCheckout: _checkout,
                  ),
                ),
              ],
            ),
    );
  }
}
```

---

## 12. Offline Mode Strategy

### 12.1 Local Database (Drift/Hive)

```dart
// Use Drift for local SQLite database
import 'package:drift/drift.dart';

@DriftDatabase(tables: [Products, Orders, Customers])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
  
  // Sync from server
  Future<void> syncFromServer() async {
    try {
      final products = await productService.getProducts();
      await batch((batch) {
        batch.insertAll(
          this.products,
          products.map((p) => p.toCompanion()),
          mode: InsertMode.insertOrReplace,
        );
      });
    } catch (e) {
      print('Sync failed: $e');
    }
  }
  
  // Sync to server (pending orders)
  Future<void> syncToServer() async {
    final pendingOrders = await (select(orders)
      ..where((o) => o.syncStatus.equals('pending')))
      .get();
    
    for (final order in pendingOrders) {
      try {
        await orderService.createOrder(order);
        await (update(orders)
          ..where((o) => o.id.equals(order.id)))
          .write(OrdersCompanion(
            syncStatus: Value('synced'),
          ));
      } catch (e) {
        print('Order sync failed: $e');
      }
    }
  }
}
```

### 12.2 Sync Strategy

```dart
class SyncService {
  final LocalDatabase _db;
  final Connectivity _connectivity;
  
  Timer? _syncTimer;
  
  void startAutoSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
      if (_connectivity.hasConnection) {
        syncAll();
      }
    });
  }
  
  Future<void> syncAll() async {
    try {
      // 1. Sync TO server (pending orders, payments)
      await _syncPendingOrders();
      await _syncPendingPayments();
      
      // 2. Sync FROM server (products, customers)
      await _syncProducts();
      await _syncCustomers();
      
      print('Sync completed');
    } catch (e) {
      print('Sync error: $e');
    }
  }
}
```

---

## 13. Quick Start Checklist

### For Flutter Developers:

**Phase 1 - Week 1: Setup**
- [ ] Set up Flutter project structure
- [ ] Configure Dio for API calls
- [ ] Implement authentication (login, PIN)
- [ ] Set up secure storage for tokens
- [ ] Test API connectivity

**Phase 1 - Week 2-3: Core POS**
- [ ] Implement product listing
- [ ] Build cart functionality
- [ ] Create checkout flow
- [ ] Implement cash payment
- [ ] Test order creation

**Phase 1 - Week 4: PhayPay (USP #1)**
- [ ] Integrate PhayPay payment
- [ ] Display QR codes
- [ ] Poll payment status
- [ ] Handle success/failure
- [ ] Test all 4 banks

**Phase 1 - Week 5-6: Inventory & Customers**
- [ ] Build inventory management UI
- [ ] Implement stock adjustments
- [ ] Create customer management
- [ ] Implement loyalty points
- [ ] Test inventory sync

**Phase 1 - Week 7: Reports & Polish**
- [ ] Implement daily reports
- [ ] Add report exports
- [ ] Create settings screen
- [ ] Add receipt printing
- [ ] UI/UX polish

**Phase 1 - Week 8: Offline Mode**
- [ ] Set up local database
- [ ] Implement offline cart
- [ ] Build sync engine
- [ ] Test offline scenarios
- [ ] Handle sync conflicts

---

## 14. Support & Resources

**API Base URLs:**
- Production: `https://api.appzap.la/api/v1`
- Staging: `https://staging-api.appzap.la/api/v1`

**WebSocket:**
- Production: `wss://ws.appzap.la`
- Staging: `wss://staging-ws.appzap.la`

**Support Contacts:**
- Technical Support: tech@appzap.la
- API Issues: api-support@appzap.la

**Additional Documentation:**
- Swagger UI: https://api.appzap.la/docs
- Postman Collection: [Available on request]

---

## Appendix: Complete Flutter Example

### A. Complete Service Implementation

```dart
// services/product_service.dart
class ProductService {
  final ApiClient _api;
  final LocalDatabase _db;
  final String _branchId;
  
  ProductService(this._api, this._db, this._branchId);
  
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    bool activeOnly = true,
  }) async {
    try {
      // Try online first
      final response = await _api.get('/menu/items', queryParameters: {
        'branchId': _branchId,
        'isActive': activeOnly,
        'limit': 500,
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null) 'search': search,
      });
      
      if (response['success']) {
        final products = (response['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
        
        // Cache to local DB
        await _db.cacheProducts(products);
        
        return products;
      }
      
      throw ApiException(message: 'Failed to load products');
      
    } catch (e) {
      // Fallback to local DB if offline
      if (e is DioError && e.type == DioErrorType.connectionError) {
        return await _db.getProducts(
          categoryId: categoryId,
          search: search,
        );
      }
      rethrow;
    }
  }
  
  Future<Product?> findByBarcode(String barcode) async {
    final products = await getProducts(search: barcode);
    return products.firstWhereOrNull((p) => p.barcode == barcode);
  }
}

// services/order_service.dart
class OrderService {
  final ApiClient _api;
  final LocalDatabase _db;
  final Connectivity _connectivity;
  
  OrderService(this._api, this._db, this._connectivity);
  
  Future<Order> createOrder({
    required String branchId,
    required Cart cart,
  }) async {
    final orderData = {
      'branchId': branchId,
      'orderType': 'takeaway',
      if (cart.customerId != null)
        'customer': {
          'customerId': cart.customerId,
          'name': cart.customerName,
          'phone': cart.customerPhone,
        },
      'items': cart.items.map((item) => {
        'menuItemId': item.productId,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        if (item.notes != null) 'notes': item.notes,
      }).toList(),
      if (cart.discounts.isNotEmpty)
        'discounts': cart.discounts.map((d) => {
          'type': d.type,
          'value': d.value,
          'reason': d.reason,
        }).toList(),
    };
    
    if (await _connectivity.hasConnection) {
      // Online: Create order on server
      final response = await _api.post('/orders/takeaway', data: orderData);
      
      if (response['success']) {
        final order = Order.fromJson(response['data']);
        await _db.saveOrder(order, syncStatus: 'synced');
        return order;
      }
      
      throw ApiException(message: 'Failed to create order');
      
    } else {
      // Offline: Save to local DB
      final localOrder = Order.createLocal(
        branchId: branchId,
        cart: cart,
      );
      await _db.saveOrder(localOrder, syncStatus: 'pending');
      return localOrder;
    }
  }
}

// services/payment_service.dart
class PaymentService {
  final ApiClient _api;
  
  PaymentService(this._api);
  
  Future<PaymentResult> processCashPayment({
    required String orderId,
    required String branchId,
    required double total,
    required double tendered,
  }) async {
    final change = tendered - total;
    
    final response = await _api.post(
      '/checkout/process-payment',
      data: {
        'orderId': orderId,
        'branchId': branchId,
        'paymentMethod': 'cash',
        'amount': {
          'total': total,
          'tendered': tendered,
          'change': change,
          'currency': 'LAK',
        },
      },
    );
    
    if (response['success']) {
      return PaymentResult.fromJson(response['data']);
    }
    
    throw ApiException(message: 'Payment failed');
  }
  
  Future<PhayPayPayment> createPhayPayPayment({
    required String orderId,
    required String branchId,
    required double amount,
    required String bankMethod,
  }) async {
    final response = await _api.post(
      '/payments/phajay/create',
      data: {
        'orderId': orderId,
        'branchId': branchId,
        'amount': amount,
        'currency': 'LAK',
        'bankMethod': bankMethod,
        'description': 'Order #$orderId',
      },
    );
    
    if (response['success']) {
      return PhayPayPayment.fromJson(response['data']);
    }
    
    throw ApiException(message: 'Failed to create PhayPay payment');
  }
  
  Stream<PhayPayStatus> watchPhayPayPayment(String paymentId) async* {
    final maxDuration = Duration(minutes: 10);
    final pollInterval = Duration(seconds: 3);
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < maxDuration) {
      final status = await checkPhayPayStatus(paymentId);
      yield status;
      
      if (status.isCompleted || status.isFailed || status.isExpired) {
        break;
      }
      
      await Future.delayed(pollInterval);
    }
  }
  
  Future<PhayPayStatus> checkPhayPayStatus(String paymentId) async {
    final response = await _api.get('/payments/phajay/status/$paymentId');
    
    if (response['success']) {
      return PhayPayStatus.fromJson(response['data']);
    }
    
    throw ApiException(message: 'Failed to check payment status');
  }
}
```

---

**END OF DOCUMENTATION**

This comprehensive API documentation covers all Phase 1 features needed to build a Universal POS that beats Loyverse. The Flutter team has everything they need to get started immediately.

**Questions?** Contact: tech@appzap.la

