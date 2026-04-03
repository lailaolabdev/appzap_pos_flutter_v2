import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/providers/localization_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Bottom navigation bar for mobile devices
///
/// Shows main navigation items at bottom of screen
/// Mobile-friendly design (Loyverse mobile style)
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Build navigation items based on permissions
    final items = <_BottomNavItem>[
      _BottomNavItem(
        icon: Icons.point_of_sale,
        label: 'Sales',
        route: AppRoutes.pos,
        enabled: true,
      ),
      if (user?.canManageInventory ?? false)
        _BottomNavItem(
          icon: Icons.inventory_2_outlined,
          label: 'Inventory',
          route: AppRoutes.inventory,
          enabled: true,
        ),
      if (user?.canManageCustomers ?? false)
        _BottomNavItem(
          icon: Icons.people_outline,
          label: 'Customers',
          route: AppRoutes.customers,
          enabled: true,
        ),
      if (user?.canViewReports ?? false)
        _BottomNavItem(
          icon: Icons.assessment_outlined,
          label: 'Reports',
          route: AppRoutes.reports,
          enabled: true,
        ),
      _BottomNavItem(
        icon: Icons.more_horiz,
        label: 'More',
        route: '',
        enabled: true,
      ),
    ];

    // Find current index
    final currentIndex = items.indexWhere((item) => item.route == currentRoute);

    return BottomNavigationBar(
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      onTap: (index) {
        final item = items[index];
        if (item.route.isEmpty) {
          // Show more menu
          _showMoreMenu(context, ref, user);
        } else {
          context.go(item.route);
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryOrange,
      unselectedItemColor: AppTheme.neutral500,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      items:
          items.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref, dynamic user) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'More',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

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
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppTheme.error),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text(
                              'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                    );

                    if (confirmed == true) {
                      await ref.read(authProvider.notifier).logout();
                      await ref.read(localizationProvider.notifier).clearLanguage();
                    }
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final String route;
  final bool enabled;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.enabled = true,
  });
}
