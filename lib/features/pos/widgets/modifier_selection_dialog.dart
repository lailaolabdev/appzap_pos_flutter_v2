import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/models/cart.dart';
import '../../../core/models/modifier.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/currency_formatter.dart';

/// Dialog shown when adding a product with modifiers to the cart.
/// Returns a list of [SelectedModifier] on confirm, or null on cancel.
class ModifierSelectionDialog extends StatefulWidget {
  final Product product;
  final String lang;

  const ModifierSelectionDialog({
    super.key,
    required this.product,
    required this.lang,
  });

  @override
  State<ModifierSelectionDialog> createState() =>
      _ModifierSelectionDialogState();
}

class _ModifierSelectionDialogState extends State<ModifierSelectionDialog> {
  // Map<customizationId, Set<optionId>>
  final Map<String, Set<String>> _selections = {};
  @override
  void initState() {
    super.initState();
    // Pre-select default options
    for (final mod in widget.product.customizations) {
      _selections[mod.id] = {};
      for (final opt in mod.options) {
        if (opt.isDefault) {
          _selections[mod.id]!.add(opt.id);
        }
      }
    }
  }

  void _toggleOption(Modifier mod, ModifierOption option) {
    setState(() {
      final selected = _selections[mod.id] ??= {};

      // Simple toggle: tap to check, tap again to uncheck
      if (selected.contains(option.id)) {
        selected.remove(option.id);
      } else {
        selected.add(option.id);
      }
    });
  }

  void _confirm() {
    final result = <SelectedModifier>[];
    for (final mod in widget.product.customizations) {
      final selectedIds = _selections[mod.id] ?? {};
      for (final opt in mod.options) {
        if (selectedIds.contains(opt.id)) {
          result.add(
            SelectedModifier(
              customizationId: mod.id,
              customizationName: mod.name,
              optionId: opt.id,
              optionName: opt.name,
              price: opt.price,
            ),
          );
        }
      }
    }

    Navigator.pop(context, result);
  }

  double get _extrasTotal {
    double total = 0;
    for (final mod in widget.product.customizations) {
      final selectedIds = _selections[mod.id] ?? {};
      for (final opt in mod.options) {
        if (selectedIds.contains(opt.id)) {
          total += opt.price;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final lang = widget.lang;
    final totalPrice = product.pricing.basePrice + _extrasTotal;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Product header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatLAKWithSymbol(
                    product.pricing.basePrice,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Modifier groups — scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children:
                    widget.product.customizations
                        .map((mod) => _buildModifierGroup(mod, lang))
                        .toList(),
              ),
            ),
          ),

          // Bottom bar: total + add to cart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.neutral200)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '${Translations.get('add_to_cart', lang)}  ${CurrencyFormatter.formatLAKWithSymbol(totalPrice)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierGroup(Modifier mod, String lang) {
    final selectedIds = _selections[mod.id] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                mod.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),

        // Options
        ...mod.options.map((opt) {
          final isSelected = selectedIds.contains(opt.id);
          return InkWell(
            onTap: () => _toggleOption(mod, opt),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Radio or checkbox
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color:
                        isSelected
                            ? AppTheme.primaryOrange
                            : AppTheme.neutral400,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (opt.price > 0)
                    Text(
                      '+${CurrencyFormatter.formatLAKWithSymbol(opt.price)}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isSelected
                                ? AppTheme.primaryOrange
                                : AppTheme.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),

        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
