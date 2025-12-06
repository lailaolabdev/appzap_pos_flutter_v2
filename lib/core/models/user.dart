import 'package:equatable/equatable.dart';

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
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      userId: json['userId'] as String?,
      role: json['role'] as String? ?? 'cashier',
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      restaurant:
          json['restaurantId'] is Map
              ? Restaurant.fromJson(
                json['restaurantId'] as Map<String, dynamic>,
              )
              : json['restaurantId'] != null
              ? Restaurant(id: json['restaurantId'] as String)
              : null,
      branch:
          json['branchId'] is Map
              ? Branch.fromJson(json['branchId'] as Map<String, dynamic>)
              : json['branchId'] != null
              ? Branch(id: json['branchId'] as String)
              : null,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
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

  // Role checks
  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get isManager => role == 'manager' || isAdmin;
  bool get isCashier => role == 'cashier';

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
  final String currency;

  const Restaurant({required this.id, this.name, this.currency = 'LAK'});

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String?,
      currency: json['currency'] as String? ?? 'LAK',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'currency': currency};
  }

  @override
  List<Object?> get props => [id, name, currency];
}

/// Branch model
class Branch extends Equatable {
  final String id;
  final String? name;

  const Branch({required this.id, this.name});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name};
  }

  @override
  List<Object?> get props => [id, name];
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
