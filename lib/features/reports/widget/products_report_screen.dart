import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';
import 'report_date_filter.dart';

/// Sales by Item Report — Loyverse style
class ProductsReportScreen extends ConsumerStatefulWidget {
  const ProductsReportScreen({super.key});

  @override
  ConsumerState<ProductsReportScreen> createState() =>
      _ProductsReportScreenState();
}

class _ProductsReportScreenState extends ConsumerState<ProductsReportScreen> {
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
    final products = state.topProducts;

    final totalQty = products.fold<int>(0, (s, p) => s + p.quantitySold);
    final totalRevenue = products.fold<double>(0, (s, p) => s + p.totalRevenue);

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
          Translations.get('sales_by_item', lang),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
              ref
                  .read(reportsProvider.notifier)
                  .setDateRange(range.start, range.end);
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
                    '${products.length} ${Translations.get('items', lang)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Text(
                  '${Translations.get('qty_sold', lang)}: $totalQty',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  CurrencyFormatter.formatLAKWithSymbol(totalRevenue),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                    ? Center(
                      child: Text(
                        Translations.get('no_data', lang),
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh:
                          () => ref.read(reportsProvider.notifier).refresh(),
                      child: ListView.separated(
                        itemCount: products.length,
                        separatorBuilder:
                            (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (_, i) {
                          final p = products[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          i < 3
                                              ? AppTheme.primaryOrange
                                              : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.productName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (p.category != null)
                                        Text(
                                          p.category!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${p.quantitySold}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.formatLAKWithSymbol(
                                    p.totalRevenue,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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
