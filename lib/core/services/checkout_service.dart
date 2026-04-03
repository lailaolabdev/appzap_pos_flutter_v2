import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/cart.dart';

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CheckoutService(apiClient);
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

  CheckoutService(this._apiClient);

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
              },
            )
            .toList();

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


    final checkoutResponse = CheckoutResponse.fromJson(
      response['data'] as Map<String, dynamic>,
    );

    // NOTE: Backend handles stock deduction inside the checkout transaction.
    // No need for client-side stock deduction.

    return checkoutResponse;
  }

  /// Helper: Process cash payment from Cart
  Future<CheckoutResponse> processCashPaymentFromCart({
    required Cart cart,
    required double tenderedAmount,
    String? notes,
  }) async {
    // NOTE: Backend handles all validation (inventory tracking, stock availability,
    // order creation, payment processing, stock deduction) in one transaction.
    // No need for redundant client-side checks — just send the request.

    // Transform cart items to LineItems
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
    final payment = PaymentMethod(
      method: 'cash',
      customerAmount: MoneyAmount(amount: cart.total, currency: 'LAK'),
      tenderedAmount: MoneyAmount(amount: tenderedAmount, currency: 'LAK'),
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
    final result = await processPayment(
      lineItems: lineItems,
      payments: [payment],
      expectedTotal: cart.total,
      customer: customerInfo,
      promotions: [],
      notes: notes ?? cart.notes,
    );

    return result;
  }

  /// Helper: Process PhayPay payment from Cart
  Future<CheckoutResponse> processPhayPayPaymentFromCart({
    required Cart cart,
    required String bankMethod,
    Map<String, dynamic>? paymentDetails,
    String? notes,
  }) async {
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

    final requestBody = {
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'holdReason': 'customer_request',
      if (customer != null) 'customer': customer.toJson(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      final response = await _apiClient.post(
        '${ApiConstants.createOrder}/on-hold',
        data: requestBody,
      );


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

      return result;
    } catch (e) {

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


        final response = await _apiClient.post(
          ApiConstants.processPayment,
          data: alternativeBody,
        );


        // Parse the checkout response
        final result = CheckoutResponse.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        return result;
      } catch (alternativeError) {
        rethrow;
      }
    }
  }

  /// Private method to process stock deduction after successful payment
}
