import 'package:equatable/equatable.dart';

/// Transaction Model
class Transaction extends Equatable {
  final String id;
  final String transactionId;
  final String? receiptId;
  final String transactionType;
  final String transactionStatus;
  final String? restaurantId;
  final String? branchId;
  final ConsolidatedTotals consolidatedTotals;
  final List<Payment> payments;
  final List<TransactionLineItem> lineItems;
  final PaymentSummary? paymentSummary;
  final TransactionStaff? staff;
  final TransactionCustomer? customer;
  final TransactionTableInfo? tableInfo;
  final TransactionTiming timing;
  final bool countInTotals;
  final int? qNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.transactionId,
    this.receiptId,
    required this.transactionType,
    required this.transactionStatus,
    this.restaurantId,
    this.branchId,
    required this.consolidatedTotals,
    required this.payments,
    required this.lineItems,
    this.paymentSummary,
    this.staff,
    this.customer,
    this.tableInfo,
    required this.timing,
    required this.countInTotals,
    this.qNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
      receiptId: json['receiptId'] as String?,
      transactionType: json['transactionType'] as String? ?? 'sale',
      transactionStatus: json['transactionStatus'] as String? ?? 'pending',
      restaurantId: json['restaurantId'] as String?,
      branchId: json['branchId'] as String?,
      consolidatedTotals: ConsolidatedTotals.fromJson(
        json['consolidatedTotals'] as Map<String, dynamic>? ?? {},
      ),
      payments:
          (json['payments'] as List<dynamic>?)
              ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lineItems:
          (json['lineItems'] as List<dynamic>?)
              ?.map(
                (e) => TransactionLineItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      paymentSummary:
          json['paymentSummary'] != null
              ? PaymentSummary.fromJson(
                json['paymentSummary'] as Map<String, dynamic>,
              )
              : null,
      staff:
          json['staff'] != null
              ? TransactionStaff.fromJson(json['staff'] as Map<String, dynamic>)
              : null,
      customer:
          json['customer'] != null
              ? TransactionCustomer.fromJson(
                json['customer'] as Map<String, dynamic>,
              )
              : null,
      tableInfo:
          json['tableInfo'] != null
              ? TransactionTableInfo.fromJson(
                json['tableInfo'] as Map<String, dynamic>,
              )
              : null,
      timing: TransactionTiming.fromJson(
        json['timing'] as Map<String, dynamic>? ?? {},
      ),
      countInTotals: json['countInTotals'] as bool? ?? true,
      qNumber: _parseQNumber(json),
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  /// Short display ID: "ORD-bbd95ced-..." → "ORD-bbd9"
  String get shortId {
    final parts = transactionId.split('-');
    if (parts.length >= 2) {
      return '${parts[0]}-${parts[1].substring(0, parts[1].length.clamp(0, 4))}';
    }
    return transactionId.length > 8
        ? transactionId.substring(0, 8)
        : transactionId;
  }

  /// Parse qNumber from orderReference.orderId.qNumber or root level
  static int? _parseQNumber(Map<String, dynamic> json) {
    // Direct field
    if (json['qNumber'] is num) return (json['qNumber'] as num).toInt();
    // Nested in orderReference.orderId
    final orderRef = json['orderReference'];
    if (orderRef is Map<String, dynamic>) {
      final order = orderRef['orderId'];
      if (order is Map<String, dynamic> && order['qNumber'] is num) {
        return (order['qNumber'] as num).toInt();
      }
    }
    return null;
  }

  bool get isCompleted => transactionStatus == 'completed';
  bool get isPending => transactionStatus == 'pending';
  bool get isVoided => transactionStatus == 'voided';
  bool get isRefunded =>
      transactionStatus == 'refunded' ||
      transactionStatus == 'partially_refunded';

  @override
  List<Object?> get props => [
    id,
    transactionId,
    transactionStatus,
    consolidatedTotals,
    timing,
  ];
}

/// Consolidated Totals
class ConsolidatedTotals extends Equatable {
  final MoneyAmount subtotal;
  final MoneyAmount tax;
  final MoneyAmount discounts;
  final MoneyAmount serviceCharge;
  final MoneyAmount grandTotal;

  const ConsolidatedTotals({
    required this.subtotal,
    required this.tax,
    required this.discounts,
    required this.serviceCharge,
    required this.grandTotal,
  });

  factory ConsolidatedTotals.fromJson(Map<String, dynamic> json) {
    return ConsolidatedTotals(
      subtotal: MoneyAmount.fromJson(
        json['subtotal'] as Map<String, dynamic>? ?? {},
      ),
      tax: MoneyAmount.fromJson(json['tax'] as Map<String, dynamic>? ?? {}),
      discounts: MoneyAmount.fromJson(
        json['discounts'] as Map<String, dynamic>? ?? {},
      ),
      serviceCharge: MoneyAmount.fromJson(
        json['serviceCharge'] as Map<String, dynamic>? ?? {},
      ),
      grandTotal: MoneyAmount.fromJson(
        json['grandTotal'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  @override
  List<Object?> get props => [
    subtotal,
    tax,
    discounts,
    serviceCharge,
    grandTotal,
  ];
}

/// Money Amount
class MoneyAmount extends Equatable {
  final double amount;
  final String currency;

  const MoneyAmount({required this.amount, required this.currency});

  factory MoneyAmount.fromJson(Map<String, dynamic> json) {
    return MoneyAmount(
      amount: _extractAmountValue(json['amount']),
      currency: json['currency'] as String? ?? 'LAK',
    );
  }

  /// Helper method to extract amount value from API response
  /// Handles both direct numbers and {amount: number, currency: string} objects
  static double _extractAmountValue(dynamic value) {
    if (value == null) return 0.0;

    // If it's already a number, return it
    if (value is num) return value.toDouble();

    // If it's a Map with 'amount' field, extract the amount
    if (value is Map<String, dynamic> && value.containsKey('amount')) {
      final amount = value['amount'];
      if (amount is num) return amount.toDouble();
    }

    // Fallback: try to parse as string or return 0
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  @override
  List<Object?> get props => [amount, currency];
}

/// Payment
class Payment extends Equatable {
  final String method;
  final MoneyAmount grossAmount;
  final MoneyAmount? changeAmount;
  final DateTime? processedAt;
  final String? processedBy;

  const Payment({
    required this.method,
    required this.grossAmount,
    this.changeAmount,
    this.processedAt,
    this.processedBy,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      method: json['method'] as String? ?? 'cash',
      grossAmount: MoneyAmount.fromJson(
        json['grossAmount'] as Map<String, dynamic>? ?? {},
      ),
      changeAmount:
          json['changeAmount'] != null
              ? MoneyAmount.fromJson(
                json['changeAmount'] as Map<String, dynamic>,
              )
              : null,
      processedAt:
          json['processedAt'] != null
              ? DateTime.parse(json['processedAt'] as String)
              : null,
      processedBy: json['processedBy'] as String?,
    );
  }

  @override
  List<Object?> get props => [method, grossAmount, processedAt];
}

/// Transaction Line Item
class TransactionLineItem extends Equatable {
  final String itemType;
  final String? menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double tax;
  final double total;
  final List<LineItemOption> options;

  const TransactionLineItem({
    required this.itemType,
    this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.options = const [],
  });

  factory TransactionLineItem.fromJson(Map<String, dynamic> json) {
    return TransactionLineItem(
      itemType: json['itemType'] as String? ?? 'menu_item',
      menuItemId: json['menuItemId'] as String?,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: MoneyAmount._extractAmountValue(json['unitPrice']),
      subtotal: MoneyAmount._extractAmountValue(json['subtotal']),
      tax: MoneyAmount._extractAmountValue(json['tax']),
      total: MoneyAmount._extractAmountValue(json['total']),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => LineItemOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Summary of selected options for display
  String get optionsSummary {
    if (options.isEmpty) return '';
    return options.map((o) => o.name).join(', ');
  }

  @override
  List<Object?> get props => [menuItemId, name, quantity, total, options];
}

/// Option selected on a line item
class LineItemOption extends Equatable {
  final String? customizationId;
  final String? customizationName;
  final String? optionId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const LineItemOption({
    this.customizationId,
    this.customizationName,
    this.optionId,
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0,
    this.totalPrice = 0,
  });

  factory LineItemOption.fromJson(Map<String, dynamic> json) {
    return LineItemOption(
      customizationId: json['customizationId']?.toString(),
      customizationName: json['customizationName'] as String?,
      optionId: json['optionId']?.toString(),
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: MoneyAmount._extractAmountValue(json['unitPrice']),
      totalPrice: MoneyAmount._extractAmountValue(json['totalPrice']),
    );
  }

  @override
  List<Object?> get props => [optionId, name, unitPrice];
}

/// Payment Summary
class PaymentSummary extends Equatable {
  final double totalPaid;
  final List<PaymentMethodBreakdown> paymentMethodBreakdown;

  const PaymentSummary({
    required this.totalPaid,
    required this.paymentMethodBreakdown,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalPaid: MoneyAmount._extractAmountValue(json['totalPaid']),
      paymentMethodBreakdown:
          (json['paymentMethodBreakdown'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PaymentMethodBreakdown.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [totalPaid, paymentMethodBreakdown];
}

/// Payment Method Breakdown
class PaymentMethodBreakdown extends Equatable {
  final String method;
  final double amount;
  final String currency;

  const PaymentMethodBreakdown({
    required this.method,
    required this.amount,
    required this.currency,
  });

  factory PaymentMethodBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentMethodBreakdown(
      method: json['method'] as String? ?? '',
      amount: MoneyAmount._extractAmountValue(json['amount']),
      currency: json['currency'] as String? ?? 'LAK',
    );
  }

  @override
  List<Object?> get props => [method, amount];
}

/// Transaction Staff
class TransactionStaff extends Equatable {
  final StaffMember? processedBy;

  const TransactionStaff({this.processedBy});

  factory TransactionStaff.fromJson(Map<String, dynamic> json) {
    return TransactionStaff(
      processedBy:
          json['processedBy'] != null
              ? StaffMember.fromJson(
                json['processedBy'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  @override
  List<Object?> get props => [processedBy];
}

/// Staff Member
class StaffMember extends Equatable {
  final String id;
  final String name;
  final String? role;

  const StaffMember({required this.id, required this.name, this.role});

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// Transaction Customer
class TransactionCustomer extends Equatable {
  final String? customerId;
  final String? name;
  final String? phone;

  const TransactionCustomer({this.customerId, this.name, this.phone});

  factory TransactionCustomer.fromJson(Map<String, dynamic> json) {
    return TransactionCustomer(
      customerId: json['customerId'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
    );
  }

  @override
  List<Object?> get props => [customerId, name];
}

/// Transaction Table Info
class TransactionTableInfo extends Equatable {
  final String? tableNumber;
  final String? zoneName;
  final String? tableSessionId;

  const TransactionTableInfo({
    this.tableNumber,
    this.zoneName,
    this.tableSessionId,
  });

  factory TransactionTableInfo.fromJson(Map<String, dynamic> json) {
    return TransactionTableInfo(
      tableNumber: json['tableNumber'] as String?,
      zoneName: json['zoneName'] as String?,
      tableSessionId: json['tableSessionId'] as String?,
    );
  }

  @override
  List<Object?> get props => [tableNumber, zoneName];
}

/// Transaction Timing
class TransactionTiming extends Equatable {
  final DateTime? initiatedAt;
  final DateTime? completedAt;

  const TransactionTiming({this.initiatedAt, this.completedAt});

  factory TransactionTiming.fromJson(Map<String, dynamic> json) {
    return TransactionTiming(
      initiatedAt:
          json['initiatedAt'] != null
              ? DateTime.parse(json['initiatedAt'] as String)
              : null,
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
    );
  }

  @override
  List<Object?> get props => [initiatedAt, completedAt];
}

/// Transaction Summary (for list view)
class TransactionSummary extends Equatable {
  final int totalTxnCount;
  final int salesCount;
  final int voidCount;
  final double salesAmount;
  final double voidAmount;
  final List<PaymentMethodBreakdown> paymentMethodBreakdown;

  const TransactionSummary({
    required this.totalTxnCount,
    required this.salesCount,
    required this.voidCount,
    required this.salesAmount,
    required this.voidAmount,
    required this.paymentMethodBreakdown,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalTxnCount: json['totalTxnCount'] as int? ?? 0,
      salesCount: json['salesCount'] as int? ?? 0,
      voidCount: json['voidCount'] as int? ?? 0,
      salesAmount: MoneyAmount._extractAmountValue(json['salesAmount']),
      voidAmount: MoneyAmount._extractAmountValue(json['voidAmount']),
      paymentMethodBreakdown:
          (json['paymentMethodBreakdown'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PaymentMethodBreakdown.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    totalTxnCount,
    salesCount,
    voidCount,
    salesAmount,
    voidAmount,
  ];
}

/// Pagination
class PaginationInfo extends Equatable {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [page, totalCount, totalPages];
}

/// Refund Result
class RefundResult extends Equatable {
  final String transactionId;
  final String refundTransactionId;
  final double refundAmount;
  final String refundMethod;
  final String status;
  final DateTime refundedAt;
  final StaffMember? refundedBy;
  final String reason;

  const RefundResult({
    required this.transactionId,
    required this.refundTransactionId,
    required this.refundAmount,
    required this.refundMethod,
    required this.status,
    required this.refundedAt,
    this.refundedBy,
    required this.reason,
  });

  factory RefundResult.fromJson(Map<String, dynamic> json) {
    return RefundResult(
      transactionId: json['transactionId'] as String? ?? '',
      refundTransactionId: json['refundTransactionId'] as String? ?? '',
      refundAmount: MoneyAmount._extractAmountValue(json['refundAmount']),
      refundMethod: json['refundMethod'] as String? ?? '',
      status: json['status'] as String? ?? '',
      refundedAt:
          json['refundedAt'] != null
              ? DateTime.parse(json['refundedAt'] as String)
              : DateTime.now(),
      refundedBy:
          json['refundedBy'] != null
              ? StaffMember.fromJson(json['refundedBy'] as Map<String, dynamic>)
              : null,
      reason: json['reason'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [transactionId, refundTransactionId, status];
}

/// Void Result
class VoidResult extends Equatable {
  final String transactionId;
  final String status;
  final DateTime voidedAt;
  final StaffMember? voidedBy;
  final String reason;

  const VoidResult({
    required this.transactionId,
    required this.status,
    required this.voidedAt,
    this.voidedBy,
    required this.reason,
  });

  factory VoidResult.fromJson(Map<String, dynamic> json) {
    return VoidResult(
      transactionId: json['transactionId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      voidedAt:
          json['voidedAt'] != null
              ? DateTime.parse(json['voidedAt'] as String)
              : DateTime.now(),
      voidedBy:
          json['voidedBy'] != null
              ? StaffMember.fromJson(json['voidedBy'] as Map<String, dynamic>)
              : null,
      reason: json['reason'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [transactionId, status];
}
