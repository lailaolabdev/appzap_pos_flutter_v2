import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/order.dart' as order_model;
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';

/// Order details screen showing complete order information
class OrderDetailsScreen extends ConsumerWidget {
  final order_model.Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar( 
          backgroundColor: AppTheme.scaffoldBackground,
          surfaceTintColor: AppTheme.scaffoldBackground,
          leading:
              isMobile
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  )
                  : null,
          title: Text('Order ${order.orderId}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print Receipt',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Print functionality - Coming Soon'),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'refund':
                    _showRefundDialog(context);
                    break;
                  case 'cancel':
                    _showCancelDialog(context);
                    break;
                }
              },
              itemBuilder:
                  (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'refund',
                      child: Text('Refund Order'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'cancel',
                      child: Text('Cancel Order'),
                    ),
                  ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          _OrderStatusChip(status: order.status.name),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          order.orderId,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (isMobile) ...[
                        _buildOrderInfoMobile(),
                      ] else ...[
                        _buildOrderInfoDesktop(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Customer Info Card (if available)
              if (order.customer != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: AppTheme.primaryOrange,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Customer Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Name', order.customer?.name ?? 'N/A'),

                        if (order.customer?.phone != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow('Phone', order.customer!.phone!),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Order Items Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Order Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Items List
                      ...order.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            if (index > 0) const Divider(),
                            const SizedBox(height: 12),
                            _OrderItemTile(item: item),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentRow('Subtotal', order.pricing.subtotal),
                      const SizedBox(height: 8),
                      _buildPaymentRow('Tax', order.pricing.tax),
                      if (order.pricing.discountTotal > 0) ...[
                        const SizedBox(height: 8),
                        _buildPaymentRow(
                          'Discount',
                          -order.pricing.discountTotal,
                          isDiscount: true,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildPaymentRow(
                        'Total',
                        order.pricing.total,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoMobile() {
    return Column(
      children: [
        _buildInfoRow(
          'Date & Time',
          DateFormatter.formatDateTime(order.createdAt),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Order Type', _getOrderTypeDisplay(order.orderType)),
        const SizedBox(height: 12),
        _buildInfoRow('Items Count', '${order.items.length} items'),
      ],
    );
  }

  Widget _buildOrderInfoDesktop() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'Date & Time',
                DateFormatter.formatDateTime(order.createdAt),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Order Type',
                _getOrderTypeDisplay(order.orderType),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Items Count', '${order.items.length} items'),
              const SizedBox(height: 12),
              _buildInfoRow('Q Number', order.qNumber.toString()),
            ],
          ),
        ),
      ],
    );
  }

  String _getOrderTypeDisplay(order_model.OrderType orderType) {
    switch (orderType) {
      case order_model.OrderType.dineIn:
        return 'Dine In';
      case order_model.OrderType.takeaway:
        return 'Takeaway';
      case order_model.OrderType.delivery:
        return 'Delivery';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.neutral600, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : AppTheme.neutral700,
          ),
        ),
        Text(
          CurrencyFormatter.formatLAKWithSymbol(amount),
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color:
                isTotal
                    ? AppTheme.primaryOrange
                    : isDiscount
                    ? Colors.green
                    : Colors.black,
          ),
        ),
      ],
    );
  }

  void _showRefundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Refund Order'),
            content: Text(
              'Are you sure you want to refund order ${order.orderId}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refund functionality - Coming Soon'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Refund'),
              ),
            ],
          ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: Text(
              'Are you sure you want to cancel order ${order.orderId}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cancel functionality - Coming Soon'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Cancel Order'),
              ),
            ],
          ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final order_model.OrderItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Image Placeholder
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.neutral300),
          ),
          child: Icon(Icons.fastfood, color: AppTheme.neutral500, size: 24),
        ),
        const SizedBox(width: 12),

        // Item Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.notes!,
                  style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutral700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatLAKWithSymbol(item.unitPrice),
                    style: TextStyle(fontSize: 14, color: AppTheme.neutral700),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Total Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatLAKWithSymbol(item.total),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
          ],
        ),
      ],
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
