import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Sidebar navigation for all devices
/// 
/// - Tablet/Desktop: Persistent sidebar (80px width)
/// - Mobile: Drawer sidebar (240px width)
/// Industry standard (Loyverse, Square, Toast style)
class AppSidebar extends ConsumerWidget {
  final bool isInDrawer;

  const AppSidebar({
    super.key,
    this.isInDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Drawer mode: wider sidebar with more spacing
    // Persistent mode: compact sidebar with icon + label
    final width = isInDrawer ? 240.0 : 80.0;

    return Container(
      width: width,
      color: AppTheme.neutral900,
      child: Column(
        children: [
          // Logo/Brand
          Container(
            height: isInDrawer ? 120 : 80,
            padding: const EdgeInsets.all(16),
            child: isInDrawer ? _buildDrawerHeader(user) : _buildCompactHeader(),
          ),

          // Divider
          Container(
            height: 1,
            color: AppTheme.neutral800,
          ),

          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _SidebarItem(
                    icon: Icons.point_of_sale,
                    label: 'Sales',
                    route: AppRoutes.pos,
                    isActive: currentRoute == AppRoutes.pos,
                    isInDrawer: isInDrawer,
                    onTap: () {
                      context.go(AppRoutes.pos);
                      if (isInDrawer) Navigator.of(context).pop(); // Close drawer
                    },
                  ),
                  // Orders - accessible to everyone who can manage sales
                  _SidebarItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    route: AppRoutes.orders,
                    isActive: currentRoute == AppRoutes.orders,
                    isInDrawer: isInDrawer,
                    onTap: () {
                      context.go(AppRoutes.orders);
                      if (isInDrawer) Navigator.of(context).pop();
                    },
                  ),
                  // Show to admins OR users with permission
                  if (user?.isAdmin == true || user?.canManageInventory == true)
                    _SidebarItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventory',
                      route: AppRoutes.inventory,
                      isActive: currentRoute == AppRoutes.inventory,
                      isInDrawer: isInDrawer,
                      onTap: () {
                        context.go(AppRoutes.inventory);
                        if (isInDrawer) Navigator.of(context).pop();
                      },
                    ),
                  // Show to admins OR users with permission
                  if (user?.isAdmin == true || user?.canManageCustomers == true)
                    _SidebarItem(
                      icon: Icons.people_outline,
                      label: 'Customers',
                      route: AppRoutes.customers,
                      isActive: currentRoute == AppRoutes.customers,
                      isInDrawer: isInDrawer,
                      onTap: () {
                        context.go(AppRoutes.customers);
                        if (isInDrawer) Navigator.of(context).pop();
                      },
                    ),
                  // Show to admins OR users with permission
                  if (user?.isAdmin == true || user?.canViewReports == true)
                    _SidebarItem(
                      icon: Icons.assessment_outlined,
                      label: 'Reports',
                      route: AppRoutes.reports,
                      isActive: currentRoute == AppRoutes.reports,
                      isInDrawer: isInDrawer,
                      onTap: () {
                        context.go(AppRoutes.reports);
                        if (isInDrawer) Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ),

          // Bottom Section - User Profile
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Divider
                Container(
                  height: 1,
                  color: AppTheme.neutral800,
                  margin: const EdgeInsets.only(bottom: 8),
                ),

                // User Profile
                _SidebarItem(
                  icon: Icons.person_outline,
                  label: isInDrawer 
                      ? (user?.name ?? 'User')
                      : user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  route: '',
                  isActive: false,
                  isInDrawer: isInDrawer,
                  onTap: () {
                    _showUserMenu(context, ref, user, isInDrawer);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact header for persistent sidebar (logo only)
  Widget _buildCompactHeader() {
    return Center(
      child: Text(
        'AZ',
        style: const TextStyle(
          color: AppTheme.primaryOrange,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Drawer header with app name and user info
  Widget _buildDrawerHeader(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App logo + name
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'AZ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'AppZap POS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Branch info
        if (user?.branch?.name != null)
          Text(
            user!.branch!.name!,
            style: const TextStyle(
              color: AppTheme.neutral400,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  void _showUserMenu(BuildContext context, WidgetRef ref, dynamic user, bool isInDrawer) {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryOrangeBackground,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(user?.name ?? 'User'),
              subtitle: Text(user?.roleDisplayName ?? 'Staff'),
            ),
            const Divider(),
            
            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text('Logout', style: TextStyle(color: AppTheme.error)),
              onTap: () async {
                Navigator.pop(modalContext); // Close bottom sheet
                if (isInDrawer) Navigator.pop(context); // Close drawer if in drawer mode
                
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual sidebar item
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;
  final bool isInDrawer;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
    required this.isInDrawer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryOrange : AppTheme.neutral400;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: isInDrawer ? 56 : 72,
        padding: isInDrawer 
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryOrangeBackground.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? AppTheme.primaryOrange : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: isInDrawer ? _buildDrawerLayout(color) : _buildCompactLayout(color),
      ),
    );
  }

  /// Drawer mode: Icon + label in row (horizontal)
  Widget _buildDrawerLayout(Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Compact mode: Icon + label in column (vertical)
  Widget _buildCompactLayout(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

