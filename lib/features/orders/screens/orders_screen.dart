import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/order.dart' as order_model;
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../providers/orders_provider.dart';
import 'order_details_screen.dart';

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
    final languageCode = ref.watch(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBackground,
          surfaceTintColor: AppTheme.scaffoldBackground,
          title: Text(Translations.get('orders', languageCode)),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: Translations.get('filter', languageCode),
              onPressed: () => _showFilterBottomSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: Translations.get('refresh', languageCode),
              onPressed: () {
                ref.read(ordersProvider.notifier).loadOrders();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body:
            ordersState.isLoading
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
                        child: Text(Translations.get('retry', languageCode)),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(ordersProvider.notifier).loadOrders();
                  },
                  child:
                      ordersState.filteredOrders.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: ordersState.filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = ordersState.filteredOrders[index];
                              return _OrderCard(
                                order: order,
                                languageCode: languageCode,
                              );
                            },
                          ),
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
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            Translations.get('no_orders_found', languageCode),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.neutral600),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus == 'all'
                ? Translations.get('start_selling_to_see_orders', languageCode)
                : '${Translations.get('no_orders_with_status', languageCode)} ${_selectedStatus} ${Translations.get('status', languageCode)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral500),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final languageCode = ref.watch(localizationProvider).languageCode;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: Text(Translations.get('all_order', languageCode)),
                  selected: _selectedStatus == 'all',
                  onTap: () {
                    setState(() => _selectedStatus = 'all');
                    ref.read(ordersProvider.notifier).filterByStatus(null);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                  ),
                  title: Text(Translations.get('pending', languageCode)),
                  selected: _selectedStatus == 'pending',
                  onTap: () {
                    setState(() => _selectedStatus = 'pending');
                    ref.read(ordersProvider.notifier).filterByStatus('pending');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(Translations.get('completed', languageCode)),
                  selected: _selectedStatus == 'completed',
                  onTap: () {
                    setState(() => _selectedStatus = 'completed');
                    ref
                        .read(ordersProvider.notifier)
                        .filterByStatus('completed');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: Text(Translations.get('cancelled', languageCode)),
                  selected: _selectedStatus == 'cancelled',
                  onTap: () {
                    setState(() => _selectedStatus = 'cancelled');
                    ref
                        .read(ordersProvider.notifier)
                        .filterByStatus('cancelled');
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
  final order_model.Order order;
  final String languageCode;
  const _OrderCard({required this.order, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to order details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
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
                  Flexible(
                    flex: 2,
                    child: Text(
                      order.orderId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _OrderStatusChip(
                    status: order.status.name,
                    languageCode: languageCode,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Customer info (if available)
              if (order.customer != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.neutral600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.customer?.name ?? 'Guest',
                        style: const TextStyle(
                          color: AppTheme.neutral600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Time
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.neutral600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      DateFormatter.formatDateTime(order.createdAt),
                      style: TextStyle(
                        color: AppTheme.neutral600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Items count & Total
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${order.items.length} ${order.items.length == 1 ? Translations.get('item', languageCode) : Translations.get('items', languageCode)}',
                      style: TextStyle(color: AppTheme.neutral700),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CurrencyFormatter.formatLAKWithSymbol(
                        order.pricing.total,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
  final String languageCode;
  const _OrderStatusChip({required this.status, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        label = Translations.get('pending', languageCode);
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue.shade700;
        label = Translations.get('confirmed', languageCode);
        break;
      case 'preparing':
        backgroundColor = Colors.purple.withValues(alpha: .1);
        textColor = Colors.purple.shade700;
        label = Translations.get('preparing', languageCode);
        break;
      case 'ready':
        backgroundColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal.shade700;
        label = Translations.get('ready', languageCode);
        break;
      case 'completed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        label = Translations.get('completed', languageCode);
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        label = Translations.get('cancelled', languageCode);
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
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
