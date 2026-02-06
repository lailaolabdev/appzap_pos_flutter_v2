import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/models/inventory.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../pos/providers/pos_provider.dart';
import '../providers/inventory_provider.dart';

/// Dialog for adjusting inventory stock levels
class AdjustStockDialog extends ConsumerStatefulWidget {
  final InventoryItem item;

  const AdjustStockDialog({super.key, required this.item});

  @override
  ConsumerState<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends ConsumerState<AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _costPriceController = TextEditingController();

  StockOperation _selectedOperation = StockOperation.add;
  String _selectedReason = 'adjustment';
  bool _isLoading = false;
  String? _error;

  final Map<StockOperation, List<String>> _reasons = {
    StockOperation.add: ['purchase', 'return', 'adjustment', 'other'],
    StockOperation.remove: [
      'sale',
      'damage',
      'theft',
      'waste',
      'adjustment',
      'other',
    ],
    StockOperation.set: ['physical_count', 'correction', 'other'],
  };

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  Future<void> _submitAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    final languageCode = ref.read(localizationProvider).languageCode;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adjustment = StockAdjustment(
        inventoryItemId:
            widget.item.itemId ??
            widget
                .item
                .id, // ✅ Use itemId (menu item ID) if available, fallback to inventory ID
        branchId: widget.item.branchId, // Use the item's branch ID
        operation: _selectedOperation,
        quantity: int.parse(_quantityController.text),
        reason: _selectedReason,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        costPrice:
            _costPriceController.text.isEmpty
                ? null
                : double.tryParse(_costPriceController.text),
      );

      print('🔧 Created adjustment object: $adjustment');
      print('🔧 Adjustment details:');
      print(
        '   - Using ID: ${widget.item.itemId ?? widget.item.id} (${widget.item.itemId != null ? "Menu Item ID" : "Inventory Item ID"})',
      );
      print('   - Menu Item ID: ${widget.item.itemId ?? "Not available"}');
      print('   - Inventory Item ID: ${widget.item.id}');
      print('   - Branch ID: ${widget.item.branchId}');
      print('   - Operation: $_selectedOperation');
      print('   - Quantity: ${_quantityController.text}');
      print('   - Reason: $_selectedReason');

      final success = await ref
          .read(inventoryProvider.notifier)
          .adjustStock(adjustment);

      if (success && mounted) {
        print('\n🔄 === POST-ADJUSTMENT VERIFICATION ===');

        // ✅ CRITICAL FIX: Verify the stock adjustment actually persisted in backend
        try {
          final inventoryService = ref.read(inventoryServiceProvider);
          final expectedNewStock = _newStockLevel;

          print('🔍 Verifying stock adjustment persisted...');
          print('   Expected new stock level: $expectedNewStock');

          final updatedItem = await inventoryService.verifyStockAdjustment(
            inventoryItemId: widget.item.itemId ?? widget.item.id,
            branchId: widget.item.branchId,
            expectedStock: expectedNewStock,
          );

          if (updatedItem != null) {
            if (updatedItem.currentStock == expectedNewStock) {
              print('✅ Stock adjustment verified successfully!');
              print(
                '   New stock level in database: ${updatedItem.currentStock}',
              );
            } else {
              print('❌ CRITICAL: Stock adjustment did not persist properly!');
              print('   Expected: $expectedNewStock');
              print('   Actual in DB: ${updatedItem.currentStock}');
              print('   This is a backend persistence issue!');

              // Show error to user
              if (mounted) {
                setState(() {
                  final prefix = Translations.get(
                    'stock_adjust_persist_prefix',
                    languageCode,
                  );
                  final expectedLabel = Translations.get(
                    'expected',
                    languageCode,
                  );
                  final actualLabel = Translations.get('actual', languageCode);
                  final contactSupport = Translations.get(
                    'please_contact_support',
                    languageCode,
                  );
                  _error =
                      '$prefix $expectedLabel: $expectedNewStock, $actualLabel: ${updatedItem.currentStock}. $contactSupport';
                  _isLoading = false;
                });
                return;
              }
            }
          } else {
            print(
              '❌ Could not verify stock adjustment - item not found in fresh data',
            );

            // Show warning to user
            if (mounted) {
              setState(() {
                _error = Translations.get(
                  'stock_adjust_verify_missing',
                  languageCode,
                );
                _isLoading = false;
              });
              return;
            }
          }
        } catch (e) {
          print('❌ Error during stock verification: $e');

          // Continue with the rest of the process even if verification fails
          if (mounted) {
            setState(() {
              final prefix = Translations.get(
                'stock_adjust_verify_failed_prefix',
                languageCode,
              );
              final refreshPrompt = Translations.get(
                'please_refresh',
                languageCode,
              );
              _error = '$prefix ${e.toString()}. $refreshPrompt';
              _isLoading = false;
            });
            return;
          }
        }

        // ✅ WORKAROUND: If backend doesn't return stock data, force refresh entire inventory
        print('🔄 Force refreshing inventory provider...');
        try {
          await ref.read(inventoryProvider.notifier).loadInventory();
          print('✅ Inventory provider refreshed successfully');
        } catch (e) {
          print('⚠️  Warning: Failed to refresh inventory: $e');
        }

        // ✅ Also refresh products to sync stock levels in UI
        print('🔄 Refreshing products provider to sync stock levels...');
        try {
          await ref.read(productsProvider.notifier).refresh();
          print('✅ Products provider refreshed successfully');
        } catch (e) {
          print('⚠️  Warning: Failed to refresh products: $e');
        }

        // ✅ CRITICAL FIX: Manually sync product inventory data after stock adjustment
        print('🔄 Manually syncing product inventory data...');
        try {
          final productsState = ref.read(productsProvider);
          final productsNotifier = ref.read(productsProvider.notifier);

          print('   Available products for matching:');
          for (final product in productsState.products) {
            print(
              '      - ${product.name} (ID: ${product.id}) | Current inventory: ${product.inventory?.currentStock ?? "NULL"}',
            );
          }

          // Find the product that matches this inventory item
          // Try multiple matching strategies
          Product? matchingProduct;

          // Strategy 1: Match by menu item ID (most reliable)
          if (widget.item.itemId != null) {
            matchingProduct =
                productsState.products.where((product) {
                  return product.id == widget.item.itemId;
                }).firstOrNull;

            if (matchingProduct != null) {
              print(
                '📦 Found matching product by menu item ID: ${matchingProduct.name}',
              );
            }
          }

          // Strategy 2: Match by inventory ID (backup)
          if (matchingProduct == null) {
            matchingProduct =
                productsState.products.where((product) {
                  return product.id == widget.item.id;
                }).firstOrNull;

            if (matchingProduct != null) {
              print(
                '📦 Found matching product by inventory ID: ${matchingProduct.name}',
              );
            }
          }

          // Strategy 3: Match by name (final fallback)
          if (matchingProduct == null) {
            matchingProduct =
                productsState.products.where((product) {
                  return product.name.toLowerCase() ==
                      widget.item.name.toLowerCase();
                }).firstOrNull;

            if (matchingProduct != null) {
              print(
                '📦 Found matching product by name: ${matchingProduct.name}',
              );
            }
          }

          if (matchingProduct != null) {
            print('   - Product ID: ${matchingProduct.id}');
            print(
              '   - Current product inventory stock: ${matchingProduct.inventory?.currentStock ?? "NULL"}',
            );
            print(
              '   - New inventory stock from adjustment: ${_newStockLevel}',
            );

            // Update the product's inventory data with new stock level using the new method
            productsNotifier.updateProductInventory(
              matchingProduct.id,
              _newStockLevel,
              lowStockThreshold: widget.item.minStockLevel,
              unit: widget.item.unit,
            );

            print('✅ Successfully synced product inventory data');

            // Verify the update worked
            final updatedState = ref.read(productsProvider);
            final updatedProduct =
                updatedState.products
                    .where((p) => p.id == matchingProduct!.id)
                    .firstOrNull;
            if (updatedProduct != null) {
              print(
                '   ✅ Verification: Updated product.inventory.currentStock: ${updatedProduct.inventory?.currentStock}',
              );
              print(
                '   ✅ Verification: Updated product.isInStock: ${updatedProduct.isInStock}',
              );
            }
          } else {
            print(
              '⚠️  Could not find matching product for inventory item: ${widget.item.name}',
            );
            print('   - Inventory item ID: ${widget.item.id}');
            print('   - Menu item ID: ${widget.item.itemId ?? "NULL"}');
            print('   - Available products: ${productsState.products.length}');
            print(
              '   - This means the menu item and inventory item are not properly linked',
            );
            print(
              '   - The UI will continue to show out of stock until products are reloaded from API',
            );
          }
        } catch (e) {
          print('⚠️  Warning: Failed to sync product inventory data: $e');
        }

        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = Translations.get('failed_to_adjust_stock', languageCode);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔧 Caught error in dialog: $e');
      setState(() {
        // Show more detailed error information
        final errorLabel = Translations.get('error', languageCode);
        _error = '$errorLabel: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  String _getOperationLabel(StockOperation op, String languageCode) {
    switch (op) {
      case StockOperation.add:
        return Translations.get('operation_add', languageCode);
      case StockOperation.remove:
        return Translations.get('operation_remove', languageCode);
      case StockOperation.set:
        return Translations.get('operation_set', languageCode);
    }
  }

  int get _newStockLevel {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    switch (_selectedOperation) {
      case StockOperation.add:
        return widget.item.currentStock + quantity;
      case StockOperation.remove:
        return widget.item.currentStock - quantity;
      case StockOperation.set:
        return quantity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localizationProvider).languageCode;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: AppTheme.primaryOrange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Translations.get('adjust_stock', languageCode),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.item.name,
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
                      tooltip: Translations.get('close', languageCode),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Current stock info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Translations.get('current_stock', languageCode),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.item.currentStock} ${widget.item.unit}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Translations.get('unit_cost', languageCode),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(widget.item.averageCost),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Operation selector
                Text(
                  Translations.get('operation', languageCode),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<StockOperation>(
                  segments: [
                    ButtonSegment(
                      value: StockOperation.add,
                      label: Text(
                        _getOperationLabel(StockOperation.add, languageCode),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                    ButtonSegment(
                      value: StockOperation.remove,
                      label: Text(
                        _getOperationLabel(StockOperation.remove, languageCode),
                      ),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    ButtonSegment(
                      value: StockOperation.set,
                      label: Text(
                        _getOperationLabel(StockOperation.set, languageCode),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                    ),
                  ],
                  selected: {_selectedOperation},
                  onSelectionChanged: (Set<StockOperation> newSelection) {
                    setState(() {
                      _selectedOperation = newSelection.first;
                      _selectedReason = _reasons[_selectedOperation]!.first;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Quantity input
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText:
                        _selectedOperation == StockOperation.set
                            ? Translations.get(
                              'new_stock_level_label',
                              languageCode,
                            )
                            : Translations.get('quantity_label', languageCode),
                    hintText: Translations.get('quantity_hint', languageCode),
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return Translations.get(
                        'quantity_required',
                        languageCode,
                      );
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return Translations.get('quantity_invalid', languageCode);
                    }
                    if (_selectedOperation == StockOperation.remove &&
                        quantity > widget.item.currentStock) {
                      return Translations.get(
                        'quantity_exceeds_stock',
                        languageCode,
                      );
                    }
                    return null;
                  },
                  onChanged:
                      (_) => setState(() {}), // Trigger rebuild for preview
                ),
                const SizedBox(height: 24),

                // Preview new stock level
                if (_quantityController.text.isNotEmpty)
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
                        Text(
                          Translations.get('new_stock_preview', languageCode),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$_newStockLevel ${widget.item.unit}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_quantityController.text.isNotEmpty)
                  const SizedBox(height: 20),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
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
                            _error!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
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
                        onPressed: _isLoading ? null : _submitAdjustment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  Translations.get('confirm', languageCode),
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
