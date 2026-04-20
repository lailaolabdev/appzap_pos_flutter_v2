import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/inventory.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../pos/providers/pos_provider.dart';
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
    final languageCode = ref.read(localizationProvider).languageCode;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AdjustStockDialog(item: item),
    );

    if (result == true && mounted) {
      // Reload inventory to show updated stock
      await ref.read(inventoryProvider.notifier).loadInventory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.get('stock_adjust_succ', languageCode)),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final productsState = ref.watch(productsProvider);
    final valuationAsync = ref.watch(inventoryValuationProvider);
    final isMobile = Responsive.isMobile(context);
    final languageCode = ref.watch(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer:
            const Drawer(child: AppSidebar(isInDrawer: true)),
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBackground,
          surfaceTintColor: AppTheme.scaffoldBackground,
          title: Text(Translations.get('inventory_manage', languageCode)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: Translations.get('refresh', languageCode),
              onPressed: () {
                // Refresh both inventory and products data
                ref.read(inventoryProvider.notifier).refresh();
                ref.read(productsProvider.notifier).refresh();
              },
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
                        Translations.get('total_inventory_value', languageCode),
                        CurrencyFormatter.format(valuation.totalValue),
                        '${valuation.totalItems} ${Translations.get('items', languageCode)}',
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
                            inventoryState.items
                                .where((item) {
                                  // Only count items that have corresponding products
                                  final product = _findProductByName(
                                    productsState.products,
                                    item.name,
                                  );
                                  return product != null &&
                                      item.isLowStock &&
                                      item.currentStock > 0;
                                })
                                .length
                                .toString(),
                            Translations.get('low_stock', languageCode),
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
                            inventoryState.items
                                .where((item) {
                                  // Only count items that have corresponding products
                                  final product = _findProductByName(
                                    productsState.products,
                                    item.name,
                                  );
                                  return product != null &&
                                      item.currentStock == 0;
                                })
                                .length
                                .toString(),
                            Translations.get('out_of_stock', languageCode),
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
                            Translations.get('total_alert', languageCode),
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
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: Translations.get(
                    'search_name_sku_barcode',
                    languageCode,
                  ),
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
                        onRefresh: () async {
                          // Refresh both inventory and products data
                          await ref.read(inventoryProvider.notifier).refresh();
                          await ref.read(productsProvider.notifier).refresh();
                        },
                        child: ListView.builder(
                          itemCount:
                              inventoryState.items.where((item) {
                                // Only show inventory items that have corresponding products
                                final product = _findProductByName(
                                  productsState.products,
                                  item.name,
                                );
                                return product != null;
                              }).length,
                          itemBuilder: (context, index) {
                            // Filter items that have corresponding products
                            final filteredItems =
                                inventoryState.items.where((item) {
                                  final product = _findProductByName(
                                    productsState.products,
                                    item.name,
                                  );
                                  return product != null;
                                }).toList();

                            final item = filteredItems[index];
                            // Find corresponding product
                            final product = _findProductByName(
                              productsState.products,
                              item.name,
                            );
                            return _buildInventoryCard(item, product);
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

  Widget _buildInventoryCard(InventoryItem item, Product? product) {
    final languageCode = ref.watch(localizationProvider).languageCode;
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
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Product Stock Info
            if (product != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${Translations.get('product_stock', languageCode)}: ${item.currentStock}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Show tracked indicator if product has inventory data
                    if (product.inventory != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.track_changes,
                        size: 12,
                        color: AppTheme.success,
                      ),
                      Text(
                        Translations.get('tracked', languageCode),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (product != null) const SizedBox(height: 4),
            if (item.sku != null || item.barcode != null)
              Text(
                [
                  if (item.sku != null)
                    '${Translations.get('sku', languageCode)}: ${item.sku}',
                  if (item.barcode != null)
                    '${Translations.get('barcode', languageCode)}: ${item.barcode}',
                ].join(' • '),
                style: const TextStyle(fontSize: 11),
              ),
            const SizedBox(height: 4),
            // Stock Status Row
            Row(
              children: [
                Expanded(
                  child: Row(
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
                      Flexible(
                        child: Text(
                          item.currentStock == 0
                              ? Translations.get('out_of_stock', languageCode)
                              : item.isLowStock
                              ? '${Translations.get('low_stock', languageCode)} (${item.lowStockThreshold})'
                              : Translations.get('in_stock', languageCode),
                          style: TextStyle(
                            fontSize: 12,
                            color: stockColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Inventory vs Product Stock Comparison
                if (product != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStockSyncColor(
                        item.currentStock,
                        product.inventory?.currentStock ?? 0,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStockSyncStatus(
                        item.currentStock,
                        product.inventory?.currentStock ?? 0,
                        languageCode,
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStockSyncColor(
                          item.currentStock,
                          product.inventory?.currentStock ?? 0,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (item.lastStockUpdate != null)
              Text(
                '${Translations.get('updated', languageCode)}: ${DateFormatter.formatRelative(item.lastStockUpdate!)}',
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
              tooltip: Translations.get('adjust_stock', languageCode),
              onPressed: () => _adjustStock(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final languageCode = ref.watch(localizationProvider).languageCode;

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
                ? Translations.get('no_inventory_items', languageCode)
                : '${Translations.get('no_matching_items', languageCode)} "${_searchController.text}".',
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
    final languageCode = ref.watch(localizationProvider).languageCode;
    final lowStockItems =
        state.items
            .where((item) => item.isLowStock && item.currentStock > 0)
            .toList();
    final isMobile = Responsive.isMobile(context);

    final content = _buildInventoryListModal(
      title: Translations.get('low_stock_item', languageCode),
      icon: Icons.warning_amber,
      iconColor: Colors.orange,
      items: lowStockItems,
      emptyMessage: Translations.get('no_low_stock_items', languageCode),
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
    final languageCode = ref.watch(localizationProvider).languageCode;
    final outOfStockItems =
        state.items.where((item) => item.currentStock == 0).toList();
    final isMobile = Responsive.isMobile(context);

    final content = _buildInventoryListModal(
      title: Translations.get('out_of_stock_items', languageCode),
      icon: Icons.error,
      iconColor: Colors.red,
      items: outOfStockItems,
      emptyMessage: Translations.get('no_out_of_stock_items', languageCode),
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
    final languageCode = ref.watch(localizationProvider).languageCode;
    final isMobile = Responsive.isMobile(context);

    final content = _buildAlertsDetailsModal(
      title: Translations.get('inventory_alerts', languageCode),
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
    final languageCode = ref.watch(localizationProvider).languageCode;
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
            tooltip: Translations.get('close', languageCode),
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
                              '${Translations.get('sku', languageCode)}: ${item.sku}',
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
                              '${Translations.get('threshold', languageCode)}: ${item.lowStockThreshold}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral600,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            '${Translations.get('value', languageCode)}: ${CurrencyFormatter.format(item.totalValue)}',
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
                        label: Text(Translations.get('Adjust', languageCode)),
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
    final languageCode = ref.watch(localizationProvider).languageCode;

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
            tooltip: Translations.get('close', languageCode),
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
                      Translations.get('no_active_alerts', languageCode),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.neutral500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Translations.get(
                        'your_inventory_is_in_good_shape',
                        languageCode,
                      ),
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
                              Translations.get('item_id', languageCode) +
                                  ': ${alert.inventoryItemId}',
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
                                '${Translations.get('current', languageCode)}: ${alert.currentStock}',
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
                                  '${Translations.get('threshold', languageCode)}: ${alert.threshold}',
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
                            '${Translations.get('alert_created', languageCode)}: ${DateFormatter.formatRelative(alert.createdAt)}',
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

  // Helper method to find product by name
  Product? _findProductByName(List<Product> products, String itemName) {
    try {
      return products.firstWhere(
        (product) => product.name.toLowerCase() == itemName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to get stock sync status
  String _getStockSyncStatus(
    int inventoryStock,
    int menuStock,
    String languageCode,
  ) {
    if (inventoryStock == menuStock) {
      return Translations.get('synced', languageCode);
    } else if (inventoryStock > menuStock) {
      return Translations.get('inventory_high', languageCode);
    } else {
      return Translations.get('menu_high', languageCode);
    }
  }

  // Helper method to get stock sync color
  Color _getStockSyncColor(int inventoryStock, int menuStock) {
    if (inventoryStock == menuStock) {
      return AppTheme.success;
    } else {
      return Colors.orange;
    }
  }
}
