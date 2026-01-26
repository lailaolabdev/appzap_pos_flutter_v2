import 'package:equatable/equatable.dart';

import '../constants/user_roles.dart';

/// User model for authenticated staff
class User extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? userId;
  final String role;
  final bool isPhoneVerified;
  final Restaurant? restaurant;
  final Branch? branch;
  final List<String> permissions;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.userId,
    required this.role,
    this.isPhoneVerified = false,
    this.restaurant,
    this.branch,
    this.permissions = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      userId: json['userId']?.toString(),
      role: json['role']?.toString() ?? 'cashier',
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      restaurant:
          json['restaurantId'] is Map
              ? Restaurant.fromJson(
                json['restaurantId'] as Map<String, dynamic>,
              )
              : json['restaurantId'] != null
              ? Restaurant(id: json['restaurantId'].toString())
              : null,
      branch:
          json['branchId'] is Map
              ? Branch.fromJson(json['branchId'] as Map<String, dynamic>)
              : json['branchId'] != null
              ? Branch(id: json['branchId'].toString())
              : null,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'userId': userId,
      'role': role,
      'isPhoneVerified': isPhoneVerified,
      'restaurantId': restaurant?.toJson(),
      'branchId': branch?.toJson(),
      'permissions': permissions,
    };
  }

  // Permission checks
  bool get canManageSales => permissions.contains('manage_sales');
  bool get canViewReports => permissions.contains('view_reports');
  bool get canManageCustomers => permissions.contains('manage_customers');
  bool get canManageInventory => permissions.contains('manage_inventory');
  bool get canManageStaff => permissions.contains('manage_staff');
  bool get canManageSettings => permissions.contains('manage_settings');
  bool get canManageOrders => permissions.contains('manage_orders');

  // Role checks (using correct API role values)
  bool get isRestaurantAdmin => role == UserRole.restaurantAdmin;
  bool get isBranchAdmin => role == UserRole.branchAdmin;
  bool get isManager => role == UserRole.manager;
  bool get isCashier => role == UserRole.cashier;
  bool get isWaiter => role == UserRole.waiter;
  bool get isChef => role == UserRole.chef;
  
  // Helper: Any admin role
  bool get isAdmin => isRestaurantAdmin || isBranchAdmin;
  
  // Helper: Management level
  bool get isManagementLevel => isAdmin || isManager;
  
  // Get role display name
  String get roleDisplayName => UserRole.getDisplayName(role);

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? userId,
    String? role,
    bool? isPhoneVerified,
    Restaurant? restaurant,
    Branch? branch,
    List<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      restaurant: restaurant ?? this.restaurant,
      branch: branch ?? this.branch,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    userId,
    role,
    isPhoneVerified,
    restaurant,
    branch,
    permissions,
  ];
}

/// Restaurant model
class Restaurant extends Equatable {
  final String id;
  final String? name;
  final String? code; // 5-character code (e.g., "JC001", "MS123")
  final RestaurantSettings? settings;

  const Restaurant({
    required this.id,
    this.name,
    this.code,
    this.settings,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString(),
      code: json['code']?.toString(),
      settings: json['settings'] != null
          ? RestaurantSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'settings': settings?.toJson(),
    };
  }

  // Helper to get currency
  String get currency => settings?.currency.mainCurrency ?? 'LAK';

  @override
  List<Object?> get props => [id, name, code, settings];
}

/// Restaurant settings
class RestaurantSettings extends Equatable {
  final CurrencySettings currency;

  const RestaurantSettings({required this.currency});

  factory RestaurantSettings.fromJson(Map<String, dynamic> json) {
    return RestaurantSettings(
      currency: json['currency'] != null
          ? CurrencySettings.fromJson(json['currency'] as Map<String, dynamic>)
          : const CurrencySettings(mainCurrency: 'LAK'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'currency': currency.toJson()};
  }

  @override
  List<Object?> get props => [currency];
}

/// Currency settings
class CurrencySettings extends Equatable {
  final String mainCurrency; // LAK, USD, THB

  const CurrencySettings({required this.mainCurrency});

  factory CurrencySettings.fromJson(Map<String, dynamic> json) {
    return CurrencySettings(
      mainCurrency: json['mainCurrency']?.toString() ?? 'LAK',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mainCurrency': mainCurrency};
  }

  @override
  List<Object?> get props => [mainCurrency];
}

/// Branch model
class Branch extends Equatable {
  final String id;
  final String? name;
  final String? branchCode; // Code format: "{restaurantCode}B{number}" (e.g., "MS1B1", "JC1B1")

  const Branch({
    required this.id,
    this.name,
    this.branchCode,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString(),
      branchCode: json['branchCode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'branchCode': branchCode,
    };
  }

  @override
  List<Object?> get props => [id, name, branchCode];
}

/// Subscription model (trial, active, expired)
class Subscription extends Equatable {
  final String id;
  final String status; // 'trial', 'active', 'expired'
  final DateTime? endDate;

  const Subscription({
    required this.id,
    required this.status,
    this.endDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'] as String? ?? '',
      status: json['status'] as String? ?? 'trial',
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
      'endDate': endDate?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isTrial => status == 'trial';
  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';

  int get daysRemaining {
    if (endDate == null) return 0;
    final now = DateTime.now();
    if (endDate!.isBefore(now)) return 0;
    return endDate!.difference(now).inDays;
  }

  @override
  List<Object?> get props => [id, status, endDate];
}

/// Authentication tokens
class AuthTokens extends Equatable {
  final TokenData access;
  final TokenData refresh;

  const AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      access: TokenData.fromJson(json['access'] as Map<String, dynamic>),
      refresh: TokenData.fromJson(json['refresh'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [access, refresh];
}

/// Token data with expiration
class TokenData extends Equatable {
  final String token;
  final DateTime? expires;

  const TokenData({required this.token, this.expires});

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      token: json['token'] as String? ?? '',
      expires:
          json['expires'] != null
              ? DateTime.tryParse(json['expires'] as String)
              : null,
    );
  }

  bool get isExpired {
    if (expires == null) return false;
    return DateTime.now().isAfter(expires!);
  }

  @override
  List<Object?> get props => [token, expires];
}
