import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/report.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../providers/reports_provider.dart';

/// Daily Sales Report Screen
class DailySalesReportScreen extends ConsumerStatefulWidget {
  const DailySalesReportScreen({super.key});

  @override
  ConsumerState<DailySalesReportScreen> createState() =>
      _DailySalesReportScreenState();
}

class _DailySalesReportScreenState
    extends ConsumerState<DailySalesReportScreen> {
  DateTime selectedDate = DateTime.now();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadToday();
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
          title: const Text('Daily Sales Report'),
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Select Date',
              onPressed: () => _selectDate(context),
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
                // Header with date
                _buildHeader(),
                const SizedBox(height: 20),

                // Loading state
                if (reportsState.isLoading)
                  const Center(child: CircularProgressIndicator()),

                // Error state
                if (reportsState.error != null)
                  _buildErrorCard(reportsState.error!),

                // Success state
                if (!reportsState.isLoading &&
                    reportsState.error == null &&
                    reportsState.summary != null)
                  _buildReportContent(reportsState.summary!, isMobile),

                // No data state
                if (!reportsState.isLoading &&
                    reportsState.error == null &&
                    reportsState.summary == null)
                  _buildNoDataCard(),
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
            colors: [AppTheme.primaryOrange.withOpacity(0.1), Colors.white],
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
                    color: AppTheme.primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assessment,
                    size: 28,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Sales Report',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayFormat.format(selectedDate),
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

  Widget _buildReportContent(DailySalesSummary summary, bool isMobile) {
    return Column(
      children: [
        // Summary Cards
        isMobile
            ? _buildMobileSummaryCards(summary)
            : _buildDesktopSummaryCards(summary),
        const SizedBox(height: 20),

        // Additional Details
        _buildTransactionBreakdown(summary),
        const SizedBox(height: 20),

        // Payment Methods (if available)
        if (summary.payments.isNotEmpty)
          _buildPaymentMethodsCard(summary.payments),
      ],
    );
  }

  Widget _buildMobileSummaryCards(DailySalesSummary summary) {
    return Column(
      children: [
        _SummaryCard(
          title: 'Total Revenue',
          value:
              'LAK ${NumberFormat('#,##0').format(summary.sales.totalSales)}',
          icon: Icons.monetization_on,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Orders',
                value: '${summary.sales.totalOrders}',
                icon: Icons.receipt,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Avg Order',
                value:
                    'LAK ${NumberFormat('#,##0').format(summary.sales.averageOrderValue)}',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopSummaryCards(DailySalesSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Revenue',
            value:
                'LAK ${NumberFormat('#,##0').format(summary.sales.totalSales)}',
            icon: Icons.monetization_on,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Total Orders',
            value: '${summary.sales.totalOrders}',
            icon: Icons.receipt,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Average Order',
            value:
                'LAK ${NumberFormat('#,##0').format(summary.sales.averageOrderValue)}',
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionBreakdown(DailySalesSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBreakdownRow(
              'Total Orders',
              '${summary.sales.totalOrders}',
              Colors.blue,
            ),
            _buildBreakdownRow(
              'Total Sales',
              'LAK ${NumberFormat('#,##0').format(summary.sales.totalSales)}',
              Colors.green,
            ),
            const Divider(height: 24),
            _buildBreakdownRow(
              'Tax Amount',
              'LAK ${NumberFormat('#,##0').format(summary.sales.totalTax)}',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard(Map<String, double> paymentMethods) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...paymentMethods.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPaymentIcon(entry.key),
                          size: 20,
                          color: AppTheme.neutral600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Text(
                      'LAK ${NumberFormat('#,##0').format(entry.value)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Report',
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
            Icon(
              Icons.assessment_outlined,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No sales data found for ${displayFormat.format(selectedDate)}',
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

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'qr':
        return Icons.qr_code;
      default:
        return Icons.payment;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primaryOrange),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      ref.read(reportsProvider.notifier).setDateRange(picked, picked);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}
