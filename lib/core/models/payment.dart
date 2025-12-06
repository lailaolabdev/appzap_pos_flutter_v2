import 'package:equatable/equatable.dart';

/// Payment method enum
enum PaymentMethod {
  cash,
  card,
  phayPay;

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'card':
        return PaymentMethod.card;
      case 'phaypay':
      case 'phajay':
        return PaymentMethod.phayPay;
      default:
        return PaymentMethod.cash;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.phayPay:
        return 'PhayPay';
    }
  }
}

/// PhayPay bank methods
enum PhayPayBankMethod {
  jdb('bank_qr_jdb', 'Joint Development Bank'),
  bcel('bank_qr_bcel', 'BCEL'),
  ib('bank_qr_ib', 'Indochina Bank'),
  ldb('bank_qr_ldb', 'Lao Development Bank'),
  paymentLink('payment_link', 'Payment Link');

  final String code;
  final String displayName;

  const PhayPayBankMethod(this.code, this.displayName);

  static PhayPayBankMethod fromCode(String code) {
    return PhayPayBankMethod.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PhayPayBankMethod.paymentLink,
    );
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  completed,
  failed,
  expired;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Payment result model
class PaymentResult extends Equatable {
  final String transactionId;
  final String paymentId;
  final String orderId;
  final PaymentStatus status;
  final PaymentMethod paymentMethod;
  final PaymentAmount amount;
  final DateTime? completedAt;

  const PaymentResult({
    required this.transactionId,
    required this.paymentId,
    required this.orderId,
    required this.status,
    required this.paymentMethod,
    required this.amount,
    this.completedAt,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      transactionId: json['transactionId'] as String? ?? '',
      paymentId: json['paymentId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      paymentMethod: PaymentMethod.fromString(
        json['paymentMethod'] as String? ?? 'cash',
      ),
      amount: PaymentAmount.fromJson(
        json['amount'] as Map<String, dynamic>? ?? {},
      ),
      completedAt:
          json['completedAt'] != null
              ? DateTime.tryParse(json['completedAt'] as String)
              : null,
    );
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isExpired => status == PaymentStatus.expired;

  @override
  List<Object?> get props => [
    transactionId,
    paymentId,
    orderId,
    status,
    paymentMethod,
    amount,
    completedAt,
  ];
}

/// Payment amount model
class PaymentAmount extends Equatable {
  final double total;
  final double tendered;
  final double change;
  final String currency;

  const PaymentAmount({
    required this.total,
    this.tendered = 0,
    this.change = 0,
    this.currency = 'LAK',
  });

  factory PaymentAmount.fromJson(Map<String, dynamic> json) {
    return PaymentAmount(
      total: (json['total'] as num?)?.toDouble() ?? 0,
      tendered: (json['tendered'] as num?)?.toDouble() ?? 0,
      change: (json['change'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'LAK',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'tendered': tendered,
      'change': change,
      'currency': currency,
    };
  }

  @override
  List<Object?> get props => [total, tendered, change, currency];
}

/// PhayPay payment model
class PhayPayPayment extends Equatable {
  final String paymentId;
  final String orderId;
  final String qrCode;
  final String? qrCodeUrl;
  final String? paymentLink;
  final double amount;
  final String currency;
  final PhayPayBankMethod bankMethod;
  final PaymentStatus status;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const PhayPayPayment({
    required this.paymentId,
    required this.orderId,
    required this.qrCode,
    this.qrCodeUrl,
    this.paymentLink,
    required this.amount,
    this.currency = 'LAK',
    required this.bankMethod,
    required this.status,
    this.expiresAt,
    required this.createdAt,
  });

  factory PhayPayPayment.fromJson(Map<String, dynamic> json) {
    return PhayPayPayment(
      paymentId: json['paymentId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      qrCode: json['qrCode'] as String? ?? '',
      qrCodeUrl: json['qrCodeUrl'] as String?,
      paymentLink: json['paymentLink'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'LAK',
      bankMethod: PhayPayBankMethod.fromCode(
        json['bankMethod'] as String? ?? '',
      ),
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      expiresAt:
          json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'] as String)
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isExpired {
    if (status == PaymentStatus.expired) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Duration get remainingTime {
    if (expiresAt == null) return Duration.zero;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  List<Object?> get props => [
    paymentId,
    orderId,
    qrCode,
    qrCodeUrl,
    paymentLink,
    amount,
    currency,
    bankMethod,
    status,
    expiresAt,
    createdAt,
  ];
}

/// PhayPay payment status check result
class PhayPayStatus extends Equatable {
  final String paymentId;
  final PaymentStatus status;
  final DateTime? paidAt;
  final double amount;
  final String? transactionId;
  final String? bankReference;

  const PhayPayStatus({
    required this.paymentId,
    required this.status,
    this.paidAt,
    this.amount = 0,
    this.transactionId,
    this.bankReference,
  });

  factory PhayPayStatus.fromJson(Map<String, dynamic> json) {
    return PhayPayStatus(
      paymentId: json['paymentId'] as String? ?? '',
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      paidAt:
          json['paidAt'] != null
              ? DateTime.tryParse(json['paidAt'] as String)
              : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      transactionId: json['transactionId'] as String?,
      bankReference: json['bankReference'] as String?,
    );
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isExpired => status == PaymentStatus.expired;

  @override
  List<Object?> get props => [
    paymentId,
    status,
    paidAt,
    amount,
    transactionId,
    bankReference,
  ];
}

/// Cash payment details
class CashPaymentDetails {
  final List<CashDenomination> denominations;

  const CashPaymentDetails({this.denominations = const []});

  Map<String, dynamic> toJson() {
    return {
      'cash': {
        'denominationBreakdown': denominations.map((d) => d.toJson()).toList(),
      },
    };
  }
}

/// Cash denomination breakdown
class CashDenomination extends Equatable {
  final int denomination;
  final int count;

  const CashDenomination({required this.denomination, required this.count});

  int get total => denomination * count;

  Map<String, dynamic> toJson() {
    return {'denomination': denomination, 'count': count, 'total': total};
  }

  @override
  List<Object?> get props => [denomination, count];
}
