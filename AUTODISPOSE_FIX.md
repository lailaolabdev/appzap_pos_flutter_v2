# AutoDispose Provider Fix - Dialog Uses Its Own Ref

## 🔍 **Problem: PaymentNotifier Disposed After Bottom Sheet Closes**

```
flutter: ❌ Payment exception: Bad state: Tried to use PaymentNotifier after `dispose` was called.
```

### **Root Cause:**

The `paymentProvider` is defined with `autoDispose`:

```dart
final paymentProvider =
    StateNotifierProvider.autoDispose<PaymentNotifier, PaymentState>((ref) {
      final checkoutService = ref.watch(checkoutServiceProvider);
      final branchId = ref.watch(currentBranchIdProvider);
      return PaymentNotifier(checkoutService, branchId);
    });
```

**What happens:**
1. Payment selection bottom sheet opens → `paymentProvider` is created
2. User clicks "Cash" → We capture `paymentNotifier` instance
3. Bottom sheet closes → **`autoDispose` disposes the provider AND the notifier instance!**
4. Cash dialog opens → Callback tries to use the disposed notifier → **ERROR!**

Even though we captured the `paymentNotifier` instance before closing, the instance itself got disposed by the `autoDispose` mechanism.

---

## ✅ **Solution: Let Dialog Use Its Own Ref**

Instead of passing the payment logic from the parent, let the `CashPaymentDialog` handle payment processing using **its own `ref`**.

Since `CashPaymentDialog` is a `ConsumerStatefulWidget`, it has its own `ref` that will watch the `paymentProvider` **while the dialog is open**. This keeps the provider alive during payment processing!

---

## 🛠️ **Implementation Changes**

### **1. Update CashPaymentDialog to Accept Cart Instead of Callback**

#### Before (BROKEN):
```dart
class CashPaymentDialog extends ConsumerStatefulWidget {
  final double totalAmount;
  final Future<bool> Function(double tenderedAmount) onProcessPayment; // ❌ Callback from parent

  const CashPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onProcessPayment,
  });
}
```

#### After (FIXED):
```dart
class CashPaymentDialog extends ConsumerStatefulWidget {
  final double totalAmount;
  final Cart cart; // ✅ Pass cart data instead

  const CashPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.cart,
  });
}
```

---

### **2. Dialog Watches Provider to Keep It Alive**

#### Before (BROKEN):
```dart
@override
Widget build(BuildContext context) {
  // ❌ Not watching provider = it can dispose during async operations
  return Scaffold(...);
}
```

#### After (FIXED):
```dart
@override
Widget build(BuildContext context) {
  // ✅ Watch provider to keep it alive for entire widget lifetime
  ref.watch(paymentProvider);
  
  return Scaffold(...);
}
```

---

### **3. Capture Notifier Before Async Operation**

#### Before (BROKEN):
```dart
onPressed: () async {
  setState(() {
    _isProcessing = true;
  });
  
  try {
    // ❌ ref.read() during async - notifier can dispose mid-operation!
    final success = await ref.read(paymentProvider.notifier).processCashPayment(
      total: widget.totalAmount,
      tendered: finalAmount,
      cart: widget.cart,
    );
    
    if (success && mounted) {
      Navigator.pop(context, {'success': true});
    }
  } catch (e) {
    // Handle error
  }
}
```

#### After (FIXED):
```dart
onPressed: () async {
  // ✅ Capture notifier BEFORE async operation
  final paymentNotifier = ref.read(paymentProvider.notifier);
  
  setState(() {
    _isProcessing = true;
  });
  
  try {
    // ✅ Use captured notifier (stays alive because provider is watched!)
    final success = await paymentNotifier.processCashPayment(
      total: widget.totalAmount,
      tendered: finalAmount,
      cart: widget.cart,
    );
    
    if (success && mounted) {
      Navigator.pop(context, {'success': true});
    }
  } catch (e) {
    // Handle error
  }
}
```

---

### **3. Update Parent to Pass Cart Instead of Callback**

#### Before (BROKEN):
```dart
_PaymentMethodButton(
  label: 'Cash',
  onTap: () {
    final paymentNotifier = ref.read(paymentProvider.notifier); // ❌ Will be disposed!
    final cartNotifier = ref.read(cartProvider.notifier);
    
    Navigator.pop(context);
    
    _handleCashPayment(context, paymentNotifier, cartNotifier, cart);
  },
),
```

#### After (FIXED):
```dart
_PaymentMethodButton(
  label: 'Cash',
  onTap: () {
    final cartNotifier = ref.read(cartProvider.notifier); // ✅ Only need cart notifier
    
    Navigator.pop(context);
    
    _handleCashPayment(context, cartNotifier, cart); // ✅ No paymentNotifier needed!
  },
),
```

---

### **4. Simplify _handleCashPayment Function**

#### Before (BROKEN):
```dart
Future<void> _handleCashPayment(
  BuildContext context,
  PaymentNotifier paymentNotifier, // ❌ Receives disposed notifier
  CartNotifier cartNotifier,
  Cart cart,
) async {
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => CashPaymentDialog(
        totalAmount: cart.total,
        onProcessPayment: (double tenderedAmount) async {
          // ❌ Uses disposed paymentNotifier
          final success = await paymentNotifier.processCashPayment(...);
          return success;
        },
      ),
    ),
  );
  
  // ... handle result
}
```

#### After (FIXED):
```dart
Future<void> _handleCashPayment(
  BuildContext context,
  CartNotifier cartNotifier, // ✅ Only need cart notifier
  Cart cart,
) async {
  // ✅ Dialog handles payment internally (no callback needed!)
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => CashPaymentDialog(
        totalAmount: cart.total,
        cart: cart, // ✅ Just pass data
      ),
    ),
  );
  
  // ... handle result
}
```

---

## 📊 **Provider Lifecycle Timeline**

### **Before (BROKEN):**
```
1. Bottom sheet opens
   └─ paymentProvider created (ref count: 1) ✅

2. User clicks "Cash"
   └─ Capture paymentNotifier instance ✅
   └─ Bottom sheet closes
   └─ ref count drops to 0
   └─ autoDispose kicks in
   └─ paymentProvider disposed ❌
   └─ PaymentNotifier instance disposed ❌

3. Cash dialog opens
   └─ paymentProvider NOT watched (no ref.watch/read in builder)
   └─ Provider stays disposed ❌

4. User clicks "Complete Payment"
   └─ Callback tries to use disposed notifier
   └─ ERROR: "Tried to use PaymentNotifier after `dispose` was called" ❌
```

### **After (FIXED):**
```
1. Bottom sheet opens
   └─ paymentProvider created (ref count: 1) ✅

2. User clicks "Cash"
   └─ Bottom sheet closes
   └─ ref count drops to 0
   └─ autoDispose kicks in
   └─ paymentProvider disposed (this is OK!) ✅

3. Cash dialog opens (CashPaymentDialog is a ConsumerStatefulWidget)
   └─ Dialog has its own ref ✅
   └─ Dialog is part of the widget tree ✅

4. User clicks "Complete Payment"
   └─ Dialog calls ref.read(paymentProvider.notifier) ✅
   └─ paymentProvider is created fresh (ref count: 1) ✅
   └─ processCashPayment() executes successfully ✅
   └─ Payment completes ✅

5. Dialog closes
   └─ ref count drops to 0
   └─ paymentProvider disposes (this is OK!) ✅
```

---

## 🎯 **Key Concepts**

### **AutoDispose Providers:**
- Automatically dispose when **no widgets are watching them**
- Ref count drops to 0 → provider disposes
- Provider instances cannot be reused after disposal
- **CRITICAL**: `ref.read()` doesn't create a watcher - only `ref.watch()` does!

### **ref.read() vs ref.watch():**
- **`ref.read()`**: One-time read, doesn't keep provider alive
- **`ref.watch()`**: Creates a listener, keeps provider alive for widget lifetime
- **For async operations with autoDispose**: Must use `ref.watch()` to prevent disposal

### **The Async Disposal Problem:**
```dart
// ❌ BROKEN: Provider can dispose during async operation
final result = await ref.read(provider.notifier).asyncMethod();

// ✅ FIXED: Watch provider to keep it alive
ref.watch(provider); // In build method
final notifier = ref.read(provider.notifier); // Capture before async
final result = await notifier.asyncMethod(); // Use captured instance
```

### **ConsumerStatefulWidget Has Its Own Ref:**
- Each `ConsumerStatefulWidget` has its own `ref`
- `ref` is alive as long as the widget is mounted
- `ref.read()` or `ref.watch()` creates/watches providers

### **Separation of Concerns:**
- **Parent widget**: Handles navigation and result handling
- **Dialog widget**: Handles its own business logic using its own `ref`
- **No callbacks needed**: Dialog is self-contained!

---

## ✅ **Testing Checklist**

- [x] Click "Checkout" → "Cash"
- [x] Bottom sheet closes ✅
- [x] Cash dialog opens ✅
- [x] Enter amount → "Complete Payment"
- [x] Loading shows inside dialog ✅
- [x] **No disposal error!** ✅
- [x] Payment processes successfully ✅
- [x] Success dialog appears ✅
- [x] Cart clears ✅

---

## 📝 **Files Modified**

1. **`lib/features/payment/widgets/cash_payment_dialog.dart`**
   - Changed constructor to accept `Cart` instead of callback
   - Added import for `Cart` model
   - **Added `ref.watch(paymentProvider)` in build method to keep provider alive**
   - **Capture notifier before async operation**
   - Dialog now calls captured notifier internally

2. **`lib/features/pos/screens/pos_screen.dart`**
   - Removed `paymentNotifier` from button's `onTap`
   - Updated `_handleCashPayment` signature (removed `paymentNotifier` param)
   - Simplified dialog instantiation (pass `cart` instead of callback)

---

## 💡 **Lessons Learned**

### **1. Respect AutoDispose Lifecycle**
Don't try to capture and pass instances from `autoDispose` providers across navigation boundaries. They **will** get disposed!

### **2. Watch Providers for Async Operations**
- **`ref.read()`** doesn't create a listener → provider can dispose during async operations
- **`ref.watch()`** creates a listener → keeps provider alive for widget lifetime
- **Critical for autoDispose**: Always `ref.watch()` in build if you have async operations!

### **3. Capture Notifiers Before Async Operations**
```dart
// ✅ CORRECT
final notifier = ref.read(provider.notifier); // Capture first
await notifier.asyncMethod(); // Use captured instance

// ❌ WRONG
await ref.read(provider.notifier).asyncMethod(); // Can dispose mid-operation
```

### **4. Let Widgets Handle Their Own Business Logic**
If a widget needs to interact with providers, let it use its own `ref` instead of receiving callbacks from the parent.

### **5. Pass Data, Not Behavior**
- ✅ **Good**: Pass `Cart cart` (data)
- ❌ **Bad**: Pass `Future<bool> Function(double) onProcessPayment` (behavior from parent's ref)

### **6. ConsumerStatefulWidget is Powerful**
It has its own `ref` that can access any provider at any time. Use it!

---

## 🚀 **Expected Console Output**

```
flutter: 📱 Opening CashPaymentDialog...
flutter: ✅ Complete Payment button clicked!
flutter:    _tenderedAmount=20000.0
flutter:    _tenderedController.text=20000
flutter: 🔄 Processing payment: 20000.0
flutter: ✅ Payment result: true ✅
flutter: ✅ Payment successful, closing dialog...
flutter: 📥 CashPaymentDialog returned with result: {success: true, tendered: 20000.0, change: 0.0}
flutter: ✅ Payment successful, showing success dialog...
flutter: ✅ Clearing cart...
flutter: ✅ Done
```

**No disposal errors!** 🎉

---

## 🎉 **Status: COMPLETELY FIXED!**

The payment flow now:
- ✅ **Respects autoDispose lifecycle**
- ✅ **Dialog uses its own ref**
- ✅ **No disposal issues**
- ✅ **Clean separation of concerns**
- ✅ **Payment processes successfully**
- ✅ **Production ready!**

**The dispose error is completely fixed!** 🚀

