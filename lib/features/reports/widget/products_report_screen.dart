import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/models/report.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/responsive.dart';
import '../providers/reports_provider.dart';

/// Products Performance Report Screen
class ProductsReportScreen extends ConsumerStatefulWidget {
  const ProductsReportScreen({super.key});

  @override
  ConsumerState<ProductsReportScreen> createState() =>
      _ProductsReportScreenState();
}

class _ProductsReportScreenState extends ConsumerState<ProductsReportScreen> {
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
    final languageCode = ref.watch(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: Text(Translations.get('products_report', languageCode)),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: Translations.get('sort_by', languageCode),
              onSelected: (value) {
                setState(() {
                  sortBy = value;
                });
                // TODO: Re-sort the data
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'revenue',
                      child: Text(Translations.get('revenue', languageCode)),
                    ),
                    PopupMenuItem(
                      value: 'quantity',
                      child: Text(
                        Translations.get('total_quantity', languageCode),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'name',
                      child: Text(Translations.get('name', languageCode)),
                    ),
                  ],
            ),
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
                if (!reportsState.isLoading && reportsState.error == null)
                  _buildProductsList(
                    reportsState.topProducts,
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
            colors: [Colors.blue.withOpacity(0.1), Colors.white],
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
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    size: 28,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get(
                          'product_performance_report',
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

  Widget _buildProductsList(
    List<SalesByProductItem> products,
    bool isMobile,
    String languageCode,
  ) {
    if (products.isEmpty) {
      return _buildNoDataCard(languageCode);
    }

    // Sort products based on sortBy
    final sortedProducts = List<SalesByProductItem>.from(products);
    switch (sortBy) {
      case 'revenue':
        sortedProducts.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
        break;
      case 'quantity':
        sortedProducts.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
        break;
      case 'name':
        sortedProducts.sort((a, b) => a.productName.compareTo(b.productName));
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
                    Translations.get('total_products', languageCode),
                    '${products.length}',
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    Translations.get('total_revenue', languageCode),
                    'LAK ${NumberFormat('#,##0').format(products.fold<double>(0, (sum, item) => sum + item.totalRevenue))}',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('total_quantity', languageCode),
                      '${products.fold<int>(0, (sum, item) => sum + item.quantitySold)}',
                      Icons.shopping_cart,
                      Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Products list header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Translations.get('top_products', languageCode),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text(
                '${Translations.get('sorted_by', languageCode)} ${Translations.get(_getSortLabel(sortBy), languageCode)}',
              ),
              backgroundColor: Colors.blue.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Products cards
        ...sortedProducts.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return _buildProductCard(product, index + 1, isMobile, languageCode);
        }).toList(),
      ],
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'revenue':
        return 'revenue';
      case 'quantity':
        return 'quantity';
      case 'name':
        return 'name';
      default:
        return '';
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

  Widget _buildProductCard(
    SalesByProductItem product,
    int rank,
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
            // Header row with rank and product name
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRankColor(rank).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getRankColor(rank),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.category!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.neutral600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            if (isMobile) ...[
              _buildStatRow(
                'quantity_sold',
                '${product.quantitySold}',
                languageCode,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                'revenue',
                'LAK ${NumberFormat('#,##0').format(product.totalRevenue)}',
                languageCode,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                'avg_price',
                'LAK ${NumberFormat('#,##0').format(product.totalRevenue / (product.quantitySold > 0 ? product.quantitySold : 1))}',
                languageCode,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'quantity',
                      '${product.quantitySold}',
                      Icons.shopping_cart,
                      languageCode,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'revenue',
                      'LAK ${NumberFormat('#,##0').format(product.totalRevenue)}',
                      Icons.monetization_on,
                      languageCode,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'avg_price',
                      'LAK ${NumberFormat('#,##0').format(product.totalRevenue / (product.quantitySold > 0 ? product.quantitySold : 1))}',
                      Icons.attach_money,
                      languageCode,
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

  Widget _buildStatRow(String labelKey, String value, String languageCode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          Translations.get(labelKey, languageCode),
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

  Widget _buildStatColumn(
    String labelKey,
    String value,
    IconData icon,
    String languageCode,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.neutral600),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          Translations.get(labelKey, languageCode),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral600),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) {
      switch (rank) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.grey.shade600;
        case 3:
          return Colors.brown;
        default:
          return Colors.blue;
      }
    }
    return Colors.blue;
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
              Translations.get('error_loading_products', languageCode),
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
              Icons.inventory_2_outlined,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              Translations.get('no_products_data', languageCode),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.get(
                'no_product_sales_data_found_for_the_selected_period',
                languageCode,
              ).replaceAll(
                '{date}',
                '${displayFormat.format(startDate)} - ${displayFormat.format(endDate)}',
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
            ).colorScheme.copyWith(primary: Colors.blue),
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
