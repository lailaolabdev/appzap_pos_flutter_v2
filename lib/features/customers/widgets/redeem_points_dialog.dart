import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/customer.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';

/// Dialog for redeeming customer loyalty points
class RedeemPointsDialog extends ConsumerStatefulWidget {
  final Customer customer;
  final double orderTotal;
  final String orderId;

  const RedeemPointsDialog({
    super.key,
    required this.customer,
    required this.orderTotal,
    required this.orderId,
  });

  @override
  ConsumerState<RedeemPointsDialog> createState() => _RedeemPointsDialogState();
}

class _RedeemPointsDialogState extends ConsumerState<RedeemPointsDialog> {
  CustomerPoints? _customerPoints;
  bool _isLoadingPoints = true;
  String? _pointsError;

  int _pointsToRedeem = 0;
  bool _isRedeeming = false;
  String? _redeemError;

  // Conversion: 100 points = 10,000 LAK
  static const double _pointValue = 100; // 1 point = 100 LAK

  @override
  void initState() {
    super.initState();
    _fetchCustomerPoints();
  }

  Future<void> _fetchCustomerPoints() async {
    setState(() {
      _isLoadingPoints = true;
      _pointsError = null;
    });

    try {
      final restaurantId = ref.read(currentRestaurantIdProvider);
      final points = await ref
          .read(customerServiceProvider)
          .getCustomerPoints(widget.customer.id, restaurantId: restaurantId);

      setState(() {
        _customerPoints = points;
        _isLoadingPoints = false;
      });
    } catch (e) {
      setState(() {
        _pointsError = e.toString();
        _isLoadingPoints = false;
      });
    }
  }

  Future<void> _redeemPoints() async {
    final languageCode = ref.read(localizationProvider).languageCode;

    if (_pointsToRedeem <= 0) {
      setState(() {
        _redeemError = Translations.get(
          'please_select_points_to_redeem',
          languageCode,
        );
      });
      return;
    }

    if (_customerPoints == null ||
        _pointsToRedeem > _customerPoints!.currentPoints) {
      setState(() {
        _redeemError = Translations.get('insufficient_points', languageCode);
      });
      return;
    }

    setState(() {
      _isRedeeming = true;
      _redeemError = null;
    });

    try {
      await ref
          .read(customerServiceProvider)
          .redeemPoints(
            customerId: widget.customer.id,
            points: _pointsToRedeem,
            orderId: widget.orderId,
          );

      if (mounted) {
        Navigator.pop(context, _pointsToRedeem);
      }
    } catch (e) {
      setState(() {
        _redeemError = e.toString();
        _isRedeeming = false;
      });
    }
  }

  double get _discountAmount => _pointsToRedeem * _pointValue;

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.read(localizationProvider).languageCode;
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrangeBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get('redeem_loyalty_points', languageCode),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.customer.name,
                        style: const TextStyle(
                          fontSize: 14,
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

            // Loading state
            if (_isLoadingPoints)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_pointsError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pointsError!,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Available points
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrangeBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.get('available_points', languageCode),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutral600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_customerPoints?.currentPoints ?? 0} ${Translations.get('points', languageCode)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _customerPoints?.tier.displayName.toUpperCase() ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Points to redeem
              Text(
                Translations.get('points_to_redeem', languageCode),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_pointsToRedeem > 0) {
                        setState(() {
                          _pointsToRedeem = (_pointsToRedeem - 10).clamp(
                            0,
                            _customerPoints!.currentPoints,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.primaryOrange,
                  ),
                  Expanded(
                    child: Slider(
                      value: _pointsToRedeem.toDouble(),
                      min: 0,
                      max: (_customerPoints?.currentPoints ?? 0).toDouble(),
                      divisions: ((_customerPoints?.currentPoints ?? 0) / 10)
                          .ceil()
                          .clamp(1, 100),
                      label:
                          '$_pointsToRedeem ${Translations.get('points', languageCode)}',
                      onChanged: (value) {
                        setState(() {
                          _pointsToRedeem = value.toInt();
                        });
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_pointsToRedeem <
                          (_customerPoints?.currentPoints ?? 0)) {
                        setState(() {
                          _pointsToRedeem = (_pointsToRedeem + 10).clamp(
                            0,
                            _customerPoints!.currentPoints,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primaryOrange,
                  ),
                ],
              ),

              // Points display
              Center(
                child: Text(
                  '$_pointsToRedeem ${Translations.get('points', languageCode)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Discount preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translations.get('discount_amount', languageCode),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '- ${CurrencyFormatter.format(_discountAmount)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Order summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.neutral50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Translations.get('order_total', languageCode),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          CurrencyFormatter.format(widget.orderTotal),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Translations.get('points_discount', languageCode),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '- ${CurrencyFormatter.format(_discountAmount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Translations.get('new_total', languageCode),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            (widget.orderTotal - _discountAmount).clamp(
                              0,
                              widget.orderTotal,
                            ),
                          ),
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

              if (_redeemError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _redeemError!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isRedeeming ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(Translations.get('cancel', languageCode)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          _isRedeeming || _pointsToRedeem <= 0
                              ? null
                              : _redeemPoints,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          _isRedeeming
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                Translations.get('redeem_points', languageCode),
                              ),
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
}
