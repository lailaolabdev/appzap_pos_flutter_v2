import 'package:equatable/equatable.dart';

/// Customer loyalty tier enum
enum LoyaltyTier {
  bronze,
  silver,
  gold,
  platinum;

  static LoyaltyTier fromString(String value) {
    return LoyaltyTier.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => LoyaltyTier.bronze,
    );
  }

  String get displayName {
    switch (this) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
    }
  }

  double get discountPercent {
    switch (this) {
      case LoyaltyTier.bronze:
        return 0;
      case LoyaltyTier.silver:
        return 5;
      case LoyaltyTier.gold:
        return 10;
      case LoyaltyTier.platinum:
        return 15;
    }
  }
}

/// Customer model
class Customer extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final int loyaltyPoints;
  final LoyaltyTier tier;
  final double totalSpent;
  final int visitCount;
  final DateTime? lastVisit;
  final DateTime? dateOfBirth;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.loyaltyPoints = 0,
    this.tier = LoyaltyTier.bronze,
    this.totalSpent = 0,
    this.visitCount = 0,
    this.lastVisit,
    this.dateOfBirth,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      tier: LoyaltyTier.fromString(json['tier'] as String? ?? 'bronze'),
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      visitCount: json['visitCount'] as int? ?? 0,
      lastVisit:
          json['lastVisit'] != null
              ? DateTime.tryParse(json['lastVisit'] as String)
              : null,
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.tryParse(json['dateOfBirth'] as String)
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'loyaltyPoints': loyaltyPoints,
      'tier': tier.name,
      'totalSpent': totalSpent,
      'visitCount': visitCount,
      'lastVisit': lastVisit?.toIso8601String(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get display name with tier badge
  String get displayNameWithTier => '$name (${tier.displayName})';

  /// Check if customer has phone
  bool get hasPhone => phone != null && phone!.isNotEmpty;

  /// Check if customer has email
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Get the tier discount
  double get tierDiscount => tier.discountPercent;

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    int? loyaltyPoints,
    LoyaltyTier? tier,
    double? totalSpent,
    int? visitCount,
    DateTime? lastVisit,
    DateTime? dateOfBirth,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      tier: tier ?? this.tier,
      totalSpent: totalSpent ?? this.totalSpent,
      visitCount: visitCount ?? this.visitCount,
      lastVisit: lastVisit ?? this.lastVisit,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    loyaltyPoints,
    tier,
    totalSpent,
    visitCount,
    lastVisit,
    dateOfBirth,
    createdAt,
  ];
}

/// Customer loyalty points info
class CustomerPoints extends Equatable {
  final String customerId;
  final int currentPoints;
  final LoyaltyTier tier;
  final LoyaltyTier? nextTier;
  final int pointsToNextTier;
  final List<PointsHistory> history;

  const CustomerPoints({
    required this.customerId,
    required this.currentPoints,
    required this.tier,
    this.nextTier,
    this.pointsToNextTier = 0,
    this.history = const [],
  });

  factory CustomerPoints.fromJson(Map<String, dynamic> json) {
    return CustomerPoints(
      customerId: json['customerId'] as String? ?? '',
      currentPoints: json['currentPoints'] as int? ?? 0,
      tier: LoyaltyTier.fromString(json['tier'] as String? ?? 'bronze'),
      nextTier:
          json['nextTier'] != null
              ? LoyaltyTier.fromString(json['nextTier'] as String)
              : null,
      pointsToNextTier: json['pointsToNextTier'] as int? ?? 0,
      history:
          (json['history'] as List<dynamic>?)
              ?.map((e) => PointsHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    customerId,
    currentPoints,
    tier,
    nextTier,
    pointsToNextTier,
    history,
  ];
}

/// Points history entry
class PointsHistory extends Equatable {
  final String type;
  final int points;
  final String? orderId;
  final DateTime date;
  final String? description;

  const PointsHistory({
    required this.type,
    required this.points,
    this.orderId,
    required this.date,
    this.description,
  });

  factory PointsHistory.fromJson(Map<String, dynamic> json) {
    return PointsHistory(
      type: json['type'] as String? ?? 'earned',
      points: json['points'] as int? ?? 0,
      orderId: json['orderId'] as String?,
      date:
          json['date'] != null
              ? DateTime.parse(json['date'] as String)
              : DateTime.now(),
      description: json['description'] as String?,
    );
  }

  bool get isEarned => type == 'earned';
  bool get isRedeemed => type == 'redeemed';

  @override
  List<Object?> get props => [type, points, orderId, date, description];
}
