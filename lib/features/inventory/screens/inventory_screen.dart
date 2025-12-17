import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/inventory.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/inventory_provider.dart';
import '../widgets/adjust_stock_dialog.dart';

/// Inventory management screen - Advanced inventory tracking (USP #2)
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(inventoryProvider.notifier).search(_searchController.text);
  }

  Future<void> _adjustStock(InventoryItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AdjustStockDialog(item: item),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock adjusted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  void _setStatusFilter(String? status) {
    ref.read(inventoryProvider.notifier).setStatusFilter(status);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final valuationAsync = ref.watch(inventoryValuationProvider);
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer: isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          title: const Text('Inventory Management'),
          actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: _setStatusFilter,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text(
                  'All Items',
                  style: TextStyle(
                    fontWeight: inventoryState.statusFilter == null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'low_stock',
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Low Stock (${inventoryState.lowStockCount})',
                      style: TextStyle(
                        fontWeight: inventoryState.statusFilter == 'low_stock'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'out_of_stock',
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Out of Stock (${inventoryState.outOfStockCount})',
                      style: TextStyle(
                        fontWeight: inventoryState.statusFilter == 'out_of_stock'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Valuation card
                valuationAsync.when(
                  data: (valuation) {
                    if (valuation == null) return const SizedBox.shrink();
                    return _buildSummaryCard(
                      'Total Inventory Value',
                      CurrencyFormatter.format(valuation.totalValue),
                      '${valuation.totalItems} items',
                      Icons.attach_money,
                      AppTheme.success,
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 12),

                // Alerts row
                Row(
                  children: [
                    Expanded(
                      child: _buildAlertCard(
                        inventoryState.lowStockCount.toString(),
                        'Low Stock',
                        Icons.warning_amber,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAlertCard(
                        inventoryState.outOfStockCount.toString(),
                        'Out of Stock',
                        Icons.error,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAlertCard(
                        inventoryState.totalAlerts.toString(),
                        'Total Alerts',
                        Icons.notifications_active,
                        AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(inventoryProvider.notifier).search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.neutral50,
              ),
            ),
          ),

          // Inventory list
          Expanded(
            child: inventoryState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : inventoryState.error != null
                    ? Center(
                        child: ErrorBanner(
                          message: inventoryState.error!,
                          onDismiss: () => ref.read(inventoryProvider.notifier).refresh(),
                        ),
                      )
                    : inventoryState.items.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
                            child: ListView.builder(
                              itemCount: inventoryState.items.length,
                              itemBuilder: (context, index) {
                                final item = inventoryState.items[index];
                                return _buildInventoryCard(item);
                              },
                            ),
                          ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    final stockColor = item.currentStock == 0
        ? Colors.red
        : item.isLowStock
            ? Colors.orange
            : AppTheme.success;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: stockColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.currentStock.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: stockColor,
                ),
              ),
              Text(
                item.unit,
                style: TextStyle(
                  fontSize: 10,
                  color: stockColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (item.sku != null || item.barcode != null)
              Text(
                [
                  if (item.sku != null) 'SKU: ${item.sku}',
                  if (item.barcode != null) 'Barcode: ${item.barcode}',
                ].join(' • '),
                style: const TextStyle(fontSize: 11),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  item.currentStock == 0
                      ? Icons.error
                      : item.isLowStock
                          ? Icons.warning_amber
                          : Icons.check_circle,
                  size: 14,
                  color: stockColor,
                ),
                const SizedBox(width: 4),
                Text(
                  item.currentStock == 0
                      ? 'Out of Stock'
                      : item.isLowStock
                          ? 'Low Stock (threshold: ${item.lowStockThreshold})'
                          : 'In Stock',
                  style: TextStyle(
                    fontSize: 12,
                    color: stockColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Value: ${CurrencyFormatter.format(item.totalValue)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.neutral600),
            ),
            if (item.lastStockUpdate != null)
              Text(
                'Updated: ${DateFormatter.formatRelative(item.lastStockUpdate!)}',
                style: const TextStyle(fontSize: 10, color: AppTheme.neutral500),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Adjust Stock',
          onPressed: () => _adjustStock(item),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.neutral300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No inventory items found.'
                : 'No matching items found for "${_searchController.text}".',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.neutral500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
