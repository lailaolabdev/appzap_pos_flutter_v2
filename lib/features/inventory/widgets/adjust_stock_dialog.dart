import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/inventory.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/inventory_provider.dart';

/// Dialog for adjusting inventory stock levels
class AdjustStockDialog extends ConsumerStatefulWidget {
  final InventoryItem item;

  const AdjustStockDialog({
    super.key,
    required this.item,
  });

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
  String _selectedReason = 'purchase';
  bool _isLoading = false;
  String? _error;

  final Map<StockOperation, List<String>> _reasons = {
    StockOperation.add: ['purchase', 'return', 'adjustment', 'other'],
    StockOperation.remove: ['sale', 'damage', 'theft', 'waste', 'adjustment', 'other'],
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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adjustment = StockAdjustment(
        inventoryItemId: widget.item.id,
        branchId: ref.read(inventoryProvider).items.first.id, // Get from auth provider in real app
        operation: _selectedOperation,
        quantity: int.parse(_quantityController.text),
        reason: _selectedReason,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        costPrice: _costPriceController.text.isEmpty
            ? null
            : double.tryParse(_costPriceController.text),
      );

      final success = await ref.read(inventoryProvider.notifier).adjustStock(adjustment);

      if (success && mounted) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = 'Failed to adjust stock. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getOperationLabel(StockOperation op) {
    switch (op) {
      case StockOperation.add:
        return 'Add Stock';
      case StockOperation.remove:
        return 'Remove Stock';
      case StockOperation.set:
        return 'Set Stock Level';
    }
  }

  String _formatReason(String reason) {
    return reason.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
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
    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.inventory_2, color: AppTheme.primaryOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adjust Stock',
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
                          const Text(
                            'Current Stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.item.currentStock} ${widget.item.unit}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Unit Value',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(widget.item.costPrice),
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

                const SizedBox(height: 24),

                // Operation selector
                const Text(
                  'Operation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<StockOperation>(
                  segments: [
                    ButtonSegment(
                      value: StockOperation.add,
                      label: Text(_getOperationLabel(StockOperation.add)),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                    ButtonSegment(
                      value: StockOperation.remove,
                      label: Text(_getOperationLabel(StockOperation.remove)),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    ButtonSegment(
                      value: StockOperation.set,
                      label: Text(_getOperationLabel(StockOperation.set)),
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

                const SizedBox(height: 20),

                // Quantity input
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: _selectedOperation == StockOperation.set
                        ? 'New Stock Level *'
                        : 'Quantity *',
                    hintText: 'Enter quantity',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    if (_selectedOperation == StockOperation.remove &&
                        quantity > widget.item.currentStock) {
                      return 'Cannot remove more than current stock';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}), // Trigger rebuild for preview
                ),

                const SizedBox(height: 16),

                // Reason dropdown
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: InputDecoration(
                    labelText: 'Reason *',
                    prefixIcon: const Icon(Icons.info_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _reasons[_selectedOperation]!
                      .map((reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(_formatReason(reason)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Cost price (optional, for ADD operation)
                if (_selectedOperation == StockOperation.add)
                  TextFormField(
                    controller: _costPriceController,
                    decoration: InputDecoration(
                      labelText: 'Cost Price (optional)',
                      hintText: 'Enter cost price per unit',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                if (_selectedOperation == StockOperation.add) const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add any additional notes',
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

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
                        const Text(
                          'New Stock Level:',
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

                if (_quantityController.text.isNotEmpty) const SizedBox(height: 20),

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
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
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
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
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
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirm Adjustment'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

