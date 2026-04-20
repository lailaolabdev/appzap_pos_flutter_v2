import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';

/// Sales Summary Report — Loyverse-style UI
class DailySalesReportScreen extends ConsumerStatefulWidget {
  const DailySalesReportScreen({super.key});

  @override
  ConsumerState<DailySalesReportScreen> createState() =>
      _DailySalesReportScreenState();
}

class _DailySalesReportScreenState
    extends ConsumerState<DailySalesReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Default: last 30 days
      final now = DateTime.now();
      ref
          .read(reportsProvider.notifier)
          .setDateRange(now.subtract(const Duration(days: 30)), now);
    });
  }

  void _shiftDateRange(int days) {
    final state = ref.read(reportsProvider);
    final duration = state.endDate.difference(state.startDate);
    final newStart = state.startDate.add(Duration(days: days));
    final newEnd = newStart.add(duration);
    // Don't go past today
    final now = DateTime.now();
    if (newEnd.isAfter(now)) return;
    ref.read(reportsProvider.notifier).setDateRange(newStart, newEnd);
  }

  Future<void> _pickDateRange() async {
    final state = ref.read(reportsProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state.startDate,
        end: state.endDate,
      ),
    );
    if (picked != null) {
      ref.read(reportsProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final lang = ref.watch(localizationProvider).languageCode;
    final summary = state.summary;
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar — Loyverse green header style but using our orange
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Translations.get('sales_summary', lang),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Date Range Bar (< 9 Mar 2026 - 7 Apr 2026 >) ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.grey.shade600),
                  onPressed: () => _shiftDateRange(-7),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDateRange,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                  onPressed: () => _shiftDateRange(7),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // ─── Content ───
          Expanded(
            child:
                state.isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange,
                      ),
                    )
                    : summary == null
                    ? Center(
                      child: Text(
                        Translations.get('no_data', lang),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh:
                          () => ref.read(reportsProvider.notifier).refresh(),
                      child: ListView(
                        children: [
                          // ─── Summary Cards Row ───
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Gross Sales
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: Translations.get(
                                      'gross_sales',
                                      lang,
                                    ),
                                    amount: summary.sales.totalSales,
                                    isLarge: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Refunds
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: Translations.get('refunds', lang),
                                    amount: 0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Discounts
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: Translations.get('discount', lang),
                                    amount: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Progress bar
                          Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor:
                                  summary.sales.totalSales > 0 ? 1.0 : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ─── Detail Rows ───
                          _buildDetailRow(
                            Translations.get('gross_sales', lang),
                            CurrencyFormatter.formatLAKWithSymbol(
                              summary.sales.totalSales,
                            ),
                          ),
                          _buildDetailRow(
                            Translations.get('orders_count', lang),
                            '${summary.sales.totalOrders}',
                          ),
                          _buildDetailRow(
                            Translations.get('avg_sale', lang),
                            CurrencyFormatter.formatLAKWithSymbol(
                              summary.sales.averageOrderValue,
                            ),
                          ),
                          if (summary.sales.totalTax > 0)
                            _buildDetailRow(
                              Translations.get('tax', lang),
                              CurrencyFormatter.formatLAKWithSymbol(
                                summary.sales.totalTax,
                              ),
                            ),

                          // ─── Payment Breakdown ───
                          if (summary.payments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(height: 8, color: Colors.grey.shade100),
                            const SizedBox(height: 8),
                            ...summary.payments.entries.map(
                              (e) => _buildDetailRow(
                                e.key.replaceAll('_', ' '),
                                CurrencyFormatter.formatLAKWithSymbol(e.value),
                              ),
                            ),
                          ],

                          // ─── Daily Breakdown ───
                          if (state.dailyBreakdown.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(height: 8, color: Colors.grey.shade100),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                Translations.get('gross_sales', lang),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...state.dailyBreakdown.map(
                              (day) => _buildDetailRow(
                                DateFormat('d MMM yyyy').format(day.date),
                                CurrencyFormatter.formatLAKWithSymbol(
                                  day.grossSales,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    bool isLarge = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatLAKWithSymbol(amount),
          style: TextStyle(
            fontSize: isLarge ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
