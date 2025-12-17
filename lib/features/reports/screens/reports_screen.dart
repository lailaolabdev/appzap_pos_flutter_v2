import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer: isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Date Range',
              onPressed: () {
                // TODO: Show date range picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Date range selector coming soon')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                // TODO: Refresh reports
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reports refreshed')),
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
                'Choose a Report',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a report to view detailed insights',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(height: 24),

              // Reports Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 2 : 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _ReportCard(
                    icon: Icons.assessment,
                    title: 'Daily Sales',
                    description: 'View today\'s performance',
                    color: AppTheme.primaryOrange,
                    onTap: () => _showComingSoon(context, 'Daily Sales Report'),
                  ),
                  _ReportCard(
                    icon: Icons.inventory_2,
                    title: 'Products',
                    description: 'Sales by products',
                    color: Colors.blue,
                    onTap: () => _showComingSoon(context, 'Products Report'),
                  ),
                  _ReportCard(
                    icon: Icons.people,
                    title: 'Staff',
                    description: 'Performance by staff',
                    color: Colors.green,
                    onTap: () => _showComingSoon(context, 'Staff Report'),
                  ),
                  _ReportCard(
                    icon: Icons.nightlight_round,
                    title: 'End of Day',
                    description: 'Daily closing report',
                    color: Colors.purple,
                    onTap: () => _showComingSoon(context, 'End of Day Report'),
                  ),
                  _ReportCard(
                    icon: Icons.trending_up,
                    title: 'Sales Trends',
                    description: 'Historical trends',
                    color: Colors.teal,
                    onTap: () => _showComingSoon(context, 'Sales Trends'),
                  ),
                  _ReportCard(
                    icon: Icons.category,
                    title: 'Categories',
                    description: 'Sales by category',
                    color: Colors.orange,
                    onTap: () => _showComingSoon(context, 'Category Report'),
                  ),
                  _ReportCard(
                    icon: Icons.payment,
                    title: 'Payments',
                    description: 'Payment methods breakdown',
                    color: Colors.indigo,
                    onTap: () => _showComingSoon(context, 'Payment Methods'),
                  ),
                  _ReportCard(
                    icon: Icons.schedule,
                    title: 'Hourly Sales',
                    description: 'Sales by hour',
                    color: Colors.pink,
                    onTap: () => _showComingSoon(context, 'Hourly Sales'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$reportName - Coming Soon'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
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
