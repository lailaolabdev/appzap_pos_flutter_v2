import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/cart.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../shared/widgets/app_text.dart';

/// Cart panel for displaying current order items
class CartPanel extends ConsumerWidget {
  final Cart cart;
  final void Function(String productId, int quantity) onUpdateQuantity;
  final void Function(String productId) onRemoveItem;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;
  final VoidCallback? onApplyLoyalty;

  const CartPanel({
    super.key,
    required this.cart,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onClearCart,
    required this.onCheckout,
    this.onApplyLoyalty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localizationProvider).languageCode;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrangeBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                AppText(
                  Translations.get('current_order', languageCode),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (cart.isNotEmpty && onApplyLoyalty != null)
                  TextButton.icon(
                    onPressed: onApplyLoyalty,
                    icon: const Icon(Icons.card_giftcard, size: 18),
                    label: AppText(Translations.get('loyalty', languageCode)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryOrange,
                    ),
                  ),
                if (cart.isNotEmpty)
                  TextButton(
                    onPressed: onClearCart,
                    child: AppText(
                      Translations.get('clear', languageCode),
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child:
                cart.isEmpty
                    ? _buildEmptyCart(context, ref, languageCode)
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: cart.items.length,
                      separatorBuilder:
                          (_, __) =>
                              Divider(height: 1, color: AppTheme.neutral100),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _CartItemTile(
                          item: item,
                          onIncrement:
                              () => onUpdateQuantity(
                                item.productId,
                                item.quantity + 1,
                              ),
                          onDecrement:
                              () => onUpdateQuantity(
                                item.productId,
                                item.quantity - 1,
                              ),
                          onRemove: () => onRemoveItem(item.productId),
                        );
                      },
                    ),
          ),

          // Summary
          if (cart.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.neutral50,
                border: Border(top: BorderSide(color: AppTheme.neutral200)),
              ),
              child: Column(
                children: [
                  // Subtotal
                  _SummaryRow(
                    translationKey: 'subtotal',
                    value: CurrencyFormatter.formatLAKWithSymbol(cart.subtotal),
                  ),

                  // Discount
                  if (cart.discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(
                      translationKey: 'discount',
                      value:
                          '-${CurrencyFormatter.formatLAKWithSymbol(cart.discountAmount)}',
                      valueColor: AppTheme.success,
                    ),
                  ],

                  // Tax
                  if (cart.totalTax > 0) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(
                      translationKey: 'tax',
                      value: CurrencyFormatter.formatLAKWithSymbol(
                        cart.totalTax,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        Translations.get('total', languageCode),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatLAKWithSymbol(cart.total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Checkout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onCheckout,
                  icon: const Icon(Icons.payment),
                  label: Consumer(
                    builder: (context, ref, _) {
                      final languageCode =
                          ref.watch(localizationProvider).languageCode;
                      final checkout = Translations.get(
                        'checkout',
                        languageCode,
                      );
                      final items = Translations.get('items', languageCode);
                      return Text(
                        '$checkout (${cart.totalItemsCount} $items)',
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCart(
    BuildContext context,
    WidgetRef ref,
    String languageCode,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppTheme.neutral400,
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            Translations.get('cart_empty', languageCode),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.neutral500),
          ),
          const SizedBox(height: 8),
          AppText(
            Translations.get('tap_products_to_add', languageCode),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral400),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.productId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: AppTheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Consumer(
                    builder: (context, ref, _) {
                      final languageCode =
                          ref.watch(localizationProvider).languageCode;
                      final each = Translations.get('each', languageCode);
                      return Text(
                        '${CurrencyFormatter.formatLAK(item.unitPrice)} $each',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutral500,
                        ),
                      );
                    },
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Quantity controls
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuantityButton(icon: Icons.remove, onPressed: onDecrement),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        item.quantity.toString(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _QuantityButton(icon: Icons.add, onPressed: onIncrement),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.formatLAKWithSymbol(item.subtotal),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
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

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.neutral100,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppTheme.neutral700),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String translationKey;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.translationKey,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          translationKey,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutral600),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
