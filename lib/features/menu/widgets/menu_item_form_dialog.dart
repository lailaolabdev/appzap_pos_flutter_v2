import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/menu_provider.dart';

class MenuItemFormDialog extends ConsumerStatefulWidget {
  final dynamic item; // Product model

  const MenuItemFormDialog({super.key, this.item});

  @override
  ConsumerState<MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends ConsumerState<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _skuController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _lowStockController;

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _taxIncluded = false;
  bool _trackStock = true;
  bool _isLoading = false;

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedCategoryId != null &&
        _basePriceController.text.trim().isNotEmpty &&
        double.tryParse(_basePriceController.text.trim()) != null;
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.item?.description ?? '',
    );
    _itemCodeController = TextEditingController(
      text: widget.item?.itemCode ?? '',
    );
    _barcodeController = TextEditingController(
      text: widget.item?.barcode ?? '',
    );
    _skuController = TextEditingController(text: widget.item?.sku ?? '');
    _basePriceController = TextEditingController(
      text: widget.item?.pricing.basePrice.toString() ?? '',
    );
    _costPriceController = TextEditingController(
      text: widget.item?.pricing.costPrice?.toString() ?? '',
    );
    _taxRateController = TextEditingController(
      text: widget.item?.pricing.taxRate?.toString() ?? '0',
    );
    _lowStockController = TextEditingController(
      text: widget.item?.inventory?.lowStockThreshold?.toString() ?? '10',
    );

    _selectedCategoryId = widget.item?.categoryId;
    _isActive = widget.item?.isActive ?? true;
    _taxIncluded = widget.item?.pricing.taxIncluded ?? false;
    _trackStock = widget.item?.inventory?.trackStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _itemCodeController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _basePriceController.dispose();
    _costPriceController.dispose();
    _taxRateController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final bool success;
    if (widget.item == null) {
      // Create new item
      success = await ref
          .read(menuProvider.notifier)
          .createMenuItem(
            categoryId: _selectedCategoryId!,
            name: _nameController.text,
            description:
                _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
            itemCode:
                _itemCodeController.text.isEmpty
                    ? null
                    : _itemCodeController.text,
            barcode:
                _barcodeController.text.isEmpty
                    ? null
                    : _barcodeController.text,
            sku: _skuController.text.isEmpty ? null : _skuController.text,
            basePrice: double.parse(_basePriceController.text),
            costPrice:
                _costPriceController.text.isEmpty
                    ? null
                    : double.parse(_costPriceController.text),
            taxRate: double.parse(_taxRateController.text),
            taxIncluded: _taxIncluded,
            trackStock: _trackStock,
            lowStockThreshold: int.parse(_lowStockController.text),
            isActive: _isActive,
          );
    } else {
      // Update existing item
      success = await ref
          .read(menuProvider.notifier)
          .updateMenuItem(
            itemId: widget.item.id,
            name: _nameController.text,
            description:
                _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
            categoryId: _selectedCategoryId,
            basePrice: double.parse(_basePriceController.text),
            costPrice:
                _costPriceController.text.isEmpty
                    ? null
                    : double.parse(_costPriceController.text),
            taxRate: double.parse(_taxRateController.text),
            taxIncluded: _taxIncluded,
            trackStock: _trackStock,
            lowStockThreshold: int.parse(_lowStockController.text),
            isActive: _isActive,
          );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        // If stock tracking is enabled and this is a new item creation,
        // refresh the inventory to show the newly created inventory item
        if (widget.item == null && _trackStock) {
          // Refresh inventory after a short delay to allow backend processing
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              try {
                ref.read(inventoryProvider.notifier).refresh();
              } catch (e) {
                // Ignore inventory refresh errors to not interrupt the success flow
              }
            }
          });
        }
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null
                  ? _trackStock
                    ? 'Menu item created successfully! Check inventory for stock tracking.'
                    : 'Item created successfully'
                  : 'Item updated successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(menuProvider).error ?? 'Operation failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menuProvider).categories;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // Full screen for mobile
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Close',
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      hintText: 'e.g., Coca Cola 330ml',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    validator:
                        (value) =>
                            value == null ? 'Category is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Base Price & Cost Price
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _basePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Sale Price (LAK) *',
                            hintText: '8000',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            if (double.tryParse(value!) == null)
                              return 'Invalid';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Cost Price (LAK)',
                            hintText: '6000',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Item Code, Barcode, SKU
                  TextFormField(
                    controller: _itemCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Item Code',
                      hintText: 'COKE330',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode',
                            hintText: '8851959132012',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU',
                            hintText: 'COKE-330ML',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tax Rate
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _taxRateController,
                          decoration: const InputDecoration(
                            labelText: 'Tax Rate (%)',
                            hintText: '0',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Tax Included'),
                          value: _taxIncluded,
                          onChanged: (value) {
                            setState(() => _taxIncluded = value ?? false);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock Settings
                  const Text(
                    'Stock Management',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  CheckboxListTile(
                    title: const Text('Track Stock'),
                    value: _trackStock,
                    onChanged: (value) {
                      setState(() => _trackStock = value ?? true);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  if (_trackStock)
                    TextFormField(
                      controller: _lowStockController,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Threshold',
                        hintText: '10',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  const SizedBox(height: 16),

                  // Active Status
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Item is available for sale'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                  ),
                ],
              ),
              // Floating Save Button at Bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_isFormValid ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          disabledBackgroundColor: AppTheme.neutral300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  widget.item == null
                                      ? 'Add Item'
                                      : 'Save Changes',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Dialog for tablet/desktop
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.item == null ? 'Add Menu Item' : 'Edit Menu Item',
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g., Coca Cola 330ml',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                  validator:
                      (value) => value == null ? 'Category is required' : null,
                ),
                const SizedBox(height: 16),

                // Base Price & Cost Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _basePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Sale Price (LAK) *',
                          hintText: '8000',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (double.tryParse(value!) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cost Price (LAK)',
                          hintText: '6000',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Item Code, Barcode, SKU
                TextFormField(
                  controller: _itemCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Code',
                    hintText: 'COKE330',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          hintText: '8851959132012',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU',
                          hintText: 'COKE-330ML',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tax Rate
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _taxRateController,
                        decoration: const InputDecoration(
                          labelText: 'Tax Rate (%)',
                          hintText: '0',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Tax Included'),
                        value: _taxIncluded,
                        onChanged: (value) {
                          setState(() => _taxIncluded = value ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stock Settings
                const Text(
                  'Stock Management',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  title: const Text('Track Stock'),
                  value: _trackStock,
                  onChanged: (value) {
                    setState(() => _trackStock = value ?? true);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                if (_trackStock)
                  TextFormField(
                    controller: _lowStockController,
                    decoration: const InputDecoration(
                      labelText: 'Low Stock Threshold',
                      hintText: '10',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                const SizedBox(height: 16),

                // Active Status
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Item is available for sale'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
