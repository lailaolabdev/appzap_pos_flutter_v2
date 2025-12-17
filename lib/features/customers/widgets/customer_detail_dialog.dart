import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/customer.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/utils/currency_formatter.dart';

/// Dialog showing customer details and loyalty information
class CustomerDetailDialog extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailDialog({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends ConsumerState<CustomerDetailDialog> {
  CustomerPoints? _points;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final points = await ref
          .read(customerServiceProvider)
          .getCustomerPoints(widget.customer.id);
      
      if (mounted) {
        setState(() {
          _points = points;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getTierColor(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.platinum:
        return const Color(0xFFE5E4E2);
      case LoyaltyTier.gold:
        return const Color(0xFFFFD700);
      case LoyaltyTier.silver:
        return const Color(0xFFC0C0C0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryOrangeBackground,
                  child: Text(
                    widget.customer.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.customer.phone != null)
                        Text(
                          widget.customer.phone!,
                          style: const TextStyle(
                            color: AppTheme.neutral600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tier badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getTierColor(widget.customer.tier).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getTierColor(widget.customer.tier),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stars,
                    color: _getTierColor(widget.customer.tier),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.customer.tier.displayName} Member',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getTierColor(widget.customer.tier),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Loyalty Points
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_points != null) ...[
              _StatCard(
                icon: Icons.stars,
                iconColor: AppTheme.primaryOrange,
                title: 'Loyalty Points',
                value: '${_points!.currentPoints}',
                subtitle: _points!.nextTier != null
                    ? '${_points!.pointsToNextTier} more to ${_points!.nextTier!.displayName}'
                    : 'Top tier achieved!',
              ),
              const SizedBox(height: 12),
            ],

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppTheme.success,
                    title: 'Total Spent',
                    value: CurrencyFormatter.formatLAKWithSymbol(
                      widget.customer.totalSpent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.event,
                    iconColor: AppTheme.info,
                    title: 'Visits',
                    value: '${widget.customer.visitCount}',
                  ),
                ),
              ],
            ),

            // Actions
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: View purchase history
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Redeem points
                    },
                    icon: const Icon(Icons.redeem),
                    label: const Text('Redeem'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.neutral600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

