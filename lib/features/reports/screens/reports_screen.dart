import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_shell.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../shared/widgets/app_sidebar.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: const Drawer(child: AppSidebar(isInDrawer: true)),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            Translations.get('reports', lang),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: ListView(
          children: [
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            _buildReportTile(
              icon: Icons.assessment,
              title: Translations.get('sales_summary', lang),
              subtitle: Translations.get('view_today_performance', lang),
              onTap: () => context.go(AppRoutes.dailySalesReport),
            ),
            _buildReportTile(
              icon: Icons.inventory_2,
              title: Translations.get('sales_by_item', lang),
              subtitle: Translations.get('sales_by_products', lang),
              onTap: () => context.go(AppRoutes.productsReport),
            ),
            _buildReportTile(
              icon: Icons.people,
              title: Translations.get('sales_by_employee', lang),
              subtitle: Translations.get('performance_by_staff', lang),
              onTap: () => context.go(AppRoutes.staffReport),
            ),
            _buildReportTile(
              icon: Icons.payment,
              title: Translations.get('sales_by_payment', lang),
              subtitle: Translations.get('payment_methods_breakdown', lang),
              onTap: () => context.go(AppRoutes.paymentsReport),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppTheme.neutral600),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
