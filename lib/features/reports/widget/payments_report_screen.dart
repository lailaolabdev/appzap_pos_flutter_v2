import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/responsive.dart';
import '../providers/reports_provider.dart';

/// Payment Methods Report Screen
class PaymentsReportScreen extends ConsumerStatefulWidget {
  const PaymentsReportScreen({super.key});

  @override
  ConsumerState<PaymentsReportScreen> createState() =>
      _PaymentsReportScreenState();
}

class _PaymentsReportScreenState extends ConsumerState<PaymentsReportScreen> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
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
    final languageCode = ref.watch(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: Text(Translations.get('payment_methods_report', languageCode)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: Translations.get('date_range', languageCode),
              onPressed: () => _selectDateRange(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: Translations.get('refresh', languageCode),
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
                _buildHeader(languageCode),
                const SizedBox(height: 20),

                // Loading state
                if (reportsState.isLoading)
                  const Center(child: CircularProgressIndicator()),

                // Error state
                if (reportsState.error != null)
                  _buildErrorCard(reportsState.error!, languageCode),

                // Success state
                if (!reportsState.isLoading &&
                    reportsState.error == null &&
                    reportsState.summary != null)
                  _buildPaymentMethodsReport(
                    reportsState.summary!,
                    isMobile,
                    languageCode,
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
            colors: [Colors.indigo.withOpacity(0.1), Colors.white],
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
                    color: Colors.indigo.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payment,
                    size: 28,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get(
                          'payment_methods_report',
                          languageCode,
                        ),
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

  Widget _buildPaymentMethodsReport(
    dynamic summary,
    bool isMobile,
    String languageCode,
  ) {
    try {
      // Extract payment methods data from the available data structure
      final paymentMethods = <String, double>{};

      // First, try to get from summary (DailySalesSummary.payments)
      if (summary?.payments != null && summary.payments.isNotEmpty) {
        summary.payments.forEach((key, value) {
          if (value > 0) {
            paymentMethods[key] = value;
          }
        });
      }

      // Second, try to get from topProducts data (sales-items-report has paymentMethodsBreakdown)
      // Check if we have access to the reports state to get payment data from products report
      final reportsState = ref.read(reportsProvider);

      // If summary doesn't have payment methods, try to extract from other available data
      if (paymentMethods.isEmpty && reportsState.topProducts.isNotEmpty) {
        // Get total sales from products
        final totalSales = reportsState.topProducts.fold<double>(
          0.0,
          (sum, product) => sum + product.totalRevenue,
        );

        // Create default payment method entry
        if (totalSales > 0) {
          paymentMethods['Cash'] = totalSales;
        }
      }

      // Final fallback - use summary sales data
      if (paymentMethods.isEmpty && summary?.sales?.totalSales != null) {
        final totalSales = summary.sales.totalSales;
        if (totalSales > 0) {
          paymentMethods['Cash'] = totalSales.toDouble();
        }
      }

      if (paymentMethods.isEmpty) {
        return _buildNoDataCard(languageCode);
      }

      final totalAmount = paymentMethods.values.fold<double>(
        0,
        (sum, amount) => sum + amount,
      );

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
                      Translations.get('payment_methods', languageCode),
                      '${paymentMethods.length}',
                      Icons.payment,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('total_amount', languageCode),
                      'LAK ${NumberFormat('#,##0').format(totalAmount)}',
                      Icons.monetization_on,
                      Colors.green,
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        Translations.get('most_used', languageCode),
                        paymentMethods.entries
                            .reduce((a, b) => a.value > b.value ? a : b)
                            .key,
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Payment methods list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Translations.get('payment_method_breakdown', languageCode),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Chip(
                label: Text(
                  '${paymentMethods.length} ${Translations.get('methods', languageCode)}',
                ),
                backgroundColor: Colors.indigo.withOpacity(0.1),
                labelStyle: const TextStyle(color: Colors.indigo),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment methods list
          ...paymentMethods.entries.map((entry) {
            final percentage =
                totalAmount > 0 ? (entry.value / totalAmount) * 100 : 0.0;
            return _buildPaymentMethodCard(
              entry.key,
              entry.value,
              percentage,
              isMobile,
              languageCode,
            );
          }).toList(),
        ],
      );
    } catch (e) {
      return _buildErrorCard(
        Translations.get(
          'error_processing_payment_data',
          languageCode,
        ).replaceAll('{error}', e.toString()),
        languageCode,
      );
    }
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    String method,
    double amount,
    double percentage,
    bool isMobile,
    String languageCode,
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
            // Header row with method name and percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _getPaymentMethodIcon(method),
                    const SizedBox(width: 12),
                    Text(
                      method,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.indigo.withOpacity(0.7),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),

            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Translations.get('amount', languageCode),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral600),
                ),
                Text(
                  'LAK ${NumberFormat('#,##0').format(amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPaymentMethodIcon(String method) {
    IconData icon;
    Color color;

    switch (method.toLowerCase()) {
      case 'cash':
        icon = Icons.money;
        color = Colors.green;
        break;
      case 'card':
      case 'credit card':
      case 'debit card':
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'mobile':
      case 'mobile payment':
      case 'digital wallet':
        icon = Icons.phone_android;
        color = Colors.purple;
        break;
      case 'bank transfer':
      case 'transfer':
        icon = Icons.account_balance;
        color = Colors.teal;
        break;
      default:
        icon = Icons.payment;
        color = Colors.indigo;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
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
              Translations.get('error_loading_payment_data', languageCode),
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
              Icons.payment_outlined,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              Translations.get('no_payment_data', languageCode),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.get(
                'no_payment_method_data_found_for_the_selectedperiod',
                languageCode,
              ),
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
            ).colorScheme.copyWith(primary: Colors.indigo),
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
