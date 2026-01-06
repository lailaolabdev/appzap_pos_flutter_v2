import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/inventory.dart';
import '../providers/inventory_provider.dart';

class InventoryAnalytics extends ConsumerWidget {
  const InventoryAnalytics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryProvider);
    final notifier = ref.read(inventoryProvider.notifier);

    if (inventoryState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final analytics = _calculateAnalytics(
      inventoryState.items,
      notifier.categories,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Analytics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Items',
                  analytics.totalItems.toString(),
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Value',
                  '\$${analytics.totalValue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Low Stock Items',
                  analytics.lowStockItems.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Out of Stock',
                  analytics.outOfStockItems.toString(),
                  Icons.error,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stock Status Distribution
          Text(
            'Stock Status Distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusRow(
                    context,
                    'Healthy Stock',
                    analytics.healthyStockItems,
                    analytics.totalItems,
                    Colors.green,
                  ),
                  _buildStatusRow(
                    context,
                    'Low Stock',
                    analytics.lowStockItems,
                    analytics.totalItems,
                    Colors.orange,
                  ),
                  _buildStatusRow(
                    context,
                    'Out of Stock',
                    analytics.outOfStockItems,
                    analytics.totalItems,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category Breakdown
          Text(
            'Category Breakdown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children:
                    analytics.categoryBreakdown.entries.map((entry) {
                      final category = entry.key;
                      final data = entry.value;
                      return _buildCategoryRow(context, category, data);
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Value Items
          Text(
            'Top Value Items',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children:
                  analytics.topValueItems.take(5).map((item) {
                    final value = item.currentStock * (item.costPerUnit ?? 0.0);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.inventory, color: Colors.blue),
                      ),
                      title: Text(item.name),
                      subtitle: Text('${item.currentStock} ${item.unit}'),
                      trailing: Text(
                        '\$${value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Low Stock Alert Items
          if (analytics.lowStockItems > 0) ...[
            Text(
              'Items Requiring Attention',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children:
                    inventoryState.items
                        .where(
                          (item) => item.isLowStock || item.currentStock == 0,
                        )
                        .take(10)
                        .map((item) {
                          final isOutOfStock = item.currentStock == 0;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (isOutOfStock
                                      ? Colors.red
                                      : Colors.orange)
                                  .withOpacity(0.1),
                              child: Icon(
                                isOutOfStock ? Icons.error : Icons.warning,
                                color:
                                    isOutOfStock ? Colors.red : Colors.orange,
                              ),
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              isOutOfStock
                                  ? 'Out of stock'
                                  : 'Low stock: ${item.currentStock}/${item.minStockLevel} ${item.unit}',
                            ),
                            trailing: Chip(
                              label: Text(
                                isOutOfStock ? 'OUT' : 'LOW',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor:
                                  isOutOfStock
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                              labelStyle: TextStyle(
                                color:
                                    isOutOfStock ? Colors.red : Colors.orange,
                              ),
                            ),
                          );
                        })
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
              Text(
                '$count (${(percentage * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    String category,
    CategoryData data,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${data.itemCount} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${data.totalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (data.lowStockCount > 0)
                Text(
                  '${data.lowStockCount} low stock',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  InventoryAnalyticsData _calculateAnalytics(
    List<InventoryItem> items,
    List<String> categories,
  ) {
    final totalItems = items.length;
    final totalValue = items.fold(
      0.0,
      (sum, item) => sum + (item.currentStock * (item.costPerUnit ?? 0.0)),
    );

    final lowStockItems = items.where((item) => item.isLowStock).length;
    final outOfStockItems =
        items.where((item) => item.currentStock == 0).length;
    final healthyStockItems = totalItems - lowStockItems - outOfStockItems;

    final categoryBreakdown = <String, CategoryData>{};
    for (final category in categories) {
      final categoryItems = items.where((item) => item.category == category);
      final itemCount = categoryItems.length;
      final totalValue = categoryItems.fold(
        0.0,
        (sum, item) => sum + (item.currentStock * (item.costPerUnit ?? 0.0)),
      );
      final lowStockCount =
          categoryItems.where((item) => item.isLowStock).length;

      if (itemCount > 0) {
        categoryBreakdown[category] = CategoryData(
          itemCount: itemCount,
          totalValue: totalValue,
          lowStockCount: lowStockCount,
        );
      }
    }

    final topValueItems = List<InventoryItem>.from(items)..sort((a, b) {
      final valueA = a.currentStock * (a.costPerUnit ?? 0.0);
      final valueB = b.currentStock * (b.costPerUnit ?? 0.0);
      return valueB.compareTo(valueA);
    });

    return InventoryAnalyticsData(
      totalItems: totalItems,
      totalValue: totalValue,
      lowStockItems: lowStockItems,
      outOfStockItems: outOfStockItems,
      healthyStockItems: healthyStockItems,
      categoryBreakdown: categoryBreakdown,
      topValueItems: topValueItems,
    );
  }
}

class InventoryAnalyticsData {
  final int totalItems;
  final double totalValue;
  final int lowStockItems;
  final int outOfStockItems;
  final int healthyStockItems;
  final Map<String, CategoryData> categoryBreakdown;
  final List<InventoryItem> topValueItems;

  InventoryAnalyticsData({
    required this.totalItems,
    required this.totalValue,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.healthyStockItems,
    required this.categoryBreakdown,
    required this.topValueItems,
  });
}

class CategoryData {
  final int itemCount;
  final double totalValue;
  final int lowStockCount;

  CategoryData({
    required this.itemCount,
    required this.totalValue,
    required this.lowStockCount,
  });
}
