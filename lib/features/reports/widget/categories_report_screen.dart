import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../providers/reports_provider.dart';

/// Categories Report Screen
class CategoriesReportScreen extends ConsumerStatefulWidget {
  const CategoriesReportScreen({super.key});

  @override
  ConsumerState<CategoriesReportScreen> createState() =>
      _CategoriesReportScreenState();
}

class _CategoriesReportScreenState
    extends ConsumerState<CategoriesReportScreen> {
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
    final languageCode = ref.read(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: Text(Translations.get('categories_report', languageCode)),
          backgroundColor: Colors.orange,
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
                    PopupMenuItem(
                      value: 'revenue',
                      child: Text(Translations.get('revenue', languageCode)),
                    ),
                    PopupMenuItem(
                      value: 'quantity',
                      child: Text(Translations.get('quantity', languageCode)),
                    ),
                    PopupMenuItem(
                      value: 'name',
                      child: Text(Translations.get('name', languageCode)),
                    ),
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
                _buildHeader(languageCode),
                const SizedBox(height: 20),

                // Loading state
                if (reportsState.isLoading)
                  const Center(child: CircularProgressIndicator()),

                // Error state
                if (reportsState.error != null)
                  _buildErrorCard(reportsState.error!, languageCode),

                // Success state - show products grouped by category
                if (!reportsState.isLoading && reportsState.error == null)
                  _buildCategoriesList(
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
            colors: [Colors.orange.withOpacity(0.1), Colors.white],
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
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category,
                    size: 28,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get(
                          'category_performance_report',
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

  Widget _buildCategoriesList(
    List products,
    bool isMobile,
    String languageCode,
  ) {
    if (products.isEmpty) {
      return _buildNoDataCard(languageCode);
    }

    // Group products by category
    final Map<String, List> categoriesMap = {};
    for (final product in products) {
      final category = product.category ?? 'Uncategorized';
      if (!categoriesMap.containsKey(category)) {
        categoriesMap[category] = [];
      }
      categoriesMap[category]!.add(product);
    }

    // Calculate category totals
    final List<Map<String, dynamic>> categories = [];
    categoriesMap.forEach((categoryName, categoryProducts) {
      final totalRevenue = categoryProducts.fold<double>(
        0,
        (sum, item) => sum + item.totalRevenue,
      );
      final totalQuantity = categoryProducts.fold<int>(
        0,
        (sum, item) => sum + (item.quantitySold as num).toInt(),
      );

      categories.add({
        'name': categoryName,
        'products': categoryProducts,
        'totalRevenue': totalRevenue,
        'totalQuantity': totalQuantity,
        'productCount': categoryProducts.length,
      });
    });

    // Sort categories
    switch (sortBy) {
      case 'revenue':
        categories.sort(
          (a, b) => b['totalRevenue'].compareTo(a['totalRevenue']),
        );
        break;
      case 'quantity':
        categories.sort(
          (a, b) => b['totalQuantity'].compareTo(a['totalQuantity']),
        );
        break;
      case 'name':
        categories.sort((a, b) => a['name'].compareTo(b['name']));
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
                    Translations.get('categories', languageCode),
                    '${categories.length}',
                    Icons.category,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    Translations.get('total_revenue', languageCode),
                    'LAK ${NumberFormat('#,##0').format(categories.fold<double>(0, (sum, item) => sum + item['totalRevenue']))}',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      Translations.get('total_products', languageCode),
                      '${products.length}',
                      Icons.inventory,
                      Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Categories list header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Translations.get('category', languageCode),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Chip(
              label: Text(
                Translations.get('sorted_by', languageCode) +
                    ' ${sortBy.toUpperCase()}',
              ),
              backgroundColor: Colors.orange.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Category cards
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return _buildCategoryCard(category, index + 1, isMobile);
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

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
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
            // Header row with rank and category name
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            if (isMobile) ...[
              _buildStatRow('Products', '${category['productCount']}'),
              const SizedBox(height: 8),
              _buildStatRow('Total Quantity', '${category['totalQuantity']}'),
              const SizedBox(height: 8),
              _buildStatRow(
                'Revenue',
                'LAK ${NumberFormat('#,##0').format(category['totalRevenue'])}',
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Products',
                      '${category['productCount']}',
                      Icons.inventory,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Quantity',
                      '${category['totalQuantity']}',
                      Icons.shopping_cart,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Revenue',
                      'LAK ${NumberFormat('#,##0').format(category['totalRevenue'])}',
                      Icons.monetization_on,
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
              Translations.get('error_loading_categories', languageCode),
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
              Icons.category_outlined,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              Translations.get('no_category_data', languageCode),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.get('no_category_data', languageCode),
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
            ).colorScheme.copyWith(primary: Colors.orange),
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
