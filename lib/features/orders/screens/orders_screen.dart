import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../providers/orders_provider.dart';

/// Orders management screen
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    // Load orders when screen opens
    Future.microtask(() => ref.read(ordersProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer: isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          title: const Text('Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter',
              onPressed: () => _showFilterBottomSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                ref.read(ordersProvider.notifier).loadOrders();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ordersState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ordersState.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ordersState.error!,
                          style: const TextStyle(color: AppTheme.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(ordersProvider.notifier).loadOrders();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(ordersProvider.notifier).loadOrders();
                    },
                    child: ordersState.filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: ordersState.filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = ordersState.filteredOrders[index];
                              return _OrderCard(order: order);
                            },
                          ),
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
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus == 'all'
                ? 'Start selling to see orders here'
                : 'No orders with ${_selectedStatus} status',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Orders'),
              selected: _selectedStatus == 'all',
              onTap: () {
                setState(() => _selectedStatus = 'all');
                ref.read(ordersProvider.notifier).filterByStatus(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              title: const Text('Pending'),
              selected: _selectedStatus == 'pending',
              onTap: () {
                setState(() => _selectedStatus = 'pending');
                ref.read(ordersProvider.notifier).filterByStatus('pending');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Completed'),
              selected: _selectedStatus == 'completed',
              onTap: () {
                setState(() => _selectedStatus = 'completed');
                ref.read(ordersProvider.notifier).filterByStatus('completed');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancelled'),
              selected: _selectedStatus == 'cancelled',
              onTap: () {
                setState(() => _selectedStatus = 'cancelled');
                ref.read(ordersProvider.notifier).filterByStatus('cancelled');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to order details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order ${order.orderNumber} details - Coming Soon')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 8),

              // Customer info (if available)
              if (order.customerName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppTheme.neutral600),
                    const SizedBox(width: 4),
                    Text(
                      order.customerName!,
                      style: TextStyle(
                        color: AppTheme.neutral600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Time
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppTheme.neutral600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDateTime(order.createdAt),
                    style: TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Items count & Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: AppTheme.neutral700,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatLAKWithSymbol(order.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final String status;

  const _OrderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        label = 'Pending';
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade700;
        label = 'Confirmed';
        break;
      case 'preparing':
        backgroundColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple.shade700;
        label = 'Preparing';
        break;
      case 'ready':
        backgroundColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal.shade700;
        label = 'Ready';
        break;
      case 'completed':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        label = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        label = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Placeholder Order model (create proper model file later)
class Order {
  final String id;
  final String orderNumber;
  final String status;
  final String? customerName;
  final DateTime createdAt;
  final int itemCount;
  final double total;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.customerName,
    required this.createdAt,
    required this.itemCount,
    required this.total,
  });
}

