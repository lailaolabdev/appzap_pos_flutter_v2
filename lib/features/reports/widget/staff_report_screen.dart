import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/report.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../providers/reports_provider.dart';

/// Staff Performance Report Screen
class StaffReportScreen extends ConsumerStatefulWidget {
  const StaffReportScreen({super.key});

  @override
  ConsumerState<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends ConsumerState<StaffReportScreen> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
  String sortBy = 'revenue';
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).setDateRange(startDate, endDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final reportsState = ref.watch(reportsProvider);

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          title: const Text('Staff Performance Report'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort By',
              onSelected: (value) {
                setState(() {
                  sortBy = value;
                });
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'revenue',
                      child: Text('Revenue'),
                    ),
                    const PopupMenuItem(
                      value: 'transactions',
                      child: Text('Transactions'),
                    ),
                    const PopupMenuItem(value: 'name', child: Text('Name')),
                  ],
            ),
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: 'Date Range',
              onPressed: () => _selectDateRange(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => ref.read(reportsProvider.notifier).refresh(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(reportsProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Loading state
                if (reportsState.isLoading)
                  const Center(child: CircularProgressIndicator()),

                // Error state
                if (reportsState.error != null)
                  _buildErrorCard(reportsState.error!),

                // Success state
                if (!reportsState.isLoading && reportsState.error == null)
                  _buildStaffList(reportsState.employeePerformance, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people,
                    size: 28,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff Performance Report',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${displayFormat.format(startDate)} - ${displayFormat.format(endDate)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList(List<SalesByStaffItem> staff, bool isMobile) {
    if (staff.isEmpty) {
      return _buildNoDataCard();
    }

    // Sort staff based on sortBy
    final sortedStaff = List<SalesByStaffItem>.from(staff);
    switch (sortBy) {
      case 'revenue':
        sortedStaff.sort((a, b) => b.totalSales.compareTo(a.totalSales));
        break;
      case 'transactions':
        sortedStaff.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        break;
      case 'name':
        sortedStaff.sort((a, b) => a.staffName.compareTo(b.staffName));
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Active Staff',
                    '${staff.length}',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Revenue',
                    'LAK ${NumberFormat('#,##0').format(staff.fold<double>(0, (sum, item) => sum + item.totalSales))}',
                    Icons.monetization_on,
                    Colors.blue,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Orders',
                      '${staff.fold<int>(0, (sum, item) => sum + item.totalOrders)}',
                      Icons.receipt,
                      Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Staff performance leaderboard header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance Leaderboard',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text('Sorted by ${sortBy.toUpperCase()}'),
              backgroundColor: Colors.green.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Staff performance cards
        ...sortedStaff.asMap().entries.map((entry) {
          final index = entry.key;
          final staffMember = entry.value;
          return _buildStaffCard(staffMember, index + 1, isMobile);
        }).toList(),
      ],
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStaffCard(
    SalesByStaffItem staffMember,
    int rank,
    bool isMobile,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with rank and staff info
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getRankColor(rank).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRankColor(rank),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (rank <= 3)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            rank == 1 ? Icons.emoji_events : Icons.star,
                            size: 12,
                            color: _getRankColor(rank),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffMember.staffName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // Role information not available in current model
                    ],
                  ),
                ),
                // Performance indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(rank).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPerformanceIcon(rank),
                    size: 20,
                    color: _getPerformanceColor(rank),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats section
            if (isMobile) ...[
              _buildStatRow('Orders Handled', '${staffMember.totalOrders}'),
              const SizedBox(height: 8),
              _buildStatRow(
                'Total Revenue',
                'LAK ${NumberFormat('#,##0').format(staffMember.totalSales)}',
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                'Avg Order Value',
                'LAK ${NumberFormat('#,##0').format(staffMember.averageOrderValue)}',
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Orders',
                      '${staffMember.totalOrders}',
                      Icons.receipt,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Revenue',
                      'LAK ${NumberFormat('#,##0').format(staffMember.totalSales)}',
                      Icons.monetization_on,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Avg Order',
                      'LAK ${NumberFormat('#,##0').format(staffMember.averageOrderValue)}',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral600),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.neutral600),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey.shade600; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.green;
    }
  }

  Color _getPerformanceColor(int rank) {
    if (rank <= 3) return Colors.green;
    if (rank <= 5) return Colors.orange;
    return Colors.grey;
  }

  IconData _getPerformanceIcon(int rank) {
    if (rank <= 3) return Icons.trending_up;
    if (rank <= 5) return Icons.trending_flat;
    return Icons.trending_down;
  }

  Widget _buildErrorCard(String error) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Staff Performance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(reportsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.people_outline,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Staff Data',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No staff performance data found for the selected period',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      ref.read(reportsProvider.notifier).setDateRange(startDate, endDate);
    }
  }
}
