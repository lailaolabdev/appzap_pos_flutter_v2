import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';
import 'report_date_filter.dart';

/// Sales by Employee Report — Loyverse style
class StaffReportScreen extends ConsumerStatefulWidget {
  const StaffReportScreen({super.key});

  @override
  ConsumerState<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends ConsumerState<StaffReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final lang = ref.watch(localizationProvider).languageCode;
    final staff = state.employeePerformance;

    final totalSales = staff.fold<double>(0, (s, e) => s + e.totalSales);
    final totalOrders = staff.fold<int>(0, (s, e) => s + e.totalOrders);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Translations.get('sales_by_employee', lang),
          style: const TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          ReportDateFilter(
            startDate: state.startDate,
            endDate: state.endDate,
            lang: lang,
            onChanged: (range) {
              ref.read(reportsProvider.notifier).setDateRange(range.start, range.end);
            },
          ),
          const Divider(height: 1),
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${staff.length} ${Translations.get('staff', lang)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                  ),
                ),
                Text(
                  '$totalOrders ${Translations.get('orders_count', lang)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 16),
                Text(
                  CurrencyFormatter.formatLAKWithSymbol(totalSales),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : staff.isEmpty
                    ? Center(child: Text(Translations.get('no_data', lang), style: TextStyle(color: Colors.grey.shade400)))
                    : RefreshIndicator(
                        onRefresh: () => ref.read(reportsProvider.notifier).refresh(),
                        child: ListView.separated(
                          itemCount: staff.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, i) {
                            final e = staff[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
                                    child: Text(
                                      e.staffName.isNotEmpty ? e.staffName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: AppTheme.primaryOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Name + orders
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.staffName,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${e.totalOrders} ${Translations.get('orders_count', lang)}  |  ${e.itemsSold} ${Translations.get('items', lang)}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Sales amount
                                  Text(
                                    CurrencyFormatter.formatLAKWithSymbol(e.totalSales),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
