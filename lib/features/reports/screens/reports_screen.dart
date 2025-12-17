import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/reports_provider.dart';

/// Reports and analytics screen
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0;

  Future<void> _selectDateRange() async {
    final reportsState = ref.read(reportsProvider);
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: reportsState.startDate,
        end: reportsState.endDate,
      ),
    );

    if (picked != null) {
      ref.read(reportsProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  void _showQuickFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Today'),
              onTap: () {
                Navigator.pop(context);
                ref.read(reportsProvider.notifier).loadToday();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('This Week'),
              onTap: () {
                Navigator.pop(context);
                ref.read(reportsProvider.notifier).loadThisWeek();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('This Month'),
              onTap: () {
                Navigator.pop(context);
                ref.read(reportsProvider.notifier).loadThisMonth();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Custom Range'),
              onTap: () {
                Navigator.pop(context);
                _selectDateRange();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Date Range',
            onPressed: _showQuickFilters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(reportsProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: TabController(
                length: 4,
                vsync: Navigator.of(context),
                initialIndex: _selectedTab,
              ),
              onTap: (index) => setState(() => _selectedTab = index),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Products'),
                Tab(text: 'Staff'),
                Tab(text: 'End of Day'),
              ],
            ),
          ),
        ),
      ),
      body: reportsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportsState.error != null
              ? Center(
                  child: ErrorBanner(
                    message: reportsState.error!,
                    onDismiss: () => ref.read(reportsProvider.notifier).refresh(),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(reportsProvider.notifier).refresh(),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Date range header
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormatter.formatShortDate(reportsState.startDate)} - ${DateFormatter.formatShortDate(reportsState.endDate)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Tab content
                        if (_selectedTab == 0)
                          _buildOverviewTab(reportsState)
                        else if (_selectedTab == 1)
                          _buildProductsTab(reportsState)
                        else if (_selectedTab == 2)
                          _buildStaffTab(reportsState)
                        else
                          _buildEndOfDayTab(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewTab(ReportsState state) {
    final summary = state.summary;
    if (summary == null) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      children: [
        // Sales Summary Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Sales',
                      CurrencyFormatter.format(summary.sales.totalSales),
                      Icons.attach_money,
                      AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Orders',
                      summary.sales.totalOrders.toString(),
                      Icons.shopping_cart,
                      AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Avg Order',
                      CurrencyFormatter.format(summary.sales.averageOrderValue),
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Tax Collected',
                      CurrencyFormatter.format(summary.sales.totalTax),
                      Icons.receipt_long,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Payment Methods
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodRow(
                'Cash',
                summary.payments['cash'] ?? 0,
                Icons.payments,
                AppTheme.success,
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodRow(
                'Card',
                summary.payments['card'] ?? 0,
                Icons.credit_card,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodRow(
                'PhayPay',
                summary.payments['phaypay'] ?? 0,
                Icons.qr_code_2,
                AppTheme.primaryOrange,
              ),
            ],
          ),
        ),

        // Top Products
        if (summary.topProducts.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Selling Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...summary.topProducts.take(5).map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${product.quantity} sold',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(product.revenue),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductsTab(ReportsState state) {
    final products = state.topProducts;
    
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No product sales data available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryOrangeBackground,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              product.productName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (product.category != null)
                  Text(
                    product.category!,
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: ${product.quantitySold}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Orders: ${product.orderCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(product.totalRevenue),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Revenue',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffTab(ReportsState state) {
    final staff = state.employeePerformance;
    
    if (staff.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No staff performance data available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: staff.length,
      itemBuilder: (context, index) {
        final employee = staff[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryOrangeBackground,
              child: Text(
                employee.staffName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              employee.staffName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${employee.totalOrders} orders • ${employee.itemsSold} items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral600,
                  ),
                ),
                Text(
                  'Avg: ${CurrencyFormatter.format(employee.averageOrderValue)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(employee.totalSales),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Total Sales',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(
    String method,
    double amount,
    IconData icon,
    Color color,
  ) {
    final reportsState = ref.read(reportsProvider);
    final summary = reportsState.summary;
    if (summary == null) return const SizedBox.shrink();

    final totalPayments = (summary.payments['cash'] ?? 0) + 
                         (summary.payments['card'] ?? 0) + 
                         (summary.payments['phaypay'] ?? 0);
    final percentage = totalPayments > 0 ? (amount / totalPayments * 100) : 0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    method,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              const SizedBox(height: 2),
              Text(
                '${percentage.toStringAsFixed(1)}% of total',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEndOfDayTab() {
    final endOfDayAsync = ref.watch(endOfDayReportProvider);

    return endOfDayAsync.when(
      data: (report) {
        if (report == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No end of day report available'),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Report Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
          children: [
            Container(
                          padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrangeBackground,
                            borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                            Icons.assignment_outlined,
                color: AppTheme.primaryOrange,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End of Day Report',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                report.date,
                                style: const TextStyle(
                                  fontSize: 14,
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
            ),

            const SizedBox(height: 16),

            // Sales Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Summary',
                      style: TextStyle(
                        fontSize: 16,
                fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEODRow('Total Sales', CurrencyFormatter.format(report.totalSales)),
                    _buildEODRow('Total Orders', report.totalOrders.toString()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Methods
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEODRow('Cash', CurrencyFormatter.format(report.totalCash)),
                    _buildEODRow('Card', CurrencyFormatter.format(report.totalCard)),
                    _buildEODRow('Digital (PhayPay)', CurrencyFormatter.format(report.totalDigital)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cash Reconciliation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cash Reconciliation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEODRow('Opening Cash', CurrencyFormatter.format(report.openingCash)),
                    _buildEODRow('Closing Cash', CurrencyFormatter.format(report.closingCash)),
                    _buildEODRow('Expected Cash', CurrencyFormatter.format(report.expectedCash)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Difference:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            Text(
                          CurrencyFormatter.format(report.cashDifference),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: report.hasDiscrepancy
                                ? AppTheme.error
                                : AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    if (report.hasDiscrepancy)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: AppTheme.error, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Cash discrepancy detected. Please review transactions.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Transactions
            if (report.transactions.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
            Text(
                        '${report.transactions.length} transactions recorded',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load end of day report',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: AppTheme.neutral600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEODRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
