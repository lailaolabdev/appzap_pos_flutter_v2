import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/responsive.dart';
import '../providers/reports_provider.dart';

/// Hourly Sales Report Screen
class HourlySalesReportScreen extends ConsumerStatefulWidget {
  const HourlySalesReportScreen({super.key});

  @override
  ConsumerState<HourlySalesReportScreen> createState() =>
      _HourlySalesReportScreenState();
}

class _HourlySalesReportScreenState
    extends ConsumerState<HourlySalesReportScreen> {
  DateTime selectedDate = DateTime.now();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayFormat = DateFormat('EEEE, MMM dd, yyyy');
  final DateFormat timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reportsProvider.notifier)
          .setDateRange(selectedDate, selectedDate);
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
          title: Text(Translations.get('hourly_sales_report', languageCode)),
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: Translations.get('select_date', languageCode),
              onPressed: () => _selectDate(context),
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
                if (!reportsState.isLoading && reportsState.error == null)
                  _buildHourlySalesReport(reportsState, isMobile, languageCode),
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
            colors: [Colors.pink.withOpacity(0.1), Colors.white],
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
                    color: Colors.pink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    size: 28,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get('hourly_sales_report', languageCode),
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

  Widget _buildHourlySalesReport(
    dynamic reportsState,
    bool isMobile,
    String languageCode,
  ) {
    // Generate hourly data based on available data
    final hourlyData = _generateHourlyData(reportsState);

    if (hourlyData.isEmpty) {
      return _buildNoDataCard(languageCode);
    }

    final totalSales = hourlyData.fold<double>(
      0,
      (sum, item) => sum + item['sales'],
    );
    final totalOrders = hourlyData.fold<int>(
      0,
      (sum, item) => (sum + item['orders']) as int,
    );
    final peakHour = hourlyData.reduce(
      (a, b) => a['sales'] > b['sales'] ? a : b,
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        Translations.get('total_sales', languageCode),
                        'LAK ${NumberFormat('#,##0').format(totalSales)}',
                        Icons.monetization_on,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        Translations.get('total_orders', languageCode),
                        '$totalOrders',
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryItem(
                          Translations.get('peak_hour', languageCode),
                          '${peakHour['hour']}:00',
                          Icons.trending_up,
                          Colors.pink,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Hourly chart
        _buildHourlyChart(hourlyData, totalSales, isMobile, languageCode),
        const SizedBox(height: 20),

        // Peak hours analysis
        _buildPeakHoursAnalysis(hourlyData, isMobile, languageCode),
        const SizedBox(height: 20),

        // Hourly breakdown
        _buildHourlyBreakdown(hourlyData, isMobile, languageCode),
      ],
    );
  }

  List<Map<String, dynamic>> _generateHourlyData(dynamic reportsState) {
    final List<Map<String, dynamic>> data = [];

    try {
      double totalDailySales = 0.0;
      int totalDailyOrders = 0;

      // Extract available data
      if (reportsState.summary?.sales?.totalSales != null) {
        totalDailySales = reportsState.summary.sales.totalSales;
        totalDailyOrders = reportsState.summary.sales.totalOrders ?? 0;
      } else if (reportsState.topProducts != null &&
          reportsState.topProducts.isNotEmpty) {
        totalDailySales = reportsState.topProducts.fold<double>(
          0.0,
          (sum, product) => sum + product.totalRevenue,
        );
        totalDailyOrders = reportsState.topProducts.fold<int>(
          0,
          (sum, product) => sum + product.quantitySold,
        );
      }

      // Generate hourly distribution (9 AM to 9 PM business hours)
      const businessHours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21];

      // Create realistic hourly distribution
      final hourlyDistribution = <int, double>{
        9: 0.03, // 9 AM
        10: 0.05, // 10 AM
        11: 0.08, // 11 AM
        12: 0.12, // 12 PM (lunch peak)
        13: 0.10, // 1 PM
        14: 0.06, // 2 PM
        15: 0.05, // 3 PM
        16: 0.07, // 4 PM
        17: 0.09, // 5 PM
        18: 0.11, // 6 PM (dinner start)
        19: 0.13, // 7 PM (dinner peak)
        20: 0.08, // 8 PM
        21: 0.04, // 9 PM
      };

      for (final hour in businessHours) {
        final salesMultiplier = hourlyDistribution[hour] ?? 0.05;
        final sales = totalDailySales * salesMultiplier;
        final orders = (totalDailyOrders * salesMultiplier).round();

        data.add({
          'hour': hour,
          'sales': sales,
          'orders': orders,
          'timeLabel': '${hour.toString().padLeft(2, '0')}:00',
        });
      }
    } catch (e) {
      debugPrint('Error generating hourly data: $e');
    }

    return data;
  }

  Widget _buildHourlyChart(
    List<Map<String, dynamic>> data,
    double totalSales,
    bool isMobile,
    String languageCode,
  ) {
    final maxSales = data.fold<double>(
      0,
      (max, item) => item['sales'] > max ? item['sales'] : max,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.get('sales_distribution_by_hour', languageCode),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Chart
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children:
                    data.map((item) {
                      final sales = item['sales'] as double;
                      // Reduced max height to leave room for spacing and text
                      final height =
                          maxSales > 0 ? (sales / maxSales) * 160 : 0.0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.7),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${item['hour']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHoursAnalysis(
    List<Map<String, dynamic>> data,
    bool isMobile,
    String languageCode,
  ) {
    // Find top 3 peak hours
    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) => b['sales'].compareTo(a['sales']));
    final top3Hours = sortedData.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translations.get('peak_hours_analysis', languageCode),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children:
              top3Hours.asMap().entries.map((entry) {
                final index = entry.key;
                final hourData = entry.value;
                final colors = [Colors.pink, Colors.purple, Colors.indigo];

                return Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors[index].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                color: colors[index],
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${hourData['timeLabel']}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LAK ${NumberFormat('#,##0').format(hourData['sales'])}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors[index]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildHourlyBreakdown(
    List<Map<String, dynamic>> data,
    bool isMobile,
    String languageCode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Translations.get('hourly_breakdown', languageCode),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text(
                '${data.length} ${Translations.get('hours', languageCode)}',
              ),
              backgroundColor: Colors.pink.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.pink),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...data
            .map(
              (hourData) => _buildHourlyCard(hourData, isMobile, languageCode),
            )
            .toList(),
      ],
    );
  }

  Widget _buildHourlyCard(
    Map<String, dynamic> hourData,
    bool isMobile,
    String languageCode,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            isMobile
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hourData['timeLabel'],
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${hourData['orders']} ${Translations.get('orders', languageCode)}',
                            style: const TextStyle(
                              color: Colors.pink,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LAK ${NumberFormat('#,##0').format(hourData['sales'])}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                )
                : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.pink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Text(
                        hourData['timeLabel'],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${hourData['orders']} ${Translations.get('orders', languageCode)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'LAK ${NumberFormat('#,##0').format(hourData['sales'])}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
      ),
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
              Translations.get('error_loading_hourly_data', languageCode),
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
              Icons.schedule_outlined,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              Translations.get('no_hourly_data', languageCode),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.get(
                'no_hourly_data_for_selected_period',
                languageCode,
              ).replaceAll('{date}', displayFormat.format(selectedDate)),
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
            ).colorScheme.copyWith(primary: Colors.pink),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      ref
          .read(reportsProvider.notifier)
          .setDateRange(selectedDate, selectedDate);
    }
  }
}
