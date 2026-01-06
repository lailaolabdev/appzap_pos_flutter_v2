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
import '../widgets/stock_movement_tracker.dart';

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
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          title: const Text('Inventory Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Stock Movements',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StockMovementTracker(),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter',
              onSelected: _setStatusFilter,
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: null,
                      child: Text(
                        'All Items',
                        style: TextStyle(
                          fontWeight:
                              inventoryState.statusFilter == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'low_stock',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Low Stock (${inventoryState.lowStockCount})',
                            style: TextStyle(
                              fontWeight:
                                  inventoryState.statusFilter == 'low_stock'
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
                              fontWeight:
                                  inventoryState.statusFilter == 'out_of_stock'
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
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => _showLowStockModal(context, inventoryState),
                          child: _buildAlertCard(
                            inventoryState.lowStockCount.toString(),
                            'Low Stock',
                            Icons.warning_amber,
                            Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () =>
                                  _showOutOfStockModal(context, inventoryState),
                          child: _buildAlertCard(
                            inventoryState.outOfStockCount.toString(),
                            'Out of Stock',
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => _showAlertsModal(context, inventoryState),
                          child: _buildAlertCard(
                            inventoryState.totalAlerts.toString(),
                            'Total Alerts',
                            Icons.notifications_active,
                            AppTheme.primaryOrange,
                          ),
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
                  suffixIcon:
                      _searchController.text.isNotEmpty
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
              child:
                  inventoryState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : inventoryState.error != null
                      ? Center(
                        child: ErrorBanner(
                          message: inventoryState.error!,
                          onDismiss:
                              () =>
                                  ref
                                      .read(inventoryProvider.notifier)
                                      .refresh(),
                        ),
                      )
                      : inventoryState.items.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                        onRefresh:
                            () =>
                                ref.read(inventoryProvider.notifier).refresh(),
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

  Widget _buildAlertCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
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
            style: const TextStyle(fontSize: 11, color: AppTheme.neutral600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    final stockColor =
        item.currentStock == 0
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
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.neutral500,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.trending_up, size: 20),
              tooltip: 'Adjust Stock',
              onPressed: () => _adjustStock(item),
            ),
          ],
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Show Low Stock Items Modal
  void _showLowStockModal(BuildContext context, InventoryState state) {
    final lowStockItems = state.items.where((item) => item.isLowStock).toList();
    final isMobile = Responsive.isMobile(context);

    final content = _buildInventoryListModal(
      title: 'Low Stock Items',
      icon: Icons.warning_amber,
      iconColor: Colors.orange,
      items: lowStockItems,
      emptyMessage: 'No low stock items',
    );

    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => content,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              child: Container(width: 600, height: 700, child: content),
            ),
      );
    }
  }

  // Show Out of Stock Items Modal
  void _showOutOfStockModal(BuildContext context, InventoryState state) {
    final outOfStockItems =
        state.items.where((item) => item.currentStock == 0).toList();
    final isMobile = Responsive.isMobile(context);

    final content = _buildInventoryListModal(
      title: 'Out of Stock Items',
      icon: Icons.error,
      iconColor: Colors.red,
      items: outOfStockItems,
      emptyMessage: 'No out of stock items',
    );

    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => content,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              child: Container(width: 600, height: 700, child: content),
            ),
      );
    }
  }

  // Show All Alerts Modal
  void _showAlertsModal(BuildContext context, InventoryState state) {
    final isMobile = Responsive.isMobile(context);

    final content = _buildAlertsDetailsModal(
      title: 'Inventory Alerts',
      icon: Icons.notifications_active,
      iconColor: AppTheme.primaryOrange,
      alerts: state.alerts,
    );

    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => content,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              child: Container(width: 600, height: 700, child: content),
            ),
      );
    }
  }

  // Build Inventory List Modal Content
  Widget _buildInventoryListModal({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<InventoryItem> items,
    required String emptyMessage,
  }) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body:
          items.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: AppTheme.neutral300),
                    const SizedBox(height: 16),
                    Text(
                      emptyMessage,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: iconColor.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: iconColor, size: 28),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (item.sku != null)
                            Text(
                              'SKU: ${item.sku}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 14,
                                color: iconColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: ${item.currentStock} ${item.unit}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                          if (item.lowStockThreshold > 0)
                            Text(
                              'Threshold: ${item.lowStockThreshold}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral600,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            'Value: ${CurrencyFormatter.format(item.totalValue)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral600,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _adjustStock(item);
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Adjust'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  // Build Alerts Details Modal Content
  Widget _buildAlertsDetailsModal({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<InventoryAlert> alerts,
  }) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body:
          alerts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active alerts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.neutral500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your inventory is in good shape!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral400,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final alertColor = _getAlertColor(alert.alertType);
                  final alertIcon = _getAlertIcon(alert.alertType);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: alertColor.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: alertColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(alertIcon, color: alertColor, size: 28),
                      ),
                      title: Text(
                        alert.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (alert.inventoryItemId.isNotEmpty)
                            Text(
                              'Item ID: ${alert.inventoryItemId}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.neutral500,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: alertColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getAlertTypeLabel(alert.alertType),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: alertColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 14,
                                color: alertColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Current: ${alert.currentStock}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: alertColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (alert.threshold != null) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.warning_amber,
                                  size: 14,
                                  color: AppTheme.neutral600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Threshold: ${alert.threshold}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.neutral600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Alert created: ${DateFormatter.formatRelative(alert.createdAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Color _getAlertColor(String? alertType) {
    switch (alertType?.toLowerCase()) {
      case 'out_of_stock':
        return Colors.red;
      case 'low_stock':
        return Colors.orange;
      case 'expiring_soon':
        return Colors.amber;
      default:
        return AppTheme.primaryOrange;
    }
  }

  IconData _getAlertIcon(String? alertType) {
    switch (alertType?.toLowerCase()) {
      case 'out_of_stock':
        return Icons.error;
      case 'low_stock':
        return Icons.warning_amber;
      case 'expiring_soon':
        return Icons.schedule;
      default:
        return Icons.notifications_active;
    }
  }

  String _getAlertTypeLabel(String? alertType) {
    switch (alertType?.toLowerCase()) {
      case 'out_of_stock':
        return 'OUT OF STOCK';
      case 'low_stock':
        return 'LOW STOCK';
      case 'expiring_soon':
        return 'EXPIRING SOON';
      default:
        return 'ALERT';
    }
  }
}
