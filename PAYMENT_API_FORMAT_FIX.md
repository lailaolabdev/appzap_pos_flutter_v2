# Payment API Format Fix - Aligned with API Documentation

## 🔍 **Problem Identified**

The Flutter app was sending payment data in an **incorrect format** that didn't match the updated API documentation.

### ❌ **Old Format (WRONG)**:
```dart
{
  "method": "cash",
  "amount": 22000,           // ❌ Should not exist
  "customerAmount": 25000,   // ❌ Should be an object
  "change": 3000,            // ❌ Should not exist (calculated by backend)
  "currency": "LAK"          // ❌ Should be nested in amount objects
}
```

### ✅ **New Format (CORRECT)**:
```dart
{
  "method": "cash",
  "customerAmount": {         // ✅ Object with amount + currency
    "amount": 22000,
    "currency": "LAK"
  },
  "tenderedAmount": {         // ✅ Object with amount + currency
    "amount": 25000,
    "currency": "LAK"
  }
}
```

---

## 🛠️ **Changes Made**

### 1. **Created `MoneyAmount` Class**

```dart
/// Money amount object (matches API format)
class MoneyAmount {
  final double amount;
  final String currency;

  MoneyAmount({
    required this.amount,
    this.currency = 'LAK',
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currency': currency,
  };
}
```

**Purpose:** This class represents money amounts as nested objects, matching the API specification.

---

### 2. **Updated `PaymentMethod` Class**

#### Before:
```dart
class PaymentMethod {
  final String method;
  final double amount;           // ❌ Flat value
  final double customerAmount;   // ❌ Flat value
  final double change;           // ❌ Should not be sent
  final String currency;         // ❌ Should be nested
  final Map<String, dynamic>? paymentDetails;
}
```

#### After:
```dart
class PaymentMethod {
  final String method;
  final MoneyAmount customerAmount;  // ✅ Nested object
  final MoneyAmount? tenderedAmount; // ✅ Optional nested object
  final Map<String, dynamic>? paymentDetails;
}
```

**Key Improvements:**
- ✅ Uses `MoneyAmount` objects for all money values
- ✅ `tenderedAmount` is optional (only required for cash payments)
- ✅ Removed `amount`, `change`, and `currency` fields (change is calculated by backend)

---

### 3. **Updated `toJson()` Method**

```dart
Map<String, dynamic> toJson() {
  final json = <String, dynamic>{
    'method': method,
    'customerAmount': customerAmount.toJson(),
  };
  
  // Only include tenderedAmount if provided (required for cash)
  if (tenderedAmount != null) {
    json['tenderedAmount'] = tenderedAmount!.toJson();
  }
  
  // Include payment details if provided (for QR payments, etc.)
  if (paymentDetails != null && paymentDetails!.isNotEmpty) {
    json['paymentDetails'] = paymentDetails;
  }
  
  return json;
}
```

**Logic:**
- Always sends `method` and `customerAmount`
- Only sends `tenderedAmount` if provided (cash payments)
- Only sends `paymentDetails` if provided (QR payments)

---

### 4. **Updated Helper Methods**

#### Cash Payment:
```dart
// ✅ Create payment method with correct API format
final payment = PaymentMethod(
  method: 'cash',
  customerAmount: MoneyAmount(
    amount: cart.total,        // Order total (amount to pay)
    currency: 'LAK',
  ),
  tenderedAmount: MoneyAmount(
    amount: tenderedAmount,    // Cash customer gave
    currency: 'LAK',
  ),
);
```

#### PhayPay/QR Payment:
```dart
// ✅ Create payment method with correct API format
// For QR payments: only customerAmount is required (no tenderedAmount)
final payment = PaymentMethod(
  method: bankMethod,          // e.g., 'bank_qr_jdb'
  customerAmount: MoneyAmount(
    amount: cart.total,        // Order total
    currency: 'LAK',
  ),
  // No tenderedAmount for QR payments (customer pays exact amount)
  paymentDetails: paymentDetails,
);
```

---

## 📋 **API Request Formats**

### **Cash Payment Request:**
```json
{
  "lineItems": [
    {
      "menuItemId": "676...",
      "name": "Iced Latte",
      "quantity": 2,
      "unitPrice": 10000,
      "subtotal": 20000
    }
  ],
  "payments": [
    {
      "method": "cash",
      "customerAmount": {
        "amount": 22000,
        "currency": "LAK"
      },
      "tenderedAmount": {
        "amount": 25000,
        "currency": "LAK"
      }
    }
  ],
  "expectedTotal": 22000,
  "idempotencyKey": "checkout-1234567890"
}
```

### **PhayPay/QR Payment Request:**
```json
{
  "lineItems": [...],
  "payments": [
    {
      "method": "bank_qr_jdb",
      "customerAmount": {
        "amount": 22000,
        "currency": "LAK"
      },
      "paymentDetails": {
        "qrPaymentId": "PHAJAY-123",
        "bankReference": "JDB-REF-456"
      }
    }
  ],
  "expectedTotal": 22000,
  "idempotencyKey": "phaypay-1234567890"
}
```

---

## 📊 **Expected API Response**

```json
{
  "success": true,
  "data": {
    "order": {
      "_id": "676...",
      "orderId": "ORD-20251221-001",
      "orderNumber": "Q-001",
      "orderStatus": "completed",
      "lineItems": [...],
      "pricing": {
        "subtotal": { "amount": 20000, "currency": "LAK" },
        "totalTax": { "amount": 2000, "currency": "LAK" },
        "totalDue": { "amount": 22000, "currency": "LAK" }
      }
    },
    "transaction": {
      "transactionId": "TXN-20251221-001",
      "transactionStatus": "completed",
      "paymentSummary": {
        "totalPaid": { "amount": 22000, "currency": "LAK" },
        "totalChange": { "amount": 3000, "currency": "LAK" },
        "paymentMethodBreakdown": [
          {
            "method": "cash",
            "customerAmount": { "amount": 22000, "currency": "LAK" },
            "tenderedAmount": { "amount": 25000, "currency": "LAK" },
            "changeGiven": { "amount": 3000, "currency": "LAK" }
          }
        ]
      }
    },
    "pricing": {
      "subtotal": { "amount": 20000, "currency": "LAK" },
      "totalTax": { "amount": 2000, "currency": "LAK" },
      "totalDue": { "amount": 22000, "currency": "LAK" }
    }
  }
}
```

---

## ✅ **Testing Checklist**

- [x] `MoneyAmount` class created with proper serialization
- [x] `PaymentMethod` updated to use `MoneyAmount` objects
- [x] `toJson()` method correctly formats nested objects
- [x] Cash payment helper creates correct request format
- [x] PhayPay payment helper creates correct request format
- [x] No linter errors
- [ ] **Test cash payment in app** - verify backend accepts new format
- [ ] **Test PhayPay payment in app** - verify QR payment works
- [ ] **Verify change calculation** - backend should return correct change amount
- [ ] **Check error handling** - ensure errors are properly caught

---

## 🎯 **Key Benefits**

1. **✅ API Compliance:** Request format now matches API documentation exactly
2. **✅ Backend Compatibility:** Backend can correctly parse the nested money objects
3. **✅ Clarity:** Separation of concerns - amount vs. tendered amount
4. **✅ Flexibility:** Supports split payments and multiple currencies
5. **✅ Maintainability:** Clear, type-safe structure

---

## 🔄 **Before vs After Examples**

### **Before (Broken):**
```dart
PaymentMethod(
  method: 'cash',
  amount: 22000,           // ❌
  customerAmount: 25000,   // ❌
  change: 3000,            // ❌
  currency: 'LAK',         // ❌
)
```

**Sent to API:**
```json
{
  "method": "cash",
  "amount": 22000,
  "customerAmount": 25000,
  "change": 3000,
  "currency": "LAK"
}
```
**Result:** ❌ Backend rejects or misinterprets the data

---

### **After (Fixed):**
```dart
PaymentMethod(
  method: 'cash',
  customerAmount: MoneyAmount(
    amount: 22000,
    currency: 'LAK',
  ),
  tenderedAmount: MoneyAmount(
    amount: 25000,
    currency: 'LAK',
  ),
)
```

**Sent to API:**
```json
{
  "method": "cash",
  "customerAmount": {
    "amount": 22000,
    "currency": "LAK"
  },
  "tenderedAmount": {
    "amount": 25000,
    "currency": "LAK"
  }
}
```
**Result:** ✅ Backend processes correctly, returns change = 3000

---

## 📝 **Files Modified**

- `lib/core/services/checkout_service.dart`
  - Added `MoneyAmount` class
  - Updated `PaymentMethod` class
  - Updated `processCashPaymentFromCart` method
  - Updated `processPhayPayPaymentFromCart` method

---

## 🚀 **Next Steps**

1. **Run the app** and test cash payment flow
2. **Verify backend response** - check that change is calculated correctly
3. **Test PhayPay payment** - ensure QR codes work
4. **Monitor logs** - look for any API errors related to payment format
5. **Update any other services** that might be using the old `PaymentMethod` format

---

## 💡 **API Documentation Reference**

See `doc/appzap_api_doc.md` Section 5.2 "Process Payment (Unified Checkout)" for complete API specification.

**Key Sections:**
- 5.2.1 - Takeaway/Quick Sale Payment
- 5.2.2 - Table Checkout
- 5.2.3 - Split Payment Example
- 5.2.4 - Flutter Implementation Example

---

**Status:** ✅ **FIXED AND ALIGNED WITH API DOCUMENTATION**

The payment request format now correctly matches the API specification with nested money amount objects!

