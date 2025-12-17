import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/inventory.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/purchase_order_provider.dart';
import '../widgets/create_purchase_order_dialog.dart';

/// Purchase Orders management screen
class PurchaseOrdersScreen extends ConsumerWidget {
  const PurchaseOrdersScreen({super.key});

  void _createPurchaseOrder(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreatePurchaseOrderDialog(),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase order created successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _updateOrderStatus(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    String currentStatus,
  ) async {
    // Determine next status
    String? nextStatus;
    if (currentStatus == 'pending') {
      nextStatus = 'ordered';
    } else if (currentStatus == 'ordered') {
      nextStatus = 'received';
    }

    if (nextStatus == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Change status to "${nextStatus!.toUpperCase()}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(purchaseOrderProvider.notifier)
          .updateOrderStatus(orderId, nextStatus);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${nextStatus.toUpperCase()}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poState = ref.watch(purchaseOrderProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (status) {
              ref.read(purchaseOrderProvider.notifier).setStatusFilter(
                    status == 'all' ? null : status,
                  );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Orders'),
              ),
              PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text('Pending (${poState.pendingCount})'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ordered',
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Text('Ordered (${poState.orderedCount})'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'received',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                    const SizedBox(width: 8),
                    Text('Received (${poState.receivedCount})'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(purchaseOrderProvider.notifier).refresh(),
          ),
        ],
      ),
      body: poState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : poState.error != null
              ? Center(
                  child: ErrorBanner(
                    message: poState.error!,
                    onDismiss: () => ref.read(purchaseOrderProvider.notifier).refresh(),
                  ),
                )
              : poState.orders.isEmpty
                  ? _buildEmptyState(context, ref)
                  : RefreshIndicator(
                      onRefresh: () => ref.read(purchaseOrderProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: poState.orders.length,
                        itemBuilder: (context, index) {
                          final order = poState.orders[index];
                          return _buildOrderCard(context, ref, order);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPurchaseOrder(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppTheme.neutral300,
          ),
          const SizedBox(height: 16),
          Text(
            'No purchase orders yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.neutral500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first purchase order to restock inventory',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutral400,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createPurchaseOrder(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create Purchase Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    WidgetRef ref,
    PurchaseOrder order,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case 'ordered':
        statusColor = Colors.blue;
        statusIcon = Icons.shopping_cart;
        break;
      case 'received':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = AppTheme.neutral500;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'PO #${order.id.substring(order.id.length - 6)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                order.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${order.items.length} items'),
            if (order.expectedDeliveryDate != null)
              Text(
                'Expected: ${order.expectedDeliveryDate}',
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              'Created: ${DateFormatter.formatRelative(order.createdAt)}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: order.status != 'received'
            ? IconButton(
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Update Status',
                onPressed: () => _updateOrderStatus(
                  context,
                  ref,
                  order.id,
                  order.status,
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items list
                const Text(
                  'Items:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Item ID: ${(item as Map)['inventoryItemId']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          'Qty: ${item['quantity']} @ ${CurrencyFormatter.format((item['unitCost'] as num).toDouble())}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
                if (order.notes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note, size: 16, color: AppTheme.neutral600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

