import 'package:equatable/equatable.dart';

/// Daily sales summary report
class DailySalesSummary extends Equatable {
  final Period period;
  final SalesData sales;
  final Map<String, double> payments;
  final List<TopProduct> topProducts;

  const DailySalesSummary({
    required this.period,
    required this.sales,
    required this.payments,
    this.topProducts = const [],
  });

  factory DailySalesSummary.fromJson(Map<String, dynamic> json) {
    return DailySalesSummary(
      period: Period.fromJson(json['period'] as Map<String, dynamic>? ?? {}),
      sales: SalesData.fromJson(json['sales'] as Map<String, dynamic>? ?? {}),
      payments:
          (json['payments'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
      topProducts:
          (json['topProducts'] as List<dynamic>?)
              ?.map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [period, sales, payments, topProducts];
}

/// Report period
class Period extends Equatable {
  final String startDate;
  final String endDate;

  const Period({required this.startDate, required this.endDate});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Sales data
class SalesData extends Equatable {
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final double totalTax;

  const SalesData({
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.totalTax,
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0,
      totalTax: (json['totalTax'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    totalSales,
    totalOrders,
    averageOrderValue,
    totalTax,
  ];
}

/// Top product
class TopProduct extends Equatable {
  final String productId;
  final String productName;
  final int quantity;
  final double revenue;

  const TopProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [productId, productName, quantity, revenue];
}

/// Sales by product report item
class SalesByProductItem extends Equatable {
  final String productId;
  final String productName;
  final String? category;
  final int quantitySold;
  final double totalRevenue;
  final double averagePrice;
  final int orderCount;

  const SalesByProductItem({
    required this.productId,
    required this.productName,
    this.category,
    required this.quantitySold,
    required this.totalRevenue,
    required this.averagePrice,
    required this.orderCount,
  });

  factory SalesByProductItem.fromJson(Map<String, dynamic> json) {
    return SalesByProductItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      category: json['category'] as String?,
      quantitySold: json['quantitySold'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0,
      orderCount: json['orderCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    category,
    quantitySold,
    totalRevenue,
    averagePrice,
    orderCount,
  ];
}

/// Sales by staff/employee report item
class SalesByStaffItem extends Equatable {
  final String staffId;
  final String staffName;
  final int totalOrders;
  final double totalSales;
  final double averageOrderValue;
  final int itemsSold;

  const SalesByStaffItem({
    required this.staffId,
    required this.staffName,
    required this.totalOrders,
    required this.totalSales,
    required this.averageOrderValue,
    required this.itemsSold,
  });

  factory SalesByStaffItem.fromJson(Map<String, dynamic> json) {
    return SalesByStaffItem(
      staffId: json['staffId'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0,
      itemsSold: json['itemsSold'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    staffId,
    staffName,
    totalOrders,
    totalSales,
    averageOrderValue,
    itemsSold,
  ];
}

/// End of day report
class EndOfDayReport extends Equatable {
  final String date;
  final double openingCash;
  final double closingCash;
  final double totalSales;
  final double totalCash;
  final double totalCard;
  final double totalDigital;
  final int totalOrders;
  final double expectedCash;
  final double cashDifference;
  final List<dynamic> transactions;

  const EndOfDayReport({
    required this.date,
    required this.openingCash,
    required this.closingCash,
    required this.totalSales,
    required this.totalCash,
    required this.totalCard,
    required this.totalDigital,
    required this.totalOrders,
    required this.expectedCash,
    required this.cashDifference,
    this.transactions = const [],
  });

  factory EndOfDayReport.fromJson(Map<String, dynamic> json) {
    return EndOfDayReport(
      date: json['date'] as String? ?? '',
      openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0,
      closingCash: (json['closingCash'] as num?)?.toDouble() ?? 0,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      totalCash: (json['totalCash'] as num?)?.toDouble() ?? 0,
      totalCard: (json['totalCard'] as num?)?.toDouble() ?? 0,
      totalDigital: (json['totalDigital'] as num?)?.toDouble() ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      expectedCash: (json['expectedCash'] as num?)?.toDouble() ?? 0,
      cashDifference: (json['cashDifference'] as num?)?.toDouble() ?? 0,
      transactions: json['transactions'] as List<dynamic>? ?? [],
    );
  }

  bool get hasDiscrepancy => cashDifference.abs() > 0.01;

  @override
  List<Object?> get props => [
    date,
    openingCash,
    closingCash,
    totalSales,
    totalCash,
    totalCard,
    totalDigital,
    totalOrders,
    expectedCash,
    cashDifference,
    transactions,
  ];
}

/// Daily breakdown item (one row per day)
class DailyBreakdownItem extends Equatable {
  final DateTime date;
  final double grossSales;
  final int orderCount;

  const DailyBreakdownItem({
    required this.date,
    required this.grossSales,
    this.orderCount = 0,
  });

  @override
  List<Object?> get props => [date, grossSales, orderCount];
}

/// Sales by payment type report item
class SalesByPaymentItem extends Equatable {
  final String method;
  final int transactionCount;
  final double totalAmount;
  final double percentage;

  const SalesByPaymentItem({
    required this.method,
    required this.transactionCount,
    required this.totalAmount,
    this.percentage = 0,
  });

  factory SalesByPaymentItem.fromJson(Map<String, dynamic> json) {
    return SalesByPaymentItem(
      method: json['method'] as String? ??
          json['paymentMethod'] as String? ??
          json['_id'] as String? ??
          '',
      transactionCount: json['transactionCount'] as int? ??
          json['count'] as int? ??
          0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          (json['netSales'] as num?)?.toDouble() ??
          0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  String get displayName {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'transfer':
        return 'Transfer';
      case 'bank_qr_jdb':
        return 'JDB QR';
      case 'bank_qr_bcel':
        return 'BCEL QR';
      case 'bank_qr_ldb':
        return 'LDB QR';
      default:
        return method.replaceAll('_', ' ');
    }
  }

  @override
  List<Object?> get props => [method, transactionCount, totalAmount];
}

