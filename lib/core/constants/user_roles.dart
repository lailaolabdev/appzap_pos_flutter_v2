/// User role constants matching API documentation
/// 
/// Valid roles from API (lines 153-162 in API doc):
/// - restaurant_admin: Full restaurant access (owner/admin)
/// - branch_admin: Branch-level admin
/// - manager: Manager permissions
/// - cashier: POS operations
/// - waiter: Service operations
/// - chef: Kitchen operations
/// - custom: Custom role with specific permissions
class UserRole {
  UserRole._(); // Private constructor to prevent instantiation

  /// Restaurant admin (owner/admin) - Full restaurant access
  static const String restaurantAdmin = 'restaurant_admin';

  /// Branch admin - Branch-level admin
  static const String branchAdmin = 'branch_admin';

  /// Manager - Manager permissions
  static const String manager = 'manager';

  /// Cashier - POS operations
  static const String cashier = 'cashier';

  /// Waiter - Service operations
  static const String waiter = 'waiter';

  /// Chef - Kitchen operations
  static const String chef = 'chef';

  /// Custom role - Custom permissions
  static const String custom = 'custom';

  /// All valid roles
  static const List<String> allRoles = [
    restaurantAdmin,
    branchAdmin,
    manager,
    cashier,
    waiter,
    chef,
    custom,
  ];

  /// Check if a role is valid
  static bool isValid(String role) => allRoles.contains(role);

  /// Get display name for role
  static String getDisplayName(String role) {
    switch (role) {
      case restaurantAdmin:
        return 'Restaurant Admin';
      case branchAdmin:
        return 'Branch Admin';
      case manager:
        return 'Manager';
      case cashier:
        return 'Cashier';
      case waiter:
        return 'Waiter';
      case chef:
        return 'Chef';
      case custom:
        return 'Custom Role';
      default:
        return role;
    }
  }
}

