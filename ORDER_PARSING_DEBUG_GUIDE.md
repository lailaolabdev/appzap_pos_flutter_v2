# Order Parsing Debug Guide

## 🐛 **The Bug**

**Error:** `type '_Map<String, dynamic>' is not a subtype of type 'num?' in type cast`

**Location:** Orders page when loading order list

**Root Cause:** The code was trying to cast `pricing.total` to a number (`num?`), but the API was returning a **`MoneyAmount` object** (Map) instead of a simple number.

---

## 📋 **The Problem**

### **Before (BROKEN):**
```dart
// Line 81 (old code)
total: ((data['pricing'] as Map<String, dynamic>?)?['total'] as num?)?.toDouble() ?? 0.0,
```

**What was expected:**
```json
"pricing": {
  "total": 22000  // ❌ Expected simple number
}
```

**What the API actually returns:**
```json
"pricing": {
  "total": {      // ✅ Actually a MoneyAmount object!
    "amount": 22000,
    "currency": "LAK"
  }
}
```

**Result:** Type cast error because we tried to cast a `Map` to `num?`!

---

## ✅ **The Fix**

### **After (FIXED):**
```dart
// Robust parsing that handles BOTH formats
double total = 0.0;

if (pricingData is Map<String, dynamic>) {
  final totalData = pricingData['total'];
  
  if (totalData is num) {
    // Simple number format
    total = totalData.toDouble();
  } else if (totalData is Map<String, dynamic>) {
    // MoneyAmount format: { amount: 22000, currency: "LAK" }
    final amount = totalData['amount'];
    if (amount is num) {
      total = amount.toDouble();
    }
  }
}
```

**Now handles:**
- ✅ Simple number: `"total": 22000`
- ✅ MoneyAmount object: `"total": { "amount": 22000, "currency": "LAK" }`

---

## 🔍 **Debug Logs Explained**

### **When you load the Orders page, you'll see these logs:**

```
🔄 Loading orders for branch: 676...
📦 Raw response type: _Map<String, dynamic>
📦 Raw response: {success: true, data: {orders: [...], pagination: {...}}}
   Response keys: [success, data, timestamp]
   Orders data length: 5

📋 Parsing order 0:
   Order keys: [_id, orderCode, restaurantId, branchId, orderType, orderStatus, lineItems, pricing, customer, ...]
   _id: 676abc123...
   orderNumber: ORD-20251218-001
   status: pending
   customerName: John Doe
   createdAt: 2025-12-18T10:00:00.000Z
   itemCount: 2
   Parsing total...
   pricing type: _Map<String, dynamic>
   pricing keys: [subtotal, tax, discountTotal, total, currency]
   total type: _Map<String, dynamic>          ← THIS IS THE KEY!
   total value: {amount: 22000, currency: LAK}
   amount type: int
   amount value: 22000
   ✅ Parsed as MoneyAmount: 22000.0
   Final total: 22000.0
   ✅ Order parsed successfully

📋 Parsing order 1:
   ...

✅ Successfully parsed 5 orders
```

---

## 📊 **What to Look For in Logs**

### **1. Response Structure:**
```
📦 Raw response type: _Map<String, dynamic>
   Response keys: [success, data, timestamp]
```
✅ **Good:** Response is a Map with `success`, `data`, `timestamp`

### **2. Orders Data:**
```
   Orders data length: 5
```
✅ **Good:** API returned 5 orders

### **3. Pricing Format (THE IMPORTANT PART!):**

**Case A: Simple Number (if API changes):**
```
   total type: int
   total value: 22000
   ✅ Parsed as simple number: 22000.0
```

**Case B: MoneyAmount Object (current):**
```
   total type: _Map<String, dynamic>
   total value: {amount: 22000, currency: LAK}
   amount type: int
   amount value: 22000
   ✅ Parsed as MoneyAmount: 22000.0
```

### **4. Success or Error:**

**✅ Success:**
```
   ✅ Order parsed successfully
✅ Successfully parsed 5 orders
```

**❌ Error:**
```
   ❌ Error parsing order 2: type 'String' is not a subtype of type 'Map<String, dynamic>'
   Stack trace: ...
```

---

## 🎯 **How to Use These Logs**

### **If orders load successfully:**
You'll see:
1. ✅ "Successfully parsed X orders"
2. No ❌ errors
3. Orders display correctly in the UI

### **If orders fail to load:**

**Step 1: Check the response structure**
```
📦 Raw response type: ???
📦 Raw response: ???
```
- Is it a Map or List?
- Does it have the expected keys?

**Step 2: Check the orders data**
```
   Orders data length: ???
```
- Is it 0 (no orders)?
- Is it null (API issue)?

**Step 3: Check individual order parsing**
```
📋 Parsing order X:
   ❌ Error parsing order X: ...
```
- Which field is causing the error?
- What type did we expect vs. what we got?

**Step 4: Check the pricing format**
```
   total type: ???
   total value: ???
```
- Is `total` a number or object?
- Does `total` have an `amount` field?

---

## 🛠️ **Common Issues & Solutions**

### **Issue 1: "Orders data length: 0"**
**Cause:** No orders in the database for this branch  
**Solution:** Create some test orders first

### **Issue 2: "total type: String"**
**Cause:** API is returning total as a string instead of number/object  
**Solution:** Update parsing to handle string: `double.tryParse(totalData as String) ?? 0.0`

### **Issue 3: "pricing is not a Map!"**
**Cause:** `pricing` field is missing or null  
**Solution:** Already handled - defaults to `0.0`

### **Issue 4: "amount is not a number!"**
**Cause:** `amount` inside `MoneyAmount` is a string  
**Solution:** Update parsing to handle string: `double.tryParse(amount as String) ?? 0.0`

---

## 📝 **API Documentation Reference**

According to `doc/appzap_api_doc.md` (Section 4.2 - Get Orders):

**Response format for GET /orders/:**
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "_id": "676...",
        "orderCode": "ORD-20251218-001",
        "orderStatus": "pending",
        "lineItems": [...],
        "pricing": {
          "subtotal": 50000,      // Could be MoneyAmount object
          "tax": 5000,            // Could be MoneyAmount object
          "discountTotal": 0,
          "total": 55000,         // Could be MoneyAmount object
          "currency": "LAK"
        },
        ...
      }
    ],
    "pagination": {...},
    "statistics": {...}
  }
}
```

**⚠️ Note:** The API documentation shows `total` as a simple number, but the actual API response may return `MoneyAmount` objects (from the checkout flow). Our code now handles **both formats** robustly!

---

## 🚀 **Next Steps**

1. **Test the Orders page** - Orders should now load without errors
2. **Check the console logs** - You'll see detailed parsing information
3. **If you see errors** - Use the logs to identify exactly which field is causing issues
4. **Report to backend team** - If the API format doesn't match the documentation

---

## 📞 **Need Help?**

If you see unexpected log output or errors:
1. Copy the full log output (from `🔄 Loading orders...` to `✅ Successfully parsed...`)
2. Share it with the team
3. We can quickly identify the exact issue!

---

**Status:** ✅ FIXED with comprehensive debug logging  
**Date:** December 23, 2025

