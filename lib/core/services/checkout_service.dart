import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/cart.dart';
import 'inventory_service.dart';

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final inventoryService = ref.watch(inventoryServiceProvider);
  return CheckoutService(apiClient, inventoryService);
});

/// Checkout request models
class LineItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final List<dynamic>? options;

  LineItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    this.options,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };

    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes!;
    }

    if (options != null && options!.isNotEmpty) {
      json['options'] = options!;
    }

    // ✅ CRITICAL FIX: Force backend to generate fresh cost breakdown
    // This prevents stock-tracked items from using invalid calculationSource values
    // The backend will generate valid cost breakdown with proper enum values
    json['forceFreshCostBreakdown'] = true;

    // ✅ ADDITIONAL FIX: Explicitly prevent any cost breakdown contamination
    // Never send costBreakdown field to avoid invalid enum values like 'inventory_average_cost'
    json['skipStoredCostBreakdown'] = true;

    return json;
  }
}

/// Money amount object (matches API format)
class MoneyAmount {
  final double amount;
  final String currency;

  MoneyAmount({required this.amount, this.currency = 'LAK'});

  Map<String, dynamic> toJson() => {'amount': amount, 'currency': currency};

  factory MoneyAmount.fromJson(Map<String, dynamic> json) => MoneyAmount(
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? 'LAK',
  );
}

class PaymentMethod {
  final String method; // cash, card, bank_qr_jdb, etc.
  final MoneyAmount customerAmount; // ✅ Object: the amount being paid
  final MoneyAmount?
  tenderedAmount; // ✅ Object: for cash - amount customer gave
  final Map<String, dynamic>? paymentDetails;

  PaymentMethod({
    required this.method,
    required this.customerAmount,
    this.tenderedAmount, // Required for cash, optional for others
    this.paymentDetails,
  });

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
}

class CustomerInfo {
  final String? customerId;
  final String? name;
  final String? phone;

  CustomerInfo({this.customerId, this.name, this.phone});

  Map<String, dynamic> toJson() => {
    if (customerId != null) 'customerId': customerId,
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
  };
}

/// Checkout response models
class CheckoutPricing {
  final Map<String, dynamic> subtotal;
  final Map<String, dynamic> totalTax;
  final Map<String, dynamic> totalDiscount;
  final Map<String, dynamic> totalFees;
  final Map<String, dynamic> totalTip;
  final Map<String, dynamic> totalDue;
  final String currency;

  CheckoutPricing({
    required this.subtotal,
    required this.totalTax,
    required this.totalDiscount,
    required this.totalFees,
    required this.totalTip,
    required this.totalDue,
    required this.currency,
  });

  factory CheckoutPricing.fromJson(Map<String, dynamic> json) {
    return CheckoutPricing(
      subtotal: json['subtotal'] as Map<String, dynamic>? ?? {},
      totalTax: json['totalTax'] as Map<String, dynamic>? ?? {},
      totalDiscount: json['totalDiscount'] as Map<String, dynamic>? ?? {},
      totalFees: json['totalFees'] as Map<String, dynamic>? ?? {},
      totalTip: json['totalTip'] as Map<String, dynamic>? ?? {},
      totalDue: json['totalDue'] as Map<String, dynamic>? ?? {},
      currency: json['currency'] as String? ?? 'LAK',
    );
  }

  double get totalAmount => (totalDue['amount'] as num?)?.toDouble() ?? 0.0;
}

class CheckoutOrder {
  final String id;
  final String orderId;
  final String orderNumber;
  final String qNumber;
  final String orderType;
  final String orderStatus;
  final List<dynamic> lineItems;
  final Map<String, dynamic> pricing;
  final Map<String, dynamic>? customer;
  final String createdAt;

  CheckoutOrder({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.qNumber,
    required this.orderType,
    required this.orderStatus,
    required this.lineItems,
    required this.pricing,
    this.customer,
    required this.createdAt,
  });

  factory CheckoutOrder.fromJson(Map<String, dynamic> json) {
    // ✅ Handle qNumber being int or String from API
    String qNumberValue = '';
    if (json['qNumber'] != null) {
      if (json['qNumber'] is int) {
        qNumberValue = json['qNumber'].toString();
      } else if (json['qNumber'] is String) {
        qNumberValue = json['qNumber'] as String;
      }
    }

    return CheckoutOrder(
      id: json['_id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      qNumber: qNumberValue,
      orderType: json['orderType'] as String? ?? 'takeaway',
      orderStatus: json['orderStatus'] as String? ?? 'completed',
      lineItems: json['lineItems'] as List<dynamic>? ?? [],
      pricing: json['pricing'] as Map<String, dynamic>? ?? {},
      customer: json['customer'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class CheckoutTransaction {
  final String transactionId;
  final String transactionStatus;
  final Map<String, dynamic> paymentSummary;

  CheckoutTransaction({
    required this.transactionId,
    required this.transactionStatus,
    required this.paymentSummary,
  });

  factory CheckoutTransaction.fromJson(Map<String, dynamic> json) {
    return CheckoutTransaction(
      transactionId: json['transactionId'] as String? ?? '',
      transactionStatus: json['transactionStatus'] as String? ?? '',
      paymentSummary: json['paymentSummary'] as Map<String, dynamic>? ?? {},
    );
  }
}

class CheckoutResponse {
  final CheckoutOrder order;
  final CheckoutTransaction transaction;
  final CheckoutPricing pricing;
  final String message;

  CheckoutResponse({
    required this.order,
    required this.transaction,
    required this.pricing,
    required this.message,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      order: CheckoutOrder.fromJson(json['order'] as Map<String, dynamic>),
      transaction: CheckoutTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
      pricing: CheckoutPricing.fromJson(
        json['pricing'] as Map<String, dynamic>,
      ),
      message: json['message'] as String? ?? '',
    );
  }
}

/// Service for unified checkout operations
class CheckoutService {
  final ApiClient _apiClient;
  final InventoryService _inventoryService;

  CheckoutService(this._apiClient, this._inventoryService);

  /// Step 1: Calculate pricing (optional but recommended)
  Future<CheckoutPricing> calculatePricing({
    required List<LineItem> lineItems,
    String orderType = 'takeaway',
    List<dynamic>? promotions,
    CustomerInfo? customer,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.calculatePricing,
      data: {
        'lineItems': lineItems.map((item) => item.toJson()).toList(),
        'orderType': orderType,
        if (promotions != null && promotions.isNotEmpty)
          'promotions': promotions,
        if (customer != null) 'customer': customer.toJson(),
      },
    );

    return CheckoutPricing.fromJson(
      response['data']['pricing'] as Map<String, dynamic>,
    );
  }

  /// Step 2: Process payment (UNIFIED ENDPOINT - Creates Order + Processes Payment)
  Future<CheckoutResponse> processPayment({
    required List<LineItem> lineItems,
    required List<PaymentMethod> payments,
    required double expectedTotal,
    CustomerInfo? customer,
    List<dynamic>? promotions,
    String? notes,
    String? idempotencyKey,
  }) async {
    print('🏪 CheckoutService.processPayment called');
    print('   Line items: ${lineItems.length}');
    print('   Payments: ${payments.length}');
    print('   Expected total: $expectedTotal');

    // Generate idempotency key if not provided
    final key =
        idempotencyKey ?? 'checkout-${DateTime.now().millisecondsSinceEpoch}';

    // ✅ CRITICAL FIX: Ensure line items are completely clean
    final cleanLineItems =
        lineItems
            .map(
              (item) => {
                'menuItemId': item.menuItemId,
                'name': item.name,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'subtotal': item.subtotal,
                if (item.notes != null && item.notes!.isNotEmpty)
                  'notes': item.notes,
                if (item.options != null && item.options!.isNotEmpty)
                  'options': item.options,
                // ✅ CRITICAL: Force fresh cost breakdown generation for ALL items
                'forceFreshCostBreakdown': true,
                // ✅ ADDITIONAL: Skip any stored cost breakdown to prevent contamination
                'skipStoredCostBreakdown': true,
              },
            )
            .toList();

    print('📤 Making API call to ${ApiConstants.processPayment}');
    final response = await _apiClient.post(
      ApiConstants.processPayment,
      data: {
        'lineItems': cleanLineItems,
        'payments': payments.map((p) => p.toJson()).toList(),
        'expectedTotal': expectedTotal,
        if (customer != null) 'customer': customer.toJson(),
        if (promotions != null && promotions.isNotEmpty)
          'promotions': promotions,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'idempotencyKey': key,
      },
    );

    print('📥 API response received');
    print('   Response keys: ${response.keys.toList()}');
    print('   Has data key: ${response.containsKey('data')}');

    if (response['data'] != null) {
      print('   Data type: ${response['data'].runtimeType}');
      if (response['data'] is Map) {
        print('   Data keys: ${(response['data'] as Map).keys.toList()}');
      }
    }

    print('🔄 Parsing CheckoutResponse...');
    final checkoutResponse = CheckoutResponse.fromJson(
      response['data'] as Map<String, dynamic>,
    );
    print('✅ CheckoutResponse parsed successfully');
    print('   Order ID: ${checkoutResponse.order.orderId}');
    print('   Transaction ID: ${checkoutResponse.transaction.transactionId}');

    // ✅ STOCK DEDUCTION: Process stock deduction after successful payment
    try {
      print('📦 Processing stock deduction for successful payment...');
      print('📊 Order ID: ${checkoutResponse.order.orderId}');
      print('📊 Line items to deduct: ${lineItems.length}');

      for (final item in lineItems) {
        print('   - ${item.name} (${item.menuItemId}): ${item.quantity} units');
      }

      await _processStockDeduction(
        orderId: checkoutResponse.order.orderId,
        lineItems: lineItems,
      );
      print('✅ Stock deduction completed successfully');
      print('📊 Stock levels should now be updated in inventory');
    } catch (e) {
      print('⚠️ Stock deduction failed (order still successful): $e');
      print('📋 Stack trace: ${StackTrace.current}');
      // Don't fail the entire transaction if stock deduction fails
      // The order is already processed successfully
    }

    return checkoutResponse;
  }

  /// Helper: Process cash payment from Cart
  Future<CheckoutResponse> processCashPaymentFromCart({
    required Cart cart,
    required double tenderedAmount,
    String? notes,
  }) async {
    print('💳 CheckoutService.processCashPaymentFromCart called');
    print('   Cart total: ${cart.total}');
    print('   Tendered amount: $tenderedAmount');
    print('   Cart items: ${cart.items.length}');

    // ✅ VALIDATION: Only allow payment for items WITH inventory tracking
    print('🔍 Validating inventory tracking for all cart items...');
    for (final item in cart.items) {
      // Check if item has inventory tracking by verifying if it exists in inventory service
      final hasInventoryTracking = await _inventoryService.hasInventoryTracking(
        item.productId,
      );
      print(
        '   📦 ${item.productName} (${item.productId}): hasInventoryTracking=${hasInventoryTracking}',
      );

      if (!hasInventoryTracking) {
        print(
          '❌ Payment blocked: ${item.productName} does not have inventory tracking enabled',
        );
        print(
          '   Only items with inventory tracking can be processed for payment',
        );
        throw Exception(
          'Payment not allowed: ${item.productName} requires inventory tracking to be enabled for payment processing. Please enable inventory tracking for this item or remove it from cart.',
        );
      }
    }
    print('✅ All items have inventory tracking enabled - payment allowed');

    // ✅ STOCK VALIDATION: Check if there's enough stock before payment
    print('📦 Validating stock availability...');
    final cartItemsForValidation =
        cart.items
            .map(
              (item) => {
                'menuItemId': item.productId,
                'name': item.productName,
                'quantity': item.quantity,
              },
            )
            .toList();

    await _inventoryService.validateStockAvailability(cartItemsForValidation);
    print('✅ Stock validation passed - sufficient stock available');

    // Transform cart items to LineItems - let backend generate costBreakdown
    final lineItems =
        cart.items
            .map(
              (item) => LineItem(
                menuItemId: item.productId,
                name: item.productName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                subtotal: item.subtotal,
                notes: item.notes,
                options: [],
                // ✅ No costBreakdown - let backend generate it with correct enum values
              ),
            )
            .toList();

    print('✅ Line items created: ${lineItems.length}');

    // ✅ Create payment method with correct API format
    final payment = PaymentMethod(
      method: 'cash',
      customerAmount: MoneyAmount(amount: cart.total, currency: 'LAK'),
      tenderedAmount: MoneyAmount(amount: tenderedAmount, currency: 'LAK'),
    );

    print('✅ Payment method created: cash');
    print('   Customer amount: ${cart.total} LAK');
    print('   Tendered amount: $tenderedAmount LAK');

    // Create customer info if available
    CustomerInfo? customerInfo;
    if (cart.customer != null) {
      customerInfo = CustomerInfo(
        customerId: cart.customer!.id,
        name: cart.customer!.name,
        phone: cart.customer!.phone,
      );
      print('✅ Customer info created: ${cart.customer!.name}');
    } else {
      print('ℹ️  No customer info in cart');
    }

    print('🔄 Calling processPayment...');
    // Process payment
    final result = await processPayment(
      lineItems: lineItems,
      payments: [payment],
      expectedTotal: cart.total,
      customer: customerInfo,
      promotions: [],
      notes: notes ?? cart.notes,
    );

    print('✅ processCashPaymentFromCart completed successfully');
    return result;
  }

  /// Helper: Process PhayPay payment from Cart
  Future<CheckoutResponse> processPhayPayPaymentFromCart({
    required Cart cart,
    required String bankMethod,
    Map<String, dynamic>? paymentDetails,
    String? notes,
  }) async {
    // ✅ VALIDATION: Only allow payment for items WITH inventory tracking
    print('🔍 Validating inventory tracking for PhayPay payment...');
    for (final item in cart.items) {
      // Check if item has inventory tracking by verifying if it exists in inventory service
      final hasInventoryTracking = await _inventoryService.hasInventoryTracking(
        item.productId,
      );
      print(
        '   📦 ${item.productName} (${item.productId}): hasInventoryTracking=${hasInventoryTracking}',
      );

      if (!hasInventoryTracking) {
        print(
          '❌ PhayPay payment blocked: ${item.productName} does not have inventory tracking enabled',
        );
        throw Exception(
          'Payment not allowed: ${item.productName} requires inventory tracking to be enabled for payment processing. Please enable inventory tracking for this item or remove it from cart.',
        );
      }
    }
    print(
      '✅ All items have inventory tracking enabled - PhayPay payment allowed',
    );

    // ✅ STOCK VALIDATION: Check if there's enough stock before PhayPay payment
    print('📦 Validating stock availability for PhayPay payment...');
    final phayPayCartItems =
        cart.items
            .map(
              (item) => {
                'menuItemId': item.productId,
                'name': item.productName,
                'quantity': item.quantity,
              },
            )
            .toList();

    await _inventoryService.validateStockAvailability(phayPayCartItems);
    print('✅ PhayPay stock validation passed - sufficient stock available');

    // Transform cart items to LineItems - let backend generate costBreakdown
    final lineItems =
        cart.items
            .map(
              (item) => LineItem(
                menuItemId: item.productId,
                name: item.productName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                subtotal: item.subtotal,
                notes: item.notes,
                options: [],
                // ✅ No costBreakdown - let backend generate it with correct enum values
              ),
            )
            .toList();

    // ✅ Create payment method with correct API format
    // For QR payments: only customerAmount is required (no tenderedAmount)
    final payment = PaymentMethod(
      method: bankMethod,
      customerAmount: MoneyAmount(amount: cart.total, currency: 'LAK'),
      // No tenderedAmount for QR payments (customer pays exact amount)
      paymentDetails: paymentDetails,
    );

    // Create customer info if available
    CustomerInfo? customerInfo;
    if (cart.customer != null) {
      customerInfo = CustomerInfo(
        customerId: cart.customer!.id,
        name: cart.customer!.name,
        phone: cart.customer!.phone,
      );
    }

    // Process payment
    return await processPayment(
      lineItems: lineItems,
      payments: [payment],
      expectedTotal: cart.total,
      customer: customerInfo,
      promotions: [],
      notes: notes ?? cart.notes,
    );
  }

  /// Helper: Save order as pending/hold status from Cart
  Future<CheckoutResponse> saveOrderAsPending({
    required Cart cart,
    String? notes,
  }) async {
    print('💾 CheckoutService.saveOrderAsPending called');
    print('   Cart items: ${cart.items.length}');
    print('   Total: ${cart.total}');

    // ✅ VALIDATION: Only allow pending orders for items WITH inventory tracking
    print('🔍 Validating inventory tracking for pending order...');
    for (final item in cart.items) {
      // Check if item has inventory tracking by verifying if it exists in inventory service
      final hasInventoryTracking = await _inventoryService.hasInventoryTracking(
        item.productId,
      );
      print(
        '   📦 ${item.productName} (${item.productId}): hasInventoryTracking=${hasInventoryTracking}',
      );

      if (!hasInventoryTracking) {
        print(
          '❌ Pending order blocked: ${item.productName} does not have inventory tracking enabled',
        );
        throw Exception(
          'Order not allowed: ${item.productName} requires inventory tracking to be enabled for order processing. Please enable inventory tracking for this item or remove it from cart.',
        );
      }
    }
    print(
      '✅ All items have inventory tracking enabled - pending order allowed',
    );

    // ✅ STOCK VALIDATION: Check if there's enough stock before creating pending order
    print('📦 Validating stock availability for pending order...');
    final pendingOrderItems =
        cart.items
            .map(
              (item) => {
                'menuItemId': item.productId,
                'name': item.productName,
                'quantity': item.quantity,
              },
            )
            .toList();

    await _inventoryService.validateStockAvailability(pendingOrderItems);
    print(
      '✅ Pending order stock validation passed - sufficient stock available',
    );

    // Transform cart items to LineItems - let backend generate costBreakdown
    final lineItems =
        cart.items
            .map(
              (item) => LineItem(
                menuItemId: item.productId,
                name: item.productName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                subtotal: item.subtotal,
                notes: item.notes,
                options: [],
                // ✅ No costBreakdown - let backend generate it with correct enum values
              ),
            )
            .toList();

    // Create customer info if available
    CustomerInfo? customerInfo;
    if (cart.customer != null) {
      customerInfo = CustomerInfo(
        customerId: cart.customer!.id,
        name: cart.customer!.name,
        phone: cart.customer!.phone,
      );
    }

    // Save as pending order without payment
    return await savePendingOrder(
      lineItems: lineItems,
      expectedTotal: cart.total,
      customer: customerInfo,
      promotions: [],
      notes: notes ?? cart.notes,
    );
  }

  /// Save pending order (without payment processing)
  Future<CheckoutResponse> savePendingOrder({
    required List<LineItem> lineItems,
    required double expectedTotal,
    CustomerInfo? customer,
    List<dynamic>? promotions,
    String? notes,
  }) async {
    print('📤 Saving pending order to API...');

    final requestBody = {
      'orderType': 'dine_in',
      'status': 'pending', // Set status as pending
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'totalAmount': {'amount': expectedTotal, 'currency': 'LAK'},
      if (customer != null) 'customer': customer.toJson(),
      if (promotions != null && promotions.isNotEmpty) 'promotions': promotions,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'createdAt': DateTime.now().toIso8601String(),
    };

    print('📋 Request body: $requestBody');

    try {
      // Use createOrder endpoint for creating pending orders
      final response = await _apiClient.post(
        ApiConstants.createOrder,
        data: requestBody,
      );

      print('📥 API Response status: ${response['status'] ?? 'unknown'}');
      print('📋 API Response body: $response');

      // For pending orders, create a simplified CheckoutResponse
      final orderData = response['data'] ?? response;
      final result = CheckoutResponse(
        order: CheckoutOrder(
          id:
              orderData['_id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          orderId:
              orderData['_id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          orderNumber:
              orderData['orderNumber']?.toString() ??
              'ORD-${DateTime.now().millisecondsSinceEpoch}',
          qNumber: orderData['qNumber']?.toString() ?? '0',
          orderType: 'dine_in',
          orderStatus: 'pending',
          lineItems: lineItems.map((item) => item.toJson()).toList(),
          pricing: {
            'subtotal': {'amount': expectedTotal, 'currency': 'LAK'},
            'totalDue': {'amount': expectedTotal, 'currency': 'LAK'},
          },
          customer: customer?.toJson(),
          createdAt: DateTime.now().toIso8601String(),
        ),
        transaction: CheckoutTransaction(
          transactionId: 'pending-${DateTime.now().millisecondsSinceEpoch}',
          transactionStatus: 'pending',
          paymentSummary: {},
        ),
        pricing: CheckoutPricing(
          subtotal: {'amount': expectedTotal, 'currency': 'LAK'},
          totalTax: {'amount': 0.0, 'currency': 'LAK'},
          totalDiscount: {'amount': 0.0, 'currency': 'LAK'},
          totalFees: {'amount': 0.0, 'currency': 'LAK'},
          totalTip: {'amount': 0.0, 'currency': 'LAK'},
          totalDue: {'amount': expectedTotal, 'currency': 'LAK'},
          currency: 'LAK',
        ),
        message: 'Order saved as pending successfully',
      );

      print('✅ savePendingOrder completed successfully');
      return result;
    } catch (e) {
      print('❌ createOrder endpoint failed: $e');
      print('🔄 Trying alternative approach with checkout system...');

      // Alternative approach: Use checkout system but with no payments to create pending order
      try {
        final alternativeBody = {
          'lineItems': lineItems.map((item) => item.toJson()).toList(),
          'payments': [], // Empty payments array for pending order
          'expectedTotal': expectedTotal,
          'orderType': 'dine_in',
          'orderStatus': 'pending', // Use orderStatus for checkout system
          if (customer != null) 'customer': customer.toJson(),
          if (promotions != null && promotions.isNotEmpty)
            'promotions': promotions,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'idempotencyKey': 'pending-${DateTime.now().millisecondsSinceEpoch}',
        };

        print('📋 Alternative request body: $alternativeBody');

        final response = await _apiClient.post(
          ApiConstants.processPayment,
          data: alternativeBody,
        );

        print('📥 Alternative API Response: $response');

        // Parse the checkout response
        final result = CheckoutResponse.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        print('✅ savePendingOrder completed via alternative approach');
        return result;
      } catch (alternativeError) {
        print('❌ Alternative approach also failed: $alternativeError');
        print(
          '💡 Suggestion: Check if your backend supports order creation endpoints',
        );
        rethrow;
      }
    }
  }

  /// Private method to process stock deduction after successful payment
  Future<void> _processStockDeduction({
    required String orderId,
    required List<LineItem> lineItems,
  }) async {
    try {
      // Convert LineItems to the format expected by inventory service
      final orderItems =
          lineItems
              .map(
                (item) => {
                  'menuItemId': item.menuItemId,
                  'name': item.name,
                  'quantity': item.quantity,
                },
              )
              .toList();

      await _inventoryService.deductStockForOrder(
        orderId: orderId,
        orderItems: orderItems,
      );
    } catch (e) {
      print('❌ Stock deduction error in checkout: $e');
      rethrow;
    }
  }
}
