import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';

/// Reports and analytics screen - Card-based layout
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Responsive.isMobile(context);
    final languageCode = ref.read(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          surfaceTintColor: AppTheme.scaffoldBackground,
          title: Text(Translations.get('reports_analytics', languageCode)),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: Translations.get('date_range', languageCode),
              onPressed: () {
                // TODO: Show date range picker
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      Translations.get(
                        'date_range_selector_coming_soon',
                        languageCode,
                      ),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: Translations.get('refresh', languageCode),
              onPressed: () {
                // TODO: Refresh reports
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      Translations.get('reports_refreshed', languageCode),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                Translations.get('choose_report', languageCode),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Translations.get('select_report', languageCode),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral600),
              ),
              const SizedBox(height: 24),

              // Reports Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 2 : 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio:
                    isMobile
                        ? 1.0
                        : 1.2, // Square cards on mobile, wider on tablet
                children: [
                  _ReportCard(
                    icon: Icons.assessment,
                    title: Translations.get('daily_sales', languageCode),
                    description: Translations.get(
                      'view_today_performance',
                      languageCode,
                    ),
                    color: AppTheme.primaryOrange,
                    onTap:
                        () =>
                            _navigateToReport(context, '/reports/daily-sales'),
                  ),
                  _ReportCard(
                    icon: Icons.inventory_2,
                    title: Translations.get('products', languageCode),
                    description: Translations.get(
                      'sales_by_products',
                      languageCode,
                    ),
                    color: Colors.blue,
                    onTap:
                        () => _navigateToReport(context, '/reports/products'),
                  ),
                  _ReportCard(
                    icon: Icons.people,
                    title: Translations.get('staff', languageCode),
                    description: Translations.get(
                      'performance_by_staff',
                      languageCode,
                    ),
                    color: Colors.green,
                    onTap: () => _navigateToReport(context, '/reports/staff'),
                  ),
                  _ReportCard(
                    icon: Icons.nightlight_round,
                    title: Translations.get('end_of_day', languageCode),
                    description: Translations.get(
                      'daily_closing_report',
                      languageCode,
                    ),
                    color: Colors.purple,
                    onTap:
                        () => _navigateToReport(context, '/reports/end-of-day'),
                  ),
                  _ReportCard(
                    icon: Icons.trending_up,
                    title: Translations.get('sales_trends', languageCode),
                    description: Translations.get(
                      'historical_trends',
                      languageCode,
                    ),
                    color: Colors.teal,
                    onTap:
                        () =>
                            _navigateToReport(context, '/reports/sales-trends'),
                  ),
                  _ReportCard(
                    icon: Icons.category,
                    title: Translations.get('categories', languageCode),
                    description: Translations.get(
                      'sales_by_category',
                      languageCode,
                    ),
                    color: Colors.orange,
                    onTap:
                        () => _navigateToReport(context, '/reports/categories'),
                  ),
                  _ReportCard(
                    icon: Icons.payment,
                    title: Translations.get('payments', languageCode),
                    description: Translations.get(
                      'payment_methods_breakdown',
                      languageCode,
                    ),
                    color: Colors.indigo,
                    onTap:
                        () => _navigateToReport(context, '/reports/payments'),
                  ),
                  _ReportCard(
                    icon: Icons.schedule,
                    title: Translations.get('hourly_sales', languageCode),
                    description: Translations.get(
                      'sales_by_hour',
                      languageCode,
                    ),
                    color: Colors.pink,
                    onTap:
                        () =>
                            _navigateToReport(context, '/reports/hourly-sales'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReport(BuildContext context, String route) {
    context.go(route);
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced from 16 to 12
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Don't expand unnecessarily
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced from 12 to 10
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28, // Reduced from 32 to 28
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(
                height: 4,
              ), // Increased from 2 to 4 for better spacing
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.neutral600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
