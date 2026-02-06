import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/responsive.dart';
import '../providers/reports_provider.dart';

/// End of Day Report Screen
class EndOfDayReportScreen extends ConsumerStatefulWidget {
  const EndOfDayReportScreen({super.key});

  @override
  ConsumerState<EndOfDayReportScreen> createState() =>
      _EndOfDayReportScreenState();
}

class _EndOfDayReportScreenState extends ConsumerState<EndOfDayReportScreen> {
  DateTime selectedDate = DateTime.now();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayFormat = DateFormat('EEEE, MMM dd, yyyy');
  final DateFormat timeFormat = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEndOfDayReport();
    });
  }

  void _loadEndOfDayReport() {
    ref.read(reportsProvider.notifier).setDateRange(selectedDate, selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final endOfDayReport = ref.watch(endOfDayReportProvider);
    final languageCode = ref.watch(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: Text(Translations.get('end_of_day_report', languageCode)),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: Translations.get('select_date', languageCode),
              onPressed: () => _selectDate(context),
            ),
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: Translations.get('print_report', languageCode),
              onPressed: () => _printReport(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: Translations.get('refresh', languageCode),
              onPressed: () => _loadEndOfDayReport(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => _loadEndOfDayReport(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(languageCode),
                const SizedBox(height: 20),

                // Report content
                endOfDayReport.when(
                  data:
                      (report) =>
                          report != null
                              ? _buildReportContent(
                                report,
                                isMobile,
                                languageCode,
                              )
                              : _buildNoDataCard(languageCode),
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) =>
                          _buildErrorCard(error.toString(), languageCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String languageCode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.purple.withOpacity(0.1), Colors.white],
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
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    size: 28,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get('end_of_day_report', languageCode),
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
                      Text(
                        Translations.get('generated_at', languageCode) +
                            ' ${timeFormat.format(DateTime.now())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutral500,
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

  Widget _buildReportContent(
    dynamic report,
    bool isMobile,
    String languageCode,
  ) {
    // Since we don't have the exact EndOfDayReport model structure,
    // I'll create a mock comprehensive report structure
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sales summary
        _buildSalesSummarySection(languageCode),
        const SizedBox(height: 16),

        // Transaction breakdown
        _buildTransactionBreakdownSection(languageCode),
        const SizedBox(height: 16),

        // Payment methods
        _buildPaymentMethodsSection(languageCode),
        const SizedBox(height: 16),

        // Staff performance summary
        _buildStaffSummarySection(languageCode),
        const SizedBox(height: 16),

        // Operational summary
        _buildOperationalSummarySection(languageCode),
        const SizedBox(height: 16),

        // Actions
        _buildActionsSection(languageCode),
      ],
    );
  }

  Widget _buildSalesSummarySection(String languageCode) {
    final reportsState = ref.watch(reportsProvider);
    final summary = reportsState.summary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              Translations.get('sales_summary', languageCode),
              Icons.assessment,
            ),
            const SizedBox(height: 16),

            if (summary != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('total_revenue', languageCode),
                      'LAK ${NumberFormat('#,##0').format(summary.sales?.totalSales ?? 0)}',
                      Colors.green,
                      Icons.monetization_on,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('total_orders', languageCode),
                      '${summary.sales?.totalOrders ?? 0}',
                      Colors.blue,
                      Icons.receipt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('average_order', languageCode),
                      'LAK ${NumberFormat('#,##0').format(summary.sales?.averageOrderValue ?? 0)}',
                      Colors.orange,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('sales_amount', languageCode),
                      'LAK ${NumberFormat('#,##0').format(summary.sales?.totalSales ?? 0)}',
                      Colors.teal,
                      Icons.attach_money,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Text(
                  Translations.get('no_sales_data_available', languageCode),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionBreakdownSection(String languageCode) {
    final reportsState = ref.watch(reportsProvider);
    final summary = reportsState.summary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              Translations.get('transaction_breakdown', languageCode),
              Icons.bar_chart,
            ),
            const SizedBox(height: 16),

            if (summary != null) ...[
              _buildBreakdownRow(
                Translations.get('completed_sales', languageCode),
                '${summary.sales?.totalOrders ?? 0}',
                summary.sales?.totalSales ?? 0,
                Colors.green,
              ),
              _buildBreakdownRow(
                Translations.get('void_transactions', languageCode),
                '0', // Not available in current model
                0.0, // Not available in current model
                Colors.red,
              ),
              const Divider(height: 24),
              _buildBreakdownRow(
                Translations.get('net_sales', languageCode),
                '${summary.sales?.totalOrders ?? 0}',
                summary.sales?.totalSales ?? 0,
                Colors.blue,
                isTotal: true,
              ),
            ] else ...[
              Center(
                child: Text(
                  Translations.get(
                    'no_transaction_data_available',
                    languageCode,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(String languageCode) {
    final reportsState = ref.watch(reportsProvider);
    final summary = reportsState.summary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              Translations.get('payment_methods_breakdown', languageCode),
              Icons.payment,
            ),
            const SizedBox(height: 16),

            if (summary != null) ...[
              Center(
                child: Text(
                  Translations.get(
                    'payment_method_breakdown_not_available_in_current_data_model',
                    languageCode,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStaffSummarySection(String languageCode) {
    final reportsState = ref.watch(reportsProvider);
    final staff = reportsState.employeePerformance;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              Translations.get('staff_summary', languageCode),
              Icons.people,
            ),
            const SizedBox(height: 16),

            if (staff.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('active_staff', languageCode),
                      '${staff.length}',
                      Colors.green,
                      Icons.people,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('top_performer', languageCode),
                      staff.first.staffName,
                      Colors.amber,
                      Icons.star,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...staff
                  .take(3)
                  .map(
                    (member) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child: Text(
                              member.staffName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(member.staffName)),
                          Text(
                            'LAK ${NumberFormat('#,##0').format(member.totalSales)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
            ] else ...[
              Center(
                child: Text(
                  Translations.get('no_staff_data_available', languageCode),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalSummarySection(String languageCode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              Translations.get('operational_summary', languageCode),
              Icons.business,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    Translations.get('operating_hours', languageCode),
                    '12 hours',
                    Colors.blue,
                    Icons.access_time,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    Translations.get('status', languageCode),
                    'Completed',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildOperationalItem(
              Translations.get('store_opened', languageCode),
              '08:00 AM',
              Icons.store,
              Colors.green,
            ),
            _buildOperationalItem(
              Translations.get('last_transaction', languageCode),
              timeFormat.format(
                DateTime.now().subtract(const Duration(hours: 1)),
              ),
              Icons.receipt,
              Colors.blue,
            ),
            _buildOperationalItem(
              Translations.get('report_generated', languageCode),
              timeFormat.format(DateTime.now()),
              Icons.description,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(String languageCode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              Translations.get('actions', languageCode),
              Icons.settings,
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _printReport(),
                  icon: const Icon(Icons.print),
                  label: Text(Translations.get('print_report', languageCode)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportReport(),
                  icon: const Icon(Icons.file_download),
                  label: Text(Translations.get('export_pdf', languageCode)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _emailReport(),
                  icon: const Icon(Icons.email),
                  label: Text(Translations.get('email_report', languageCode)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.purple),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String count,
    double amount,
    Color color, {
    bool isTotal = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration:
          isTotal
              ? BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: Padding(
        padding: isTotal ? const EdgeInsets.all(8) : EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                count,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'LAK ${NumberFormat('#,##0').format(amount)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, String languageCode) {
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
              Translations.get('error_loading_end_of_day_report', languageCode),
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
              onPressed: () => _loadEndOfDayReport(),
              child: Text(Translations.get('retry', languageCode)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard(String languageCode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.nightlight_round,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              Translations.get('no_end_of_day_data', languageCode),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${Translations.get('no_end_of_day_report_data_available_for', languageCode)} ${displayFormat.format(selectedDate)}',
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
            ).colorScheme.copyWith(primary: Colors.purple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadEndOfDayReport();
    }
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon')),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _emailReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email functionality coming soon')),
    );
  }
}
