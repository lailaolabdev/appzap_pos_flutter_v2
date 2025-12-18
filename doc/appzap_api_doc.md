# AppZap Universal POS - Complete API Documentation
**Version:** 1.0 (Phase 1 - Basic POS)  
**Target:** Flutter Mobile POS Application  
**Date:** January 15, 2025  
**Status:** ✅ Production Ready  
**Industries:** Mini Marts, Cafes, Shops, Retail Stores, Takeaway Restaurants

---

## 📋 Table of Contents

1. [Overview & Getting Started](#1-overview--getting-started)
2. [Authentication](#2-authentication)
3. [Product Management](#3-product-management)
4. [Sales & Checkout](#4-sales--checkout)
5. [Payment Processing](#5-payment-processing-usp)
   - 5.1 [Calculate Pricing](#51-calculate-pricing-before-payment)
   - 5.2 [Process Cash Payment](#52-process-cash-payment)
   - 5.3 [PhayPay Payment](#53-phaypay-payment--killer-feature)
   - 5.4 [Transaction Management](#54-transaction-management-)
6. [Inventory Management](#6-inventory-management-usp)
7. [Customer & Loyalty](#7-customer--loyalty-usp)
8. [Reports](#8-reports)
9. [WebSocket Real-time](#9-websocket-real-time)
10. [Error Handling](#10-error-handling)
11. [Flutter Implementation Guide](#11-flutter-implementation-guide)
12. [Testing & Troubleshooting](#12-testing--troubleshooting)

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

1. **PhayPay Built-in Payment** - Native integration with Laos banking (JDB, BCEL, LDB, Indochina Bank)
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

### 2.1 Authentication Flow Overview

> **🌟 WORLD STANDARD:** Self-service onboarding like WhatsApp, Grab, Banking apps

```
┌────────────────────────────────────────────────────────────┐
│         NEW USER (SELF-REGISTRATION) - SUPER SIMPLE!       │
└────────────────────────────────────────────────────────────┘
1. Download app
2. Enter phone → Receive OTP
3. Enter OTP → Phone verified ✅
4. Enter:
   - Your name
   - Restaurant name
5. ✅ ACCOUNT CREATED & LOGGED IN!

⏱️  Total Time: ~60 seconds  |  Required Fields: Only 3!

┌────────────────────────────────────────────────────────────┐
│            EXISTING USER (LOGIN) - INSTANT!                 │
└────────────────────────────────────────────────────────────┘
1. Enter phone → Receive OTP
2. Enter OTP → ✅ LOGGED IN IMMEDIATELY!

⏱️  Total Time: ~30 seconds  |  Steps: 2

┌────────────────────────────────────────────────────────────┐
│              FAST LOGIN (OPTIONAL) - LIGHTNING!             │
└────────────────────────────────────────────────────────────┘
Option: Phone + 4-digit PIN (⚡ 2 seconds)
  └─→ Setup after first login for faster daily access
```

**Key Benefits:**
- ✅ **No admin needed** - Anyone can create account
- ✅ **Super simple** - Only 3 required fields (name, phone, restaurant name)
- ✅ **Industry standard** - Matches WhatsApp, Grab, Telegram, Banking apps
- ✅ **Instant access** - Create account & start selling in 60 seconds
- ✅ **Optional PIN** - Convenience feature for faster daily logins

---

### 📋 Important: Response Format Standards

> **For Flutter Team:** All authentication responses follow these formats consistently:

**Code Formats:**
```
Restaurant Code:  5 characters      e.g., "JC001", "MS123", "AB789"
User ID:          {code}-OWN/001    e.g., "JC001-OWN", "MS001-001"
Branch Code:      {code}B1          e.g., "JC1B1", "MS1B1"
```

**User Roles:**
```
restaurant_admin  → Full restaurant access (owner/admin)
branch_admin      → Branch-level admin
manager           → Manager permissions
cashier           → POS operations
waiter            → Service operations
chef              → Kitchen operations
custom            → Custom role with specific permissions
```

**Key Response Fields:**
- `user.role` → Always one of the valid roles above (NOT "owner")
- `user.userId` → Format depends on role: "{code}-OWN" for admins, "{code}-001" for staff
- `restaurant.code` → Always 5 characters max
- `branch.branchCode` → Format: "{restaurantCode}B{number}"
- `subscription` → Present for new registrations (trial info)

---

### 2.2 Send OTP (Works for ANY Phone Number) 🌍

Send OTP to **any valid phone number** - registered or not!

```http
POST /auth/phone/send-otp
Content-Type: application/json

{
  "phone": "020 12345678",
  "purpose": "login"
}
```

**Phone Number Format:** The API accepts any format and auto-normalizes:
- `020 12345678` → `+85620123456789`
- `20 1234 5678` → `+85620123456789`
- `+856 20 12345678` → `+85620123456789`

**Purpose Options:**
- `login` - Login/Registration (default)
- `forgot_pin` - Reset PIN

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP sent to +85620123456789",
  "expiresIn": 300
}
```

**✨ Key Points:**
- ✅ Works for **both new and existing users**
- ✅ No need to check if user exists first
- ✅ New users will register after OTP verification
- ✅ Existing users will login after OTP verification

**Error Response (Rate Limited):**
```json
{
  "success": false,
  "message": "Too many OTP requests. Please try again in 8 minutes.",
  "code": "RATE_LIMIT_EXCEEDED"
}
```

**Rate Limits:**
- Max 3 OTP requests per 10 minutes per phone
- OTP expires in 5 minutes
- Max 3 verification attempts per OTP

---

### 2.3 Verify OTP (Smart Response) 🎯

Verify OTP and get appropriate response based on user status.

```http
POST /auth/phone/verify-otp
Content-Type: application/json

{
  "phone": "020 12345678",
  "otp": "123456"
}
```

---

#### **Scenario 1: Existing User (Login) ✅**

**Response (200 OK) - COMPLETE AUTHENTICATION:**
```json
{
  "success": true,
  "verified": true,
  "isRegistered": true,
  "user": {
    "_id": "60d5ec954b24c72d88c4e123",
    "name": "John Doe",
    "phone": "+85620123456789",
    "userId": "MS001-OWN",
    "role": "restaurant_admin",
    "restaurantId": {
      "_id": "60d5ec854b24c72d88c4e120",
      "name": "My Store",
      "code": "MS001",
      "settings": {
        "currency": {
          "mainCurrency": "LAK"
        }
      }
    },
    "branchId": {
      "_id": "60d5ec954b24c72d88c4e121",
      "name": "Main Branch",
      "branchCode": "MS1B1"
    },
    "permissions": [...]
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
  },
  "hasPIN": false,
  "message": "Login successful"
}
```

**🎉 User is LOGGED IN immediately!**

---

#### **Scenario 2: New User (Registration Required) 📝**

**Response (200 OK) - REGISTRATION REQUIRED:**
```json
{
  "success": true,
  "verified": true,
  "isRegistered": false,
  "registrationRequired": true,
  "registrationToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "phone": "+85620123456789",
  "message": "Phone verified successfully. Please complete registration.",
  "expiresIn": 900
}
```

**📝 Next Step:** Use `registrationToken` to complete registration (see Section 2.4)

---

#### **Error Response (Invalid OTP):**

```json
{
  "success": false,
  "verified": false,
  "message": "Invalid OTP. 2 attempts remaining.",
  "code": "INVALID_OTP",
  "remainingAttempts": 2
}
```

**Key Points:**
- ✅ **Existing users** → Get full tokens, logged in immediately
- ✅ **New users** → Get registrationToken to complete signup
- ✅ **registrationToken** valid for 15 minutes
- ✅ Both flows are seamless and user-friendly

---

### 2.4 Complete Registration (Self-Service) 🌟

Complete registration for new users with just **3 required fields**!

```http
POST /auth/phone/register
Content-Type: application/json

{
  "registrationToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "name": "John Doe",
  "restaurantName": "John's Coffee Shop",
  "pin": "1234"
}
```

**Required Fields:**
- `registrationToken` (from verify-otp response)
- `name` - Your name
- `restaurantName` - Your restaurant/shop name

**Optional Fields:**
- `pin` - 4-digit PIN for faster future logins

**Important Response Details:**
- 🏷️ **Restaurant Code**: 5-character format (e.g., "JC001", "MS123", "AB789")
- 🏷️ **User ID**: `{restaurantCode}-OWN` (e.g., "JC001-OWN")
- 🏷️ **Branch Code**: `{restaurantCode}B1` (e.g., "JC1B1" for first branch)
- 👤 **User Role**: `restaurant_admin` (full restaurant permissions)
- 🎁 **Trial**: 1-year free trial subscription included

**Response (201 Created) - ACCOUNT CREATED & LOGGED IN:**
```json
{
  "success": true,
  "registered": true,
  "user": {
    "_id": "60d5ec954b24c72d88c4e123",
    "name": "John Doe",
    "phone": "+85620123456789",
    "userId": "JC001-OWN",
    "role": "restaurant_admin",
    "restaurantId": {
      "_id": "60d5ec854b24c72d88c4e120",
      "name": "John's Coffee Shop",
      "code": "JC001",
      "settings": {
        "currency": {
          "mainCurrency": "LAK"
        }
      }
    },
    "branchId": {
      "_id": "60d5ec954b24c72d88c4e121",
      "name": "Main Branch",
      "branchCode": "JC1B1"
    },
    "permissions": [
      "manage_sales",
      "manage_orders",
      "manage_inventory",
      "manage_customers",
      "manage_staff",
      "view_reports",
      "manage_settings"
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
  },
  "restaurant": {
    "_id": "60d5ec854b24c72d88c4e120",
    "name": "John's Coffee Shop",
    "code": "JC001"
  },
  "branch": {
    "_id": "60d5ec954b24c72d88c4e121",
    "name": "Main Branch",
    "branchCode": "JC1B1"
  },
  "subscription": {
    "_id": "60d5ec854b24c72d88c4e122",
    "status": "trial",
    "endDate": "2026-12-17T12:00:00Z"
  },
  "message": "Registration successful! Welcome to AppZap POS - 1 Year Free Trial"
}
```

**🎉 Account Created & User is LOGGED IN!**

**What Gets Created Automatically:**
- ✅ Restaurant account (with 5-char code, e.g., "JC001")
- ✅ Main branch (with branchCode, e.g., "JC1B1")
- ✅ Restaurant admin account (you - full permissions)
- ✅ 1-year free trial subscription
- ✅ Full authentication tokens

**Key Benefits:**
- ✅ **Super simple** - Only 3 required fields!
- ✅ **Instant setup** - Everything created automatically
- ✅ **Restaurant admin role** - Full access to all features
- ✅ **Free trial** - 1 year trial period included
- ✅ **Ready to use** - Start selling immediately

**Response Fields Explained:**

| Field | Format | Example | Description |
|-------|--------|---------|-------------|
| `restaurant.code` | 5 chars | "JC001" | Unique restaurant identifier |
| `user.userId` | `{code}-OWN` | "JC001-OWN" | Unique user login ID |
| `user.role` | String | "restaurant_admin" | Full restaurant permissions |
| `branch.branchCode` | `{code}B1` | "JC1B1" | Branch identifier |
| `subscription.status` | String | "trial" | Free trial status |
| `subscription.endDate` | ISO Date | "2026-12-17T..." | Trial expires in 1 year |

**Error Responses:**

```json
// Invalid token
{
  "success": false,
  "message": "Invalid or expired registration token",
  "code": "UNAUTHORIZED"
}

// Phone already registered
{
  "success": false,
  "message": "User with this phone number already exists",
  "code": "CONFLICT"
}

// Missing required fields
{
  "success": false,
  "message": "Name and restaurant name are required",
  "code": "VALIDATION_ERROR"
}
```

---

### 2.5 Login with Phone + PIN 🚀 (Optional - Fast Daily Login)

Fast login for daily POS usage - just phone number + 4-digit PIN.

```http
POST /auth/phone/login
Content-Type: application/json

{
  "phone": "020 12345678",
  "pin": "1234"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "user": {
    "_id": "60d5ec954b24c72d88c4e123",
    "name": "John Doe",
    "phone": "+85620123456789",
    "userId": "MS001-001",
    "role": "cashier",
    "restaurantId": {
      "_id": "60d5ec854b24c72d88c4e120",
      "name": "My Store",
      "code": "MS001",
      "settings": {
        "currency": {
          "mainCurrency": "LAK"
        }
      }
    },
    "branchId": {
      "_id": "60d5ec954b24c72d88c4e121",
      "name": "Main Branch",
      "branchCode": "MS1B1"
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
- 💪 **No Expiry:** PIN never expires (unlike passwords)

---

### 2.6 Setup/Change PIN (Authenticated)

Setup or change PIN while logged in.

```http
POST /auth/phone/setup-pin
Authorization: Bearer {token}
Content-Type: application/json

{
  "pin": "1234",
  "oldPin": "5678"
}
```

**Notes:**
- `oldPin` is required if PIN already exists
- PIN must be exactly 4 digits
- First-time setup doesn't require `oldPin`

**Response:**
```json
{
  "success": true,
  "message": "PIN setup successfully"
}
```

---

### 2.7 Forgot PIN

Reset PIN using OTP verification.

**Step 1: Request OTP**
```http
POST /auth/phone/forgot-pin
Content-Type: application/json

{
  "phone": "020 12345678"
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
  "newPin": "5678"
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

### 2.8 Refresh Tokens

Get new access token using refresh token.

```http
POST /auth/refresh-tokens
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### 2.9 Legacy Authentication (Web POS)

For backward compatibility, these endpoints are still available:

```http
POST /auth/login              # Email + Password
POST /auth/login-with-userid  # UserId + Password
POST /auth/quick-login        # UserId + Passcode
```

**Note:** Mobile apps should use Phone + PIN authentication for better UX.

---

## 3. Product Management

### 3.1 Get Products/Menu Items

```http
GET /menu-items
Authorization: Bearer {token}

Query Parameters:
  restaurantId (required) - Restaurant ID
  branchId (optional) - Filter by branch ID
  isActive (optional) - Filter active items (default: true)
  categoryId (optional) - Filter by category
  search (optional) - Search by name, SKU, or barcode
  limit (optional) - Results per page (default: 100, max: 500)
  page (optional) - Page number (default: 1)
```

**Example Request:**
```http
GET /menu-items?restaurantId=60d5ec954b24c72d88c4e120&branchId=60d5ec954b24c72d88c4e121&isActive=true&limit=500
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
GET /menu-items/:itemId
Authorization: Bearer {token}
```

### 3.3 Get Categories

```http
GET /menu-categories
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
GET /menu-items?restaurantId={restaurantId}&branchId={branchId}&search={barcode}
Authorization: Bearer {token}
```

**Barcode Scanner Integration:**
```dart
// Flutter: Use barcode scanner package
final barcode = await BarcodeScanner.scan();
final product = await productService.findByBarcode(
  restaurantId: currentUser.restaurantId,
  branchId: currentBranch.id,
  barcode: barcode
);
```

---

### 3.5 Create Menu Item (Product)

```http
POST /menu-items
Authorization: Bearer {token}
Content-Type: application/json

{
  "restaurantId": "60d5ec954b24c72d88c4e120",
  "branchId": "60d5ec954b24c72d88c4e121",
  "categoryId": "60d5eca74b24c72d88c4e124",
  "name": "Iced Latte",
  "description": "Cold espresso with milk",
  "itemCode": "LATTE001",
  "barcode": "8851234567890",
  "sku": "ICE-LATTE-16OZ",
  "itemLevel": "restaurant",
  
  "pricing": {
    "basePrice": 25000,
    "costPrice": 15000,
    "taxRate": 10,
    "taxIncluded": false,
    "currency": "LAK"
  },
  
  "inventory": {
    "trackStock": true,
    "lowStockThreshold": 10,
    "unit": "unit"
  },
  
  "isActive": true,
  "displayOrder": 1
}
```

**Item Levels:**
- `restaurant` - Available across all branches (default)
- `branch` - Specific to one branch only (requires branchId)
- `override` - Branch-specific override of restaurant item

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Menu item created successfully with inventory tracking (auto_create) - Strategy: create_for_all_branches",
  "data": {
    "menuItem": {
      "_id": "60d5ecb94b24c72d88c4e127",
      "name": "Iced Latte",
      "itemCode": "LATTE001",
      "restaurantId": "60d5ec954b24c72d88c4e120",
      "branchId": null,
      "categoryId": {
        "_id": "60d5eca74b24c72d88c4e124",
        "name": "Beverages",
        "discount": {...}
      },
      "recipeId": {
        "_id": "60d5ecb14b24c72d88c4e125",
        "name": "Latte Recipe",
        "ingredients": [...]
      },
      "pricing": {
        "basePrice": 25000,
        "costPrice": 15000,
        "taxRate": 10,
        "currency": "LAK"
      },
      "inventory": {
        "trackInventory": true,
        "preparationMethod": "auto_create",
        "stockLevel": 0,
        "reorderPoint": 10,
        "reorderQuantity": 50
      },
      "images": [],
      "customizations": [],
      "itemLevel": "restaurant",
      "isActive": true,
      "createdBy": {
        "_id": "60d5ec954b24c72d88c4e121",
        "name": "John Admin"
      },
      "updatedBy": null,
      "createdAt": "2025-01-15T10:00:00.000Z",
      "updatedAt": "2025-01-15T10:00:00.000Z"
    },
    "inventoryActivation": {
      "strategy": "create_for_all_branches",
      "inventoryItemsCreated": 2,
      "pendingBranchesCount": 0,
      "pendingBranches": []
    }
  }
}
```

**⚠️ Important Notes:**
- The menu item is nested under `data.menuItem`, not directly in `data`
- `categoryId`, `recipeId`, `createdBy`, `updatedBy` are **populated objects**, not string IDs
- `inventoryActivation` provides details about inventory creation across branches
- If your model expects string IDs, extract them from the populated objects (e.g., `categoryId._id`)

**Flutter Parsing Example:**
```dart
final response = await dio.post('/api/v1/menu-items', data: {...});

// Access nested menuItem
final menuItemData = response.data['data']['menuItem'];

// Extract inventory activation info (optional)
final inventoryInfo = response.data['data']['inventoryActivation'];

// Normalize populated fields to IDs if needed
if (menuItemData['categoryId'] is Map) {
  menuItemData['categoryId'] = menuItemData['categoryId']['_id'];
}
if (menuItemData['recipeId'] is Map) {
  menuItemData['recipeId'] = menuItemData['recipeId']['_id'];
}
if (menuItemData['createdBy'] is Map) {
  menuItemData['createdBy'] = menuItemData['createdBy']['_id'];
}

final menuItem = MenuItem.fromJson(menuItemData);
```

---

### 3.6 Update Menu Item

```http
PATCH /menu-items/:itemId
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Iced Latte (Large)",
  "pricing": {
    "basePrice": 28000
  },
  "isActive": true
}
```

**Note:** Send only the fields you want to update.

**Response (200 OK):**
```json
{
  "_id": "60d5ecb94b24c72d88c4e127",
  "restaurantId": "60d5ec954b24c72d88c4e120",
  "name": "Iced Latte (Large)",
  "itemCode": "LATTE001",
  "categoryId": "60d5eca74b24c72d88c4e124",
  "pricing": {
    "basePrice": 28000,
    "costPrice": 15000,
    "taxRate": 10
  },
  "inventory": {...},
  "isActive": true,
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T11:00:00Z"
}
```

**⚠️ Important:** Response is the **direct menu item object**, not wrapped in `{ success, data }` format!

---

### 3.7 Delete Menu Item

```http
DELETE /menu-items/:itemId
Authorization: Bearer {token}
```

**Response (204 No Content):**
```
No content returned
```

**Note:** Hard delete - item is permanently removed from database.

---

### 3.8 Bulk Create Menu Items

```http
POST /menu-items/bulk
Authorization: Bearer {token}
Content-Type: application/json

{
  "restaurantId": "60d5ec954b24c72d88c4e120",
  "items": [
    {
      "name": "Espresso",
      "categoryId": "60d5eca74b24c72d88c4e124",
      "pricing": { "basePrice": 15000 },
      "itemCode": "ESP001"
    },
    {
      "name": "Cappuccino",
      "categoryId": "60d5eca74b24c72d88c4e124",
      "pricing": { "basePrice": 20000 },
      "itemCode": "CAP001"
    }
  ]
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "2 menu items created successfully",
  "data": {
    "created": 2,
    "items": [
      { "_id": "...", "name": "Espresso" },
      { "_id": "...", "name": "Cappuccino" }
    ]
  }
}
```

---

### 3.9 Upload Menu Item Image

```http
POST /menu-items/:itemId/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "image": <file>
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Image uploaded successfully",
  "data": {
    "imageId": "img_123",
    "url": "https://cdn.appzap.la/images/menu/latte-001.jpg",
    "thumbnailUrl": "https://cdn.appzap.la/images/menu/thumbs/latte-001.jpg"
  }
}
```

---

## 3.10 Menu Category Management

### 3.10.1 Create Menu Category

```http
POST /menu-categories
Authorization: Bearer {token}
Content-Type: application/json

{
  "restaurantId": "60d5ec954b24c72d88c4e120",
  "name": "Hot Beverages",
  "description": "Hot coffee, tea, and chocolate drinks",
  "displayOrder": 1,
  "isActive": true,
  "color": "#FF5733"
}
```

**Response (201 Created):**
```json
{
  "_id": "60d5eca74b24c72d88c4e124",
  "restaurantId": "60d5ec954b24c72d88c4e120",
  "name": "Hot Beverages",
  "description": "Hot coffee, tea, and chocolate drinks",
  "displayOrder": 1,
  "isActive": true,
  "itemLevel": "restaurant",
  "color": "#FF5733",
  "parentCategoryId": null,
  "overrideParentId": null,
  "createdBy": {
    "_id": "...",
    "name": "Staff Name"
  },
  "updatedBy": null,
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

**⚠️ Important:** Response is the **direct category object**, not wrapped in `{ success, data }` format!

---

### 3.10.2 Update Menu Category

```http
PATCH /menu-categories/:categoryId
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Hot Drinks",
  "description": "All hot beverages",
  "displayOrder": 2
}
```

**Response (200 OK):**
```json
{
  "_id": "60d5eca74b24c72d88c4e124",
  "restaurantId": "60d5ec954b24c72d88c4e120",
  "name": "Hot Drinks",
  "description": "All hot beverages",
  "displayOrder": 2,
  "isActive": true,
  "itemLevel": "restaurant",
  "parentCategoryId": null,
  "overrideParentId": null,
  "createdBy": {...},
  "updatedBy": {...},
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T11:00:00Z"
}
```

**⚠️ Important:** Response is the **direct category object**, not wrapped in `{ success, data }` format!

---

### 3.10.3 Delete Menu Category

```http
DELETE /menu-categories/:categoryId
Authorization: Bearer {token}
```

**Response (204 No Content):**
```
No content returned
```

**Note:** Cannot delete category if it contains active menu items.

---

### 3.10.4 Get Single Category

```http
GET /menu-categories/:categoryId
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "_id": "60d5eca74b24c72d88c4e124",
  "restaurantId": "60d5ec954b24c72d88c4e120",
  "name": "Beverages",
  "description": "All drinks",
  "displayOrder": 1,
  "isActive": true,
  "itemLevel": "restaurant",
  "parentCategoryId": null,
  "overrideParentId": null,
  "createdBy": {...},
  "updatedBy": {...},
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

**⚠️ Important:** Response is the **direct category object**, not wrapped in `{ success, data }` format!

---

## 4. Sales & Checkout

### 4.1 Create Sale/Order (Takeaway/Quick Sale)

```http
POST /orders/takeaway-order/
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

### 4.2 Get Orders (List/Filter)

```http
GET /orders/
Authorization: Bearer {token}

Query Parameters:
  branchId (optional) - Filter by branch
  orderType (optional) - Filter by type (table, takeaway, delivery), supports comma-separated values
  orderStatus (optional) - Filter by status, supports comma-separated values
  startDate (optional) - Filter from date (ISO 8601)
  endDate (optional) - Filter to date (ISO 8601)
  page (optional) - Page number (default: 1)
  limit (optional) - Results per page (default: 20)
  includeStatistics (optional) - Include order counts by status (default: true)
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "_id": "676...",
        "orderCode": "ORD-20251218-001",
        "restaurantId": "676...",
        "branchId": "676...",
        "orderType": "table",
        "orderStatus": "pending",
        "lineItems": [
          {
            "menuItemId": "676...",
            "name": "Iced Latte",
            "quantity": 2,
            "unitPrice": 25000,
            "subtotal": 50000,
            "notes": ""
          }
        ],
        "pricing": {
          "subtotal": 50000,
          "tax": 5000,
          "discountTotal": 0,
          "total": 55000,
          "currency": "LAK"
        },
        "customer": {
          "customerId": "676...",
          "name": "John Doe",
          "phone": "+85620..."
        },
        "tableSession": {
          "sessionId": "676...",
          "tableNumber": "A-101"
        },
        "paymentStatus": "pending",
        "createdAt": "2025-12-18T05:00:00Z",
        "updatedAt": "2025-12-18T05:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "totalCount": 45,
      "totalPages": 3,
      "hasNext": true,
      "hasPrev": false
    },
    "statistics": {
      "total": 45,
      "byStatus": {
        "pending": 12,
        "confirmed": 8,
        "preparing": 10,
        "ready": 5,
        "out_for_delivery": 0,
        "served": 3,
        "completed": 7,
        "cancelled": 0
      }
    },
    "message": "Retrieved 20 orders successfully"
  },
  "timestamp": "2025-12-18T05:16:48.000Z"
}
```

**⚠️ Important Notes:**
- Orders are nested under `data.orders`, not directly in `data`
- Response includes `pagination` for navigating results
- Response includes `statistics` with order counts by status (unless `includeStatistics=false`)
- Use `orderType` and `orderStatus` with comma-separated values for multiple filters (e.g., `orderStatus=pending,confirmed`)

**Flutter Parsing Example:**
```dart
final response = await dio.get('/api/v1/orders/', queryParameters: {...});

// Access nested structure
final data = response.data['data'];
final orders = (data['orders'] as List)
    .map((json) => Order.fromJson(json))
    .toList();
final pagination = data['pagination'];
final statistics = data['statistics']; // optional

print('Loaded ${orders.length} of ${pagination['totalCount']} orders');
print('Pending: ${statistics['byStatus']['pending']}');
```

**Example Queries:**
```http
# Get all orders
GET /orders/

# Get pending orders only
GET /orders/?orderStatus=pending

# Get table and takeaway orders
GET /orders/?orderType=table,takeaway

# Get multiple statuses
GET /orders/?orderStatus=pending,confirmed,preparing

# Get orders for today
GET /orders/?startDate=2025-12-18T00:00:00Z&endDate=2025-12-18T23:59:59Z

# Pagination
GET /orders/?page=2&limit=50

# Without statistics (faster)
GET /orders/?includeStatistics=false
```

**Note:** To get a specific order, use `GET /orders/?orderId={orderId}` or filter the results.

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

---

### 5.3 PhayPay Payment (🎯 KILLER FEATURE!)

> **Native Laos Bank Integration:** QR payments for JDB, BCEL, LDB, and Indochina Bank

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
- `bank_qr_jdb` - Joint Development Bank (JDB)
- `bank_qr_bcel` - BCEL (Banque pour le Commerce Exterieur Lao)
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
    "expiresInSeconds": 600,
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
    "bankReference": "JDB20250115103630",
    "orderId": "ORD-20250115-00045"
  }
}
```

**Payment Statuses:**
- `pending` - Waiting for payment
- `completed` - Payment successful ✅
- `failed` - Payment failed ❌
- `expired` - QR code expired (10 minutes)

#### 5.3.3 Flutter PhayPay Implementation Example

```dart
class PhayPayService {
  final Dio dio;
  
  Future<PhayPayPayment> createPayment({
    required String orderId,
    required String branchId,
    required double amount,
    required String bankMethod,
  }) async {
    final response = await dio.post(
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
    
    return PhayPayPayment.fromJson(response.data['data']);
  }
  
  // Poll payment status every 3 seconds
  Stream<PhayPayStatus> watchPayment(String paymentId) async* {
    final maxDuration = Duration(minutes: 10);
    final pollInterval = Duration(seconds: 3);
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < maxDuration) {
      final status = await checkPaymentStatus(paymentId);
      yield status;
      
      if (status.isCompleted || status.isFailed || status.isExpired) {
        break;
      }
      
      await Future.delayed(pollInterval);
    }
  }
  
  Future<PhayPayStatus> checkPaymentStatus(String paymentId) async {
    final response = await dio.get('/payments/phajay/status/$paymentId');
    return PhayPayStatus.fromJson(response.data['data']);
  }
}

// Usage in UI
void _showPhayPayDialog(Order order) async {
  // Create payment
  final payment = await phayPayService.createPayment(
    orderId: order.id,
    branchId: currentBranchId,
    amount: order.total,
    bankMethod: 'bank_qr_jdb',
  );
  
  // Show QR code dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PhayPayQRDialog(
      qrCode: payment.qrCode,
      amount: payment.amount,
      expiresAt: payment.expiresAt,
    ),
  );
  
  // Watch payment status
  phayPayService.watchPayment(payment.paymentId).listen((status) {
    if (status.isCompleted) {
      Navigator.pop(context); // Close QR dialog
      _showSuccessDialog(order);
    } else if (status.isFailed || status.isExpired) {
      Navigator.pop(context);
      _showErrorDialog(status.message);
    }
  });
}
```

---

### 5.4 Transaction Management 📊

> **View and manage all payment transactions with advanced filtering and reporting**

Transaction endpoints allow you to view payment history, generate reports, process refunds, and manage transaction records.

#### 5.4.1 Get Transaction History

Get a paginated list of transactions with powerful filtering options.

```http
GET /transactions/
Authorization: Bearer {token}

Query Parameters:
  startDate (optional) - Start date (YYYY-MM-DD or ISO 8601)
  startTime (optional) - Start time (HH:MM)
  endDate (optional) - End date (YYYY-MM-DD or ISO 8601)
  endTime (optional) - End time (HH:MM)
  timezone (optional) - Timezone (e.g., "Asia/Vientiane")
  
  // Alternative date parameters
  dateFrom (optional) - Alias for startDate
  dateTo (optional) - Alias for endDate
  
  // Filters
  branchId (optional) - Filter by branch
  status (optional) - Filter by status (completed, pending, voided, refunded)
  method (optional) - Filter by payment method (cash, card, bank_qr_jdb, etc.)
  staffId (optional) - Filter by staff member
  
  // Pagination
  page (optional) - Page number (default: 1)
  limit (optional) - Results per page (default: 20, max: 100)
  sort (optional) - Sort field (default: "-timing.initiatedAt")
  
  // Options
  includeSummary (optional) - Include payment statistics (default: true)
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "_id": "676...",
        "transactionId": "TXN-20251218-001",
        "transactionType": "sale",
        "transactionStatus": "completed",
        "consolidatedTotals": {
          "grandTotal": {
            "amount": 50000,
            "currency": "LAK"
          }
        },
        "paymentSummary": {
          "totalPaid": 50000,
          "paymentMethodBreakdown": [
            {
              "method": "cash",
              "amount": 50000,
              "currency": "LAK"
            }
          ]
        },
        "timing": {
          "initiatedAt": "2025-12-18T10:00:00Z",
          "completedAt": "2025-12-18T10:01:00Z"
        },
        "staff": {
          "processedBy": {
            "_id": "676...",
            "name": "John Cashier",
            "role": "cashier"
          }
        },
        "tableInfo": {
          "tableNumber": "A-101",
          "zoneName": "Main Floor"
        },
        "countInTotals": true
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "totalCount": 150,
      "totalPages": 8,
      "hasNext": true,
      "hasPrev": false
    },
    "summary": {
      "totalTxnCount": 150,
      "salesCount": 145,
      "voidCount": 5,
      "salesAmount": 7250000,
      "voidAmount": 125000,
      "paymentMethodBreakdown": [
        {
          "method": "cash",
          "count": 80,
          "totalAmount": 4000000
        },
        {
          "method": "bank_qr_jdb",
          "count": 65,
          "totalAmount": 3250000
        }
      ]
    }
  },
  "timestamp": "2025-12-18T12:00:00Z"
}
```

**⚠️ Important Notes:**
- Transactions are nested under `data.transactions`, not directly in `data`
- `summary` includes sales statistics (only included if `includeSummary=true`)
- Voided transactions are excluded from `salesAmount` but included in `voidAmount`
- Supports timezone-aware date filtering

**Flutter Parsing Example:**
```dart
final response = await dio.get('/api/v1/transactions/', queryParameters: {
  'startDate': '2025-12-01',
  'endDate': '2025-12-31',
  'branchId': currentBranchId,
  'includeSummary': true,
  'page': 1,
  'limit': 50,
});

// Access nested structure
final data = response.data['data'];
final transactions = (data['transactions'] as List)
    .map((json) => Transaction.fromJson(json))
    .toList();
final pagination = data['pagination'];
final summary = data['summary'];

// Display summary stats
print('Total sales: ${summary['salesAmount']}');
print('Total transactions: ${summary['totalTxnCount']}');
print('Voided: ${summary['voidCount']}');

// Display payment method breakdown
for (var method in summary['paymentMethodBreakdown']) {
  print('${method['method']}: ${method['totalAmount']}');
}
```

**Example Queries:**

```http
# Get today's transactions
GET /transactions/?startDate=2025-12-18&endDate=2025-12-18&includeSummary=true

# Get cash transactions only
GET /transactions/?method=cash&startDate=2025-12-01

# Get transactions for last 7 days
GET /transactions/?startDate=2025-12-11&endDate=2025-12-18

# Get completed transactions only
GET /transactions/?status=completed

# Get transactions by specific staff
GET /transactions/?staffId=676...

# Paginated results
GET /transactions/?page=2&limit=50

# Without summary (faster)
GET /transactions/?includeSummary=false

# With timezone (e.g., for businesses in Laos)
GET /transactions/?startDate=2025-12-18&timezone=Asia/Vientiane
```

---

#### 5.4.2 Get Transaction Summary

Get aggregate statistics for transactions in a date range.

```http
GET /transactions/summary
Authorization: Bearer {token}

Query Parameters:
  startDate (optional) - Start date (YYYY-MM-DD or ISO 8601)
  endDate (optional) - End date (YYYY-MM-DD or ISO 8601)
  branchId (optional) - Filter by branch
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "totalTransactions": 150,
    "totalRevenue": 7250000,
    "averageTransactionValue": 48333,
    "paymentMethodBreakdown": [
      {
        "method": "cash",
        "count": 80,
        "totalAmount": 4000000,
        "percentage": 55.17
      },
      {
        "method": "bank_qr_jdb",
        "count": 65,
        "totalAmount": 3250000,
        "percentage": 44.83
      }
    ],
    "statusBreakdown": [
      {
        "status": "completed",
        "count": 145
      },
      {
        "status": "voided",
        "count": 5
      }
    ],
    "dailyTransactions": [
      {
        "date": "2025-12-01",
        "count": 45,
        "totalAmount": 2175000
      },
      {
        "date": "2025-12-02",
        "count": 52,
        "totalAmount": 2510000
      }
    ],
    "hourlyTransactions": [
      {
        "hour": 9,
        "count": 12,
        "totalAmount": 580000
      },
      {
        "hour": 12,
        "count": 28,
        "totalAmount": 1350000
      },
      {
        "hour": 18,
        "count": 22,
        "totalAmount": 1060000
      }
    ]
  }
}
```

**Use Cases:**
- Dashboard summary cards
- Payment method pie charts
- Daily sales line charts
- Peak hours heat map

---

#### 5.4.3 Get Single Transaction

Get detailed information about a specific transaction.

```http
GET /transactions/:transactionId
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "_id": "676...",
  "transactionId": "TXN-20251218-001",
  "receiptId": "RCP-20251218-001",
  "transactionType": "sale",
  "transactionStatus": "completed",
  "restaurantId": "676...",
  "branchId": "676...",
  "consolidatedTotals": {
    "subtotal": {
      "amount": 45000,
      "currency": "LAK"
    },
    "tax": {
      "amount": 4500,
      "currency": "LAK"
    },
    "discounts": {
      "amount": 0,
      "currency": "LAK"
    },
    "serviceCharge": {
      "amount": 0,
      "currency": "LAK"
    },
    "grandTotal": {
      "amount": 49500,
      "currency": "LAK"
    }
  },
  "payments": [
    {
      "method": "cash",
      "grossAmount": {
        "amount": 50000,
        "currency": "LAK"
      },
      "changeAmount": {
        "amount": 500,
        "currency": "LAK"
      },
      "processedAt": "2025-12-18T10:01:00Z",
      "processedBy": "676..."
    }
  ],
  "lineItems": [
    {
      "itemType": "menu_item",
      "menuItemId": "676...",
      "name": "Iced Latte",
      "quantity": 2,
      "unitPrice": 22500,
      "subtotal": 45000,
      "tax": 4500,
      "total": 49500
    }
  ],
  "staff": {
    "processedBy": {
      "_id": "676...",
      "name": "John Cashier",
      "role": "cashier"
    }
  },
  "customer": {
    "customerId": "676...",
    "name": "Jane Customer",
    "phone": "+85620..."
  },
  "tableInfo": {
    "tableNumber": "A-101",
    "zoneName": "Main Floor",
    "tableSessionId": "676..."
  },
  "timing": {
    "initiatedAt": "2025-12-18T10:00:00Z",
    "completedAt": "2025-12-18T10:01:00Z"
  },
  "countInTotals": true,
  "createdAt": "2025-12-18T10:00:00Z",
  "updatedAt": "2025-12-18T10:01:00Z"
}
```

**⚠️ Important:** Response is the **direct transaction object**, not wrapped in `{ success, data }` format!

---

#### 5.4.4 Process Refund

Process a full or partial refund for a transaction.

```http
POST /transactions/:transactionId/refund
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Customer dissatisfied with product quality",
  "refundAmount": 49500,
  "refundMethod": "cash",
  "notes": "Full refund issued",
  "managerApproval": {
    "managerId": "676...",
    "approvalCode": "1234"
  }
}
```

**Required Permissions:** `MANAGE_TRANSACTIONS`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "transactionId": "TXN-20251218-001",
    "refundTransactionId": "TXN-20251218-REF-001",
    "refundAmount": 49500,
    "refundMethod": "cash",
    "status": "refunded",
    "refundedAt": "2025-12-18T14:30:00Z",
    "refundedBy": {
      "_id": "676...",
      "name": "Manager John"
    },
    "reason": "Customer dissatisfied with product quality"
  }
}
```

**Refund Rules:**
- ✅ Can refund completed transactions
- ✅ Supports partial refunds
- ✅ Requires manager approval
- ❌ Cannot refund already voided transactions
- ❌ Cannot refund more than original amount

---

#### 5.4.5 Void Transaction

Void (cancel) a transaction. Use this for order mistakes or cancellations.

```http
POST /transactions/:transactionId/void
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Order entered incorrectly",
  "notes": "Wrong table number entered",
  "managerApproval": {
    "managerId": "676...",
    "approvalCode": "1234"
  }
}
```

**Required Permissions:** `MANAGE_TRANSACTIONS`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "transactionId": "TXN-20251218-001",
    "status": "voided",
    "voidedAt": "2025-12-18T10:05:00Z",
    "voidedBy": {
      "_id": "676...",
      "name": "Manager John"
    },
    "reason": "Order entered incorrectly"
  }
}
```

**Void vs Refund:**
- **Void:** Cancel before payment/completion (doesn't count in sales)
- **Refund:** Return money after payment (counts as negative sale)

---

#### 5.4.6 Get Transaction Receipt

Generate a receipt for a transaction.

```http
GET /transactions/:transactionId/receipt
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "receiptId": "RCP-20251218-001",
    "transactionId": "TXN-20251218-001",
    "restaurant": {
      "name": "My Coffee Shop",
      "address": "123 Main St, Vientiane",
      "phone": "020 12345678",
      "taxId": "LAO123456789"
    },
    "branch": {
      "name": "Main Branch",
      "address": "123 Main St"
    },
    "items": [
      {
        "name": "Iced Latte",
        "quantity": 2,
        "unitPrice": 22500,
        "total": 45000
      }
    ],
    "totals": {
      "subtotal": 45000,
      "tax": 4500,
      "total": 49500
    },
    "payment": {
      "method": "cash",
      "tendered": 50000,
      "change": 500
    },
    "staff": "John Cashier",
    "date": "2025-12-18T10:01:00Z",
    "receiptHtml": "<html>...</html>",
    "receiptText": "--- Receipt Text ---"
  }
}
```

---

#### 5.4.7 Get Adjustment Report

Get a report of all adjusted transactions.

```http
GET /transactions/reports/adjustments
Authorization: Bearer {token}

Query Parameters:
  startDate (optional) - Start date
  endDate (optional) - End date
  branchId (optional) - Filter by branch
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "adjustmentStats": {
      "count": 15,
      "totalAdjustmentAmount": 75000,
      "avgAdjustmentAmount": 5000
    },
    "adjustmentsByReason": [
      {
        "reason": "Price correction",
        "count": 8,
        "totalAmount": 40000
      },
      {
        "reason": "Discount applied late",
        "count": 7,
        "totalAmount": 35000
      }
    ],
    "adjustmentsByStaff": [
      {
        "staffId": "676...",
        "staffName": "Manager John",
        "count": 12,
        "totalAmount": 60000
      }
    ]
  }
}
```

---

#### 5.4.8 Get Refunds & Voids Report

Get a report of all refunds and voids.

```http
GET /transactions/reports/refunds-voids
Authorization: Bearer {token}

Query Parameters:
  startDate (optional) - Start date
  endDate (optional) - End date
  branchId (optional) - Filter by branch
  type (optional) - Filter by type (refunded, voided, or both)
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "stats": [
      {
        "status": "refunded",
        "count": 8,
        "totalAmount": 240000
      },
      {
        "status": "voided",
        "count": 5,
        "totalAmount": 125000
      }
    ],
    "byReason": [
      {
        "reason": "Customer dissatisfied",
        "count": 6,
        "totalAmount": 180000
      },
      {
        "reason": "Order mistake",
        "count": 7,
        "totalAmount": 185000
      }
    ],
    "byStaff": [
      {
        "staffId": "676...",
        "staffName": "Manager John",
        "refundCount": 8,
        "refundAmount": 240000,
        "voidCount": 5,
        "voidAmount": 125000
      }
    ],
    "transactions": [
      {
        "_id": "676...",
        "transactionId": "TXN-20251218-001",
        "originalAmount": 49500,
        "refundAmount": 49500,
        "status": "refunded",
        "reason": "Customer dissatisfied",
        "processedAt": "2025-12-18T14:30:00Z",
        "processedBy": "Manager John"
      }
    ]
  }
}
```

---

#### 5.4.9 Flutter Transaction Service Example

Complete implementation example for Flutter:

```dart
import 'package:dio/dio.dart';

class TransactionService {
  final Dio _dio;
  
  TransactionService(this._dio);
  
  /// Get transaction history with filtering
  Future<TransactionHistoryResponse> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? status,
    String? method,
    String? staffId,
    int page = 1,
    int limit = 20,
    bool includeSummary = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'includeSummary': includeSummary.toString(),
      };
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      if (branchId != null) queryParams['branchId'] = branchId;
      if (status != null) queryParams['status'] = status;
      if (method != null) queryParams['method'] = method;
      if (staffId != null) queryParams['staffId'] = staffId;
      
      final response = await _dio.get(
        '/api/v1/transactions/',
        queryParameters: queryParams,
      );
      
      // ✅ FIX: Access nested data structure
      final data = response.data['data'];
      
      return TransactionHistoryResponse(
        transactions: (data['transactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList(),
        pagination: Pagination.fromJson(data['pagination']),
        summary: data['summary'] != null
            ? TransactionSummary.fromJson(data['summary'])
            : null,
      );
      
    } catch (e) {
      print('❌ Get transactions error: $e');
      rethrow;
    }
  }
  
  /// Get transaction summary
  Future<TransactionSummaryReport> getSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }
    if (branchId != null) queryParams['branchId'] = branchId;
    
    final response = await _dio.get(
      '/api/v1/transactions/summary',
      queryParameters: queryParams,
    );
    
    return TransactionSummaryReport.fromJson(response.data['data']);
  }
  
  /// Get single transaction
  Future<Transaction> getTransaction(String transactionId) async {
    final response = await _dio.get('/api/v1/transactions/$transactionId');
    
    // ⚠️ Direct response (not wrapped)
    return Transaction.fromJson(response.data);
  }
  
  /// Process refund
  Future<RefundResult> processRefund({
    required String transactionId,
    required double refundAmount,
    required String refundMethod,
    required String reason,
    String? notes,
    required ManagerApproval managerApproval,
  }) async {
    final response = await _dio.post(
      '/api/v1/transactions/$transactionId/refund',
      data: {
        'refundAmount': refundAmount,
        'refundMethod': refundMethod,
        'reason': reason,
        if (notes != null) 'notes': notes,
        'managerApproval': {
          'managerId': managerApproval.managerId,
          'approvalCode': managerApproval.approvalCode,
        },
      },
    );
    
    return RefundResult.fromJson(response.data['data']);
  }
  
  /// Void transaction
  Future<VoidResult> voidTransaction({
    required String transactionId,
    required String reason,
    String? notes,
    required ManagerApproval managerApproval,
  }) async {
    final response = await _dio.post(
      '/api/v1/transactions/$transactionId/void',
      data: {
        'reason': reason,
        if (notes != null) 'notes': notes,
        'managerApproval': {
          'managerId': managerApproval.managerId,
          'approvalCode': managerApproval.approvalCode,
        },
      },
    );
    
    return VoidResult.fromJson(response.data['data']);
  }
}

// Response models
class TransactionHistoryResponse {
  final List<Transaction> transactions;
  final Pagination pagination;
  final TransactionSummary? summary;
  
  TransactionHistoryResponse({
    required this.transactions,
    required this.pagination,
    this.summary,
  });
}

class Transaction {
  final String id;
  final String transactionId;
  final String transactionType;
  final String transactionStatus;
  final ConsolidatedTotals consolidatedTotals;
  final PaymentSummary paymentSummary;
  final Timing timing;
  final Staff? staff;
  final TableInfo? tableInfo;
  final bool countInTotals;
  
  Transaction({
    required this.id,
    required this.transactionId,
    required this.transactionType,
    required this.transactionStatus,
    required this.consolidatedTotals,
    required this.paymentSummary,
    required this.timing,
    this.staff,
    this.tableInfo,
    required this.countInTotals,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'],
      transactionId: json['transactionId'] ?? '',
      transactionType: json['transactionType'] ?? 'sale',
      transactionStatus: json['transactionStatus'] ?? 'pending',
      consolidatedTotals: ConsolidatedTotals.fromJson(
        json['consolidatedTotals'] ?? {},
      ),
      paymentSummary: PaymentSummary.fromJson(
        json['paymentSummary'] ?? {},
      ),
      timing: Timing.fromJson(json['timing'] ?? {}),
      staff: json['staff'] != null ? Staff.fromJson(json['staff']) : null,
      tableInfo: json['tableInfo'] != null
          ? TableInfo.fromJson(json['tableInfo'])
          : null,
      countInTotals: json['countInTotals'] ?? true,
    );
  }
}

class TransactionSummary {
  final int totalTxnCount;
  final int salesCount;
  final int voidCount;
  final double salesAmount;
  final double voidAmount;
  final List<PaymentMethodBreakdown> paymentMethodBreakdown;
  
  TransactionSummary({
    required this.totalTxnCount,
    required this.salesCount,
    required this.voidCount,
    required this.salesAmount,
    required this.voidAmount,
    required this.paymentMethodBreakdown,
  });
  
  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalTxnCount: json['totalTxnCount'] ?? 0,
      salesCount: json['salesCount'] ?? 0,
      voidCount: json['voidCount'] ?? 0,
      salesAmount: (json['salesAmount'] ?? 0).toDouble(),
      voidAmount: (json['voidAmount'] ?? 0).toDouble(),
      paymentMethodBreakdown: (json['paymentMethodBreakdown'] as List?)
              ?.map((item) => PaymentMethodBreakdown.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// Usage in UI
class TransactionHistoryScreen extends StatefulWidget {
  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionService _service = TransactionService(dio);
  DateTime? startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime? endDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TransactionHistoryResponse>(
      future: _service.getTransactions(
        startDate: startDate,
        endDate: endDate,
        includeSummary: true,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final data = snapshot.data!;
        
        return Column(
          children: [
            // Summary cards
            if (data.summary != null)
              SummaryCards(summary: data.summary!),
            
            // Transaction list
            Expanded(
              child: ListView.builder(
                itemCount: data.transactions.length,
                itemBuilder: (context, index) {
                  final txn = data.transactions[index];
                  return TransactionTile(transaction: txn);
                },
              ),
            ),
            
            // Pagination
            PaginationWidget(pagination: data.pagination),
          ],
        );
      },
    );
  }
}
```

---

#### 5.4.10 Transaction Status Flow

```
Order Created
     ↓
[pending] → Transaction initiated
     ↓
[completed] → Payment successful
     ↓
     ├─→ [refunded] → Money returned to customer
     └─→ [voided] → Order cancelled (no money movement)
```

**Status Meanings:**
- `pending` - Transaction initiated, awaiting payment
- `completed` - Payment successful, counted in sales
- `refunded` - Full or partial refund issued
- `partially_refunded` - Some items refunded
- `voided` - Transaction cancelled, not counted in sales

---

#### 5.4.11 Best Practices

**For Transaction History:**
1. ✅ Always include date range for better performance
2. ✅ Use `includeSummary=false` when summary not needed
3. ✅ Implement pagination for large result sets
4. ✅ Cache transaction data with proper invalidation
5. ✅ Use timezone parameter for accurate local time filtering

**For Refunds & Voids:**
1. ✅ Always require manager approval
2. ✅ Provide clear reason for audit trail
3. ✅ Show confirmation dialog before processing
4. ✅ Update inventory if tracking stock
5. ✅ Print refund receipt for customer

**For Reports:**
1. ✅ Export to CSV/PDF for offline analysis
2. ✅ Use daily summaries for dashboard
3. ✅ Monitor refund/void rates for fraud detection
4. ✅ Track payment method performance
5. ✅ Analyze peak hours for staffing decisions

---

## 6. Inventory Management (🏆 USP #2)

### 6.1 Get Inventory Items

```http
GET /inventory/items
Authorization: Bearer {token}

Query Parameters:
  restaurantId (required) - Restaurant ID
  branchId (required) - Branch ID
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
  restaurantId (required) - Restaurant ID
  branchId (required) - Branch ID
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
  restaurantId (required) - Restaurant ID
  branchId (required) - Branch ID
  valuationMethod (optional) - FIFO, LIFO, AVERAGE
  categoryId (optional) - Filter by category
  itemType (optional) - Filter by item type
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
GET /crm/customers/:customerId/loyalty/available-points
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
POST /crm/loyalty-programs/:programId/redeem-points
Authorization: Bearer {token}
Content-Type: application/json

{
  "customerId": "60d5ecb84b24c72d88c4e126",
  "points": 100,
  "orderId": "60d5ecc04b24c72d88c4e128"
}
```

**Path Parameters:**
- `programId` - The loyalty program ID (required)

---

## 8. Reports

### 8.1 Daily Sales Summary

```http
GET /daily-summary/:restaurantId/:branchId
Authorization: Bearer {token}

Query Parameters:
  startDate (required) - YYYY-MM-DD
  endDate (required) - YYYY-MM-DD
```

**Alternative (Get Today's Summary):**
```http
GET /daily-summary/:restaurantId/:branchId/today
```

**Alternative (Get Specific Date):**
```http
GET /daily-summary/:restaurantId/:branchId/:date
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
GET /end-of-day/
Authorization: Bearer {token}

Query Parameters:
  branchId (required)
  date (required) - YYYY-MM-DD
```

**Get EOD Summary:**
```http
GET /end-of-day/summary
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

```dart
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
```dart
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
```dart
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
```dart
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
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
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
  bool get isRateLimited => code == 'RATE_LIMIT_EXCEEDED';
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
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
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

### 11.3 Authentication Service

```dart
// core/services/auth_service.dart
class AuthService {
  final ApiClient _api;
  
  AuthService(this._api);
  
  // Send OTP
  Future<void> sendOTP(String phone) async {
    await _api.post('/auth/phone/send-otp', data: {
      'phone': phone,
      'purpose': 'login',
    });
  }
  
  // Verify OTP (Smart Response - Login OR Registration Required)
  Future<OTPVerificationResult> verifyOTP(String phone, String otp) async {
    final response = await _api.post('/auth/phone/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
    
    if (response['success'] && response['verified']) {
      if (response['isRegistered']) {
        // Existing user - Logged in!
        final user = User.fromJson(response['user']);
        final tokens = Tokens.fromJson(response['tokens']);
        final hasPIN = response['hasPIN'] ?? false;
        
        // Save tokens
        await _saveTokens(tokens);
        
        // Save user data
        await SecureStorage().write(
          key: 'user_data',
          value: jsonEncode(user.toJson()),
        );
        
        return OTPVerificationResult.loggedIn(
          user: user,
          tokens: tokens,
          hasPIN: hasPIN,
        );
      } else {
        // New user - Registration required
        return OTPVerificationResult.registrationRequired(
          registrationToken: response['registrationToken'],
          phone: response['phone'],
        );
      }
    }
    
    throw ApiException(message: response['message'] ?? 'OTP verification failed');
  }
  
  // Complete Registration (Self-service)
  Future<AuthResult> registerWithPhone({
    required String registrationToken,
    required String name,
    required String restaurantName,
    String? pin,
  }) async {
    final response = await _api.post('/auth/phone/register', data: {
      'registrationToken': registrationToken,
      'name': name,
      'restaurantName': restaurantName,
      if (pin != null) 'pin': pin,
    });
    
    if (response['success'] && response['registered']) {
      final user = User.fromJson(response['user']);
      final tokens = Tokens.fromJson(response['tokens']);
      final restaurant = Restaurant.fromJson(response['restaurant']);
      
      // Save tokens
      await _saveTokens(tokens);
      
      // Save user data
      await SecureStorage().write(
        key: 'user_data',
        value: jsonEncode(user.toJson()),
      );
      
      return AuthResult(
        user: user,
        tokens: tokens,
        restaurant: restaurant,
        hasPIN: pin != null,
      );
    }
    
    throw ApiException(message: 'Registration failed');
  }
  
  // Helper: Save tokens
  Future<void> _saveTokens(Tokens tokens) async {
    await SecureStorage().write(
      key: 'auth_token',
      value: tokens.accessToken,
    );
    
    await SecureStorage().write(
      key: 'refresh_token',
      value: tokens.refreshToken,
    );
  }
  
  // Login with PIN (Fast - Recommended for daily use)
  Future<AuthResult> loginWithPIN(String phone, String pin) async {
    final response = await _api.post('/auth/phone/login', data: {
      'phone': phone,
      'pin': pin,
    });
    
    if (response['success']) {
      final user = User.fromJson(response['user']);
      final tokens = Tokens.fromJson(response['tokens']);
      
      // Save token to secure storage
      await SecureStorage().write(
        key: 'auth_token',
        value: tokens.accessToken,
      );
      
      await SecureStorage().write(
        key: 'refresh_token',
        value: tokens.refreshToken,
      );
      
      return AuthResult(user: user, tokens: tokens, hasPIN: true);
    }
    
    throw ApiException(message: 'Login failed');
  }
  
  // Setup PIN (Optional - for faster future logins)
  Future<void> setupPIN(String pin, {String? oldPin}) async {
    await _api.post('/auth/phone/setup-pin', data: {
      'pin': pin,
      if (oldPin != null) 'oldPin': oldPin,
    });
  }
  
  // Forgot PIN
  Future<void> forgotPIN(String phone) async {
    await _api.post('/auth/phone/forgot-pin', data: {
      'phone': phone,
    });
  }
  
  // Reset PIN
  Future<void> resetPIN(String phone, String otp, String newPin) async {
    await _api.post('/auth/phone/reset-pin', data: {
      'phone': phone,
      'otp': otp,
      'newPin': newPin,
    });
  }
  
  // Logout
  Future<void> logout() async {
    await SecureStorage().delete(key: 'auth_token');
    await SecureStorage().delete(key: 'refresh_token');
    await SecureStorage().delete(key: 'user_data');
  }
}

// Models
class AuthResult {
  final User user;
  final Tokens tokens;
  final Restaurant? restaurant;
  final bool hasPIN;
  
  AuthResult({
    required this.user,
    required this.tokens,
    this.restaurant,
    this.hasPIN = false,
  });
}

class OTPVerificationResult {
  final bool isRegistered;
  final User? user;
  final Tokens? tokens;
  final bool? hasPIN;
  final String? registrationToken;
  final String? phone;
  
  OTPVerificationResult._({
    required this.isRegistered,
    this.user,
    this.tokens,
    this.hasPIN,
    this.registrationToken,
    this.phone,
  });
  
  // Factory for logged in user
  factory OTPVerificationResult.loggedIn({
    required User user,
    required Tokens tokens,
    required bool hasPIN,
  }) {
    return OTPVerificationResult._(
      isRegistered: true,
      user: user,
      tokens: tokens,
      hasPIN: hasPIN,
    );
  }
  
  // Factory for registration required
  factory OTPVerificationResult.registrationRequired({
    required String registrationToken,
    required String phone,
  }) {
    return OTPVerificationResult._(
      isRegistered: false,
      registrationToken: registrationToken,
      phone: phone,
    );
  }
}
```

### 11.4 Complete Login Screen Example

```dart
// features/auth/otp_login_screen.dart
class OTPLoginScreen extends StatefulWidget {
  @override
  _OTPLoginScreenState createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  int _otpExpiresIn = 300;
  Timer? _timer;
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  // Step 1: Send OTP
  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _authService.sendOTP(_phoneController.text);
      
      setState(() {
        _otpSent = true;
        _isLoading = false;
        _otpExpiresIn = 300;
      });
      
      // Start countdown timer
      _startCountdown();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent to ${_phoneController.text}')),
      );
      
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }
  
  // Step 2: Verify OTP (Smart - Handles Login OR Registration)
  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _authService.verifyOTP(
        _phoneController.text,
        _otpController.text,
      );
      
      if (result.isRegistered) {
        // ✅ Existing User - LOGGED IN!
        Navigator.pushReplacementNamed(
          context,
          '/pos',
          arguments: result.user,
        );
        
        // Optional: Show PIN setup suggestion
        if (!result.hasPIN!) {
          Future.delayed(Duration(seconds: 2), () {
            _showPINSetupSuggestion();
          });
        }
      } else {
        // 📝 New User - Show Registration Form
        Navigator.pushNamed(
          context,
          '/register',
          arguments: {
            'registrationToken': result.registrationToken,
            'phone': result.phone,
          },
        );
      }
      
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }
  
  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_otpExpiresIn > 0) {
          _otpExpiresIn--;
        } else {
          timer.cancel();
        }
      });
    });
  }
  
  void _showPINSetupSuggestion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Setup PIN for Faster Login?'),
        content: Text(
          'Setup a 4-digit PIN for quicker logins in the future. '
          'You can always login with OTP if you forget your PIN.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/setup-pin');
            },
            child: Text('Setup PIN'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/logo.png', height: 80),
              SizedBox(height: 40),
              
              // Title
              Text(
                'AppZap POS',
                style: Theme.of(context).textTheme.headline4,
              ),
              SizedBox(height: 8),
              Text(
                _otpSent ? 'Enter OTP Code' : 'Login with Phone Number',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              SizedBox(height: 40),
              
              // Phone input
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '020 12345678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                enabled: !_otpSent,
              ),
              SizedBox(height: 16),
              
              // OTP input (shown after OTP sent)
              if (_otpSent) ...[
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'OTP Code',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    suffixText: _otpExpiresIn > 0 
                        ? '${_otpExpiresIn}s'
                        : 'Expired',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                ),
                SizedBox(height: 8),
                Text(
                  'Check your console for OTP code (Dev mode)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
              
              SizedBox(height: 8),
              
              // Error message
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 16),
              
              // Action button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading 
                      ? null 
                      : (_otpSent ? _verifyOTP : _sendOTP),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(_otpSent ? 'Verify & Continue' : 'Send OTP'),
                ),
              ),
              SizedBox(height: 16),
              
              // Secondary actions
              if (_otpSent) ...[
                TextButton(
                  onPressed: _otpExpiresIn <= 0 ? _sendOTP : null,
                  child: Text('Resend OTP'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                      _timer?.cancel();
                    });
                  },
                  child: Text('Change Phone Number'),
                ),
              ] else ...[
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pin-login');
                  },
                  child: Text('Login with PIN instead'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

### 11.5 Complete Registration Screen Example

```dart
// features/auth/registration_screen.dart
class RegistrationScreen extends StatefulWidget {
  final String registrationToken;
  final String phone;
  
  RegistrationScreen({
    required this.registrationToken,
    required this.phone,
  });
  
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _restaurantController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isLoading = false;
  bool _setupPIN = false;
  String? _errorMessage;
  
  Future<void> _completeRegistration() async {
    // Validate
    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }
    
    if (_restaurantController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your restaurant name');
      return;
    }
    
    if (_setupPIN && _pinController.text.length != 4) {
      setState(() => _errorMessage = 'PIN must be 4 digits');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _authService.registerWithPhone(
        registrationToken: widget.registrationToken,
        name: _nameController.text,
        restaurantName: _restaurantController.text,
        pin: _setupPIN ? _pinController.text : null,
      );
      
      // 🎉 Registration complete! Navigate to main app
      Navigator.pushReplacementNamed(
        context,
        '/pos',
        arguments: result.user,
      );
      
      // Show welcome message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome to AppZap POS! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Registration'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Text(
                  'Create Your Account',
                  style: Theme.of(context).textTheme.headline5,
                ),
                SizedBox(height: 8),
                Text(
                  'Phone verified: ${widget.phone} ✓',
                  style: TextStyle(color: Colors.green),
                ),
                SizedBox(height: 32),
                
                // Name input
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name *',
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                
                // Restaurant name input
                TextField(
                  controller: _restaurantController,
                  decoration: InputDecoration(
                    labelText: 'Restaurant/Shop Name *',
                    hintText: 'John\'s Coffee Shop',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                
                // Optional PIN setup
                CheckboxListTile(
                  value: _setupPIN,
                  onChanged: (value) {
                    setState(() => _setupPIN = value ?? false);
                  },
                  title: Text('Setup 4-digit PIN (Optional)'),
                  subtitle: Text('For faster daily logins'),
                  contentPadding: EdgeInsets.zero,
                ),
                
                if (_setupPIN) ...[
                  SizedBox(height: 8),
                  TextField(
                    controller: _pinController,
                    decoration: InputDecoration(
                      labelText: '4-Digit PIN',
                      hintText: '****',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                  ),
                ],
                
                SizedBox(height: 8),
                
                // Error message
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                ],
                
                SizedBox(height: 16),
                
                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Create Account & Start Selling'),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Info text
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 12. Testing & Troubleshooting

### 12.1 Complete Authentication Flow Diagram

```
┌────────────────────────────────────────────────────────────┐
│                    UNIFIED AUTH FLOW                        │
│              (Works for Everyone - New or Existing)         │
└────────────────────────────────────────────────────────────┘

Step 1: Enter Phone Number
   ↓
Step 2: Send OTP (POST /auth/phone/send-otp)
   ↓
   📱 Check backend console for OTP: 🔢 123456
   ↓
Step 3: Enter OTP Code
   ↓
Step 4: Verify OTP (POST /auth/phone/verify-otp)
   ↓
   ┌─────────────────────────────────────┐
   │  Is User Registered?                │
   └─────────────────────────────────────┘
          │                    │
          ├─→ YES              └─→ NO
          │   (Existing)           (New User)
          ↓                      ↓
   ✅ LOGGED IN!          📝 Show Registration Form
   - Full tokens              - Name: _____
   - User data                - Restaurant: _____
   - Navigate to POS          - PIN (optional): ____
   - Show PIN setup?          ↓
   (if no PIN)          Step 5: Submit Registration
                        (POST /auth/phone/register)
                             ↓
                        ✅ ACCOUNT CREATED & LOGGED IN!
                        - Restaurant created
                        - Owner account created
                        - Full tokens
                        - Navigate to POS

┌────────────────────────────────────────────────────────────┐
│                  DAILY LOGIN (FAST) ⚡                      │
└────────────────────────────────────────────────────────────┘

Option A: Phone + PIN (2 seconds)
   ↓
POST /auth/phone/login { phone, pin }
   ↓
✅ LOGGED IN!

Option B: Phone + OTP (30 seconds)
   ↓
POST /auth/phone/send-otp → Enter OTP → Verify
   ↓
✅ LOGGED IN!
```

---

### 12.2 Development Testing

#### Testing OTP in Development

In development mode, OTP codes are **console-logged** instead of being sent via SMS. Check your backend terminal for output like this:

```
============================================================
🔐 MOCK OTP SERVICE
============================================================
📱 Phone: +85620123456789
🔢 OTP Code: 123456          ← USE THIS CODE IN THE APP!
⏰ Purpose: login
⏱️  Expires in: 300 seconds (5 minutes)
🔄 Max Attempts: 3
============================================================
```

**Testing Flow for Existing User:**
1. **Flutter app:** Enter phone `020 12345678` → Tap "Send OTP"
2. **Backend terminal:** Copy the OTP code from console (e.g., `123456`)
3. **Flutter app:** Enter the OTP code → Tap "Verify & Continue"
4. **Result:** ✅ User is LOGGED IN with full authentication tokens!
5. **Check:** User can now access POS screens, create orders, etc.

**Testing Flow for New User (Self-Registration):**
1. **Flutter app:** Enter phone `020 99999999` (not in database) → Tap "Send OTP"
2. **Backend terminal:** Copy the OTP code from console (e.g., `654321`)
3. **Flutter app:** Enter the OTP code → Tap "Verify & Continue"
4. **Result:** 📝 Registration form appears
5. **Flutter app:** Enter:
   - Name: "Test User"
   - Restaurant: "Test Shop"
   - PIN (optional): "1234"
6. **Flutter app:** Tap "Create Account & Start Selling"
7. **Result:** ✅ Account created! Restaurant created! User is LOGGED IN!
8. **Check:** User can access POS, create products, start selling!

#### Test Endpoints

```bash
# Test 1: Send OTP (Works for ANY phone number!)
curl -X POST http://localhost:3000/api/v1/auth/phone/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "020 12345678", "purpose": "login"}'

# Check terminal for OTP:
# 🔢 OTP Code: 123456

# Test 2A: Verify OTP - Existing User (Returns full tokens)
curl -X POST http://localhost:3000/api/v1/auth/phone/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "020 12345678", "otp": "123456"}'

# Test 2B: Verify OTP - New User (Returns registrationToken)
curl -X POST http://localhost:3000/api/v1/auth/phone/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "020 99999999", "otp": "123456"}'

# Test 3: Complete Registration (New User)
curl -X POST http://localhost:3000/api/v1/auth/phone/register \
  -H "Content-Type: application/json" \
  -d '{
    "registrationToken": "eyJhbGc...",
    "name": "John Doe",
    "restaurantName": "Johns Coffee Shop",
    "pin": "1234"
  }'

# Test 4: Login with PIN (Existing User - Fast)
curl -X POST http://localhost:3000/api/v1/auth/phone/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "020 12345678", "pin": "1234"}'

# Test 5: Setup PIN (Optional - After Login)
curl -X POST http://localhost:3000/api/v1/auth/phone/setup-pin \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"pin": "1234"}'
```

#### Test Phone Numbers

All these formats are valid and auto-normalize to `+85620123456789`:

```
"020 12345678"
"20 1234 5678"
"+856 20 12345678"
"85620123456789"
```

---

### 12.2 Common Issues & Solutions

#### Issue: OTP not showing in console
**Solution:** Ensure backend is running in development mode (`NODE_ENV=development`)

#### Issue: "Phone number not registered"
**Solution:** Admin must create staff record with phone number on web dashboard first

#### Issue: PIN verification fails
**Solution:** 
- Check PIN is exactly 4 digits
- Verify staff has setup PIN (call `/auth/phone/setup-pin` first)
- Try resetting PIN with forgot PIN flow

#### Issue: Rate limit exceeded
**Solution:** 
- Wait 10 minutes, or
- Clear Redis key: `redis-cli DEL "otp:rate:+85620123456789"`

#### Issue: PhayPay endpoint not found
**Solution:** Use `/payments/phajay/create` (not `/generate-qr` or `/generate-link`)

#### Issue: Invalid OTP
**Solutions:**
- OTP expires in 5 minutes - request new one if expired
- Max 3 attempts per OTP - request new one if exceeded
- Check you're entering the correct OTP from console

#### Issue: Token expired (401 Unauthorized)
**Solution:**
```dart
// Use refresh token to get new access token
await authService.refreshTokens(refreshToken);
```

---

### 12.3 Complete Flow Comparison

#### **Flow 1: New User (Self-Registration)**

```dart
// Step 1: Send OTP
await authService.sendOTP('020 99999999');
// ✅ OTP sent to ANY phone (no check needed)

// Step 2: Verify OTP
final result = await authService.verifyOTP('020 99999999', '123456');

// Step 3: Check result
if (!result.isRegistered) {
  // New user - Show registration form
  final registrationData = await showRegistrationForm(
    registrationToken: result.registrationToken,
    phone: result.phone,
  );
  
  // Step 4: Complete registration
  final authResult = await authService.registerWithPhone(
    registrationToken: result.registrationToken,
    name: registrationData.name,
    restaurantName: registrationData.restaurantName,
    pin: registrationData.pin, // Optional
  );
  
  // ✅ ACCOUNT CREATED & LOGGED IN!
  navigateToMainApp(authResult.user);
}
```

#### **Flow 2: Existing User (Login)**

```dart
// Step 1: Send OTP
await authService.sendOTP('020 12345678');

// Step 2: Verify OTP
final result = await authService.verifyOTP('020 12345678', '123456');

// Step 3: Check result
if (result.isRegistered) {
  // ✅ LOGGED IN IMMEDIATELY!
  navigateToMainApp(result.user);
  
  // Optional: Suggest PIN setup
  if (!result.hasPIN!) {
    showPINSetupSuggestion();
  }
}
```

#### **Flow 3: Fast Daily Login (PIN)**

```dart
// One-step login (if PIN is set up)
final result = await authService.loginWithPIN('020 12345678', '1234');

// ✅ LOGGED IN in 2 seconds!
navigateToMainApp(result.user);
```

---

### 12.4 Phone Number Format Testing

```dart
// Test all phone formats
final testPhones = [
  '020 12345678',      // Laos local format
  '20 1234 5678',      // Without leading 0
  '+856 20 12345678',  // International format
  '85620123456789',    // Without spaces
];

for (final phone in testPhones) {
  final result = await authService.sendOTP(phone);
  print('✅ $phone → ${result.normalizedPhone}');
}
```

---

### 12.4 Production Deployment Checklist

#### Environment Variables
```bash
# API Base URL
API_BASE_URL=https://api.appzap.la/api/v1

# Lailao Auth (SMS Provider)
LAILAO_AUTH_ENABLED=true
LAILAO_AUTH_DOMAIN_NAME=appzap.lailaolab.com

# PhayPay (Payment Gateway)
PHAJAY_API_URL=https://payment-gateway.phajay.co/v1/api
PHAJAY_SECRET_KEY=your_production_secret_key
PHAJAY_QR_EXPIRY_MINUTES=10
PHAJAY_PAYMENT_LINK_EXPIRY_MINUTES=30

# Redis
REDIS_URL=redis://production-redis-server:6379

# JWT
JWT_SECRET=your_production_jwt_secret
JWT_ACCESS_EXPIRATION_MINUTES=60
JWT_REFRESH_EXPIRATION_DAYS=30
```

#### Pre-deployment Testing
- [ ] Test all authentication flows (OTP, PIN, forgot PIN)
- [ ] Test PhayPay payment with all 4 banks
- [ ] Test offline mode and sync
- [ ] Test WebSocket real-time updates
- [ ] Test rate limiting and security
- [ ] Test on slow network (3G simulation)
- [ ] Load test with 100+ concurrent users
- [ ] Test receipt printing
- [ ] Test barcode scanning

#### Go-Live Checklist
- [ ] Configure production SMS provider (Lailao Auth)
- [ ] Configure production payment gateway (PhayPay)
- [ ] Set up monitoring and alerts
- [ ] Configure backup and disaster recovery
- [ ] Train staff on app usage
- [ ] Prepare support documentation
- [ ] Set up customer support channels

---

### 12.5 Performance Best Practices

#### Optimize API Calls
```dart
// Cache products locally
class ProductCache {
  List<Product>? _cache;
  DateTime? _lastFetch;
  
  Future<List<Product>> getProducts(bool forceRefresh) async {
    if (!forceRefresh && 
        _cache != null && 
        DateTime.now().difference(_lastFetch!) < Duration(minutes: 5)) {
      return _cache!;
    }
    
    _cache = await api.getProducts();
    _lastFetch = DateTime.now();
    return _cache!;
  }
}
```

#### Implement Pagination
```dart
// Load products in batches
await productService.getProducts(
  page: 1,
  limit: 100,
);
```

#### Use WebSocket for Real-time Updates
```dart
// Don't poll - use WebSocket instead
socket.on('inventory:updated', (data) {
  // Update local cache
  productCache.update(data);
});
```

---

## 13. Quick Start Checklist

### For Flutter Developers:

**Phase 1 - Week 1: Setup & Authentication**
- [ ] Set up Flutter project structure
- [ ] Configure Dio for API calls
- [ ] Implement OTP login screen (handles both login & registration)
- [ ] Implement registration screen (3 fields: name, restaurant, PIN optional)
- [ ] Implement phone + PIN fast login (optional daily use)
- [ ] Set up secure storage for tokens
- [ ] Test complete flow:
  - [ ] New user self-registration (phone → OTP → register → logged in!)
  - [ ] Existing user login (phone → OTP → logged in!)
  - [ ] Fast PIN login (phone → PIN → logged in!)
- [ ] Add optional PIN setup suggestion dialog

**Phase 1 - Week 2-3: Core POS**
- [ ] Implement product listing & categories
- [ ] Build cart functionality
- [ ] Create checkout flow
- [ ] Implement cash payment
- [ ] Test order creation
- [ ] Add barcode scanning

**Phase 1 - Week 4: PhayPay (USP #1)**
- [ ] Integrate PhayPay payment
- [ ] Display QR codes
- [ ] Poll payment status
- [ ] Handle success/failure
- [ ] Test all 4 banks (JDB, BCEL, LDB, IB)

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

**Phase 1 - Week 8: Offline Mode & Testing**
- [ ] Set up local database (Drift)
- [ ] Implement offline cart
- [ ] Build sync engine
- [ ] Test offline scenarios
- [ ] Handle sync conflicts
- [ ] Final testing & bug fixes

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
- Backend Implementation: `/docs/PHONE_AUTH_IMPLEMENTATION_SUMMARY.md`

---

**END OF DOCUMENTATION**

This comprehensive API documentation covers all Phase 1 features needed to build a Universal POS that beats Loyverse. The Flutter team has everything they need to get started immediately.

**Questions?** Contact: tech@appzap.la

**Last Updated:** December 17, 2025  
**Status:** ✅ Production Ready  
**Version:** 1.0
