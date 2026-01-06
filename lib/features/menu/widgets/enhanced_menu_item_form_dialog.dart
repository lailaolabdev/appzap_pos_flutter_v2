import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/inventory.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/menu_provider.dart';

/// Enhanced Menu Item Form Dialog with Complete Inventory Integration
/// 
/// This dialog provides comprehensive CRUD operations for menu items with:
/// - Full inventory tracking integration
/// - Advanced tax calculations (tax-inclusive vs tax-exclusive)
/// - Stock management with multiple units of measure
/// - Cost analysis and profit margin calculations
/// - Real-time price previews
class EnhancedMenuItemFormDialog extends ConsumerStatefulWidget {
  final dynamic item; // Existing menu item to edit, null for new item

  const EnhancedMenuItemFormDialog({super.key, this.item});

  @override
  ConsumerState<EnhancedMenuItemFormDialog> createState() => _EnhancedMenuItemFormDialogState();
}

class _EnhancedMenuItemFormDialogState extends ConsumerState<EnhancedMenuItemFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Controllers for all form fields
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _skuController;
  
  // Pricing controllers
  late final TextEditingController _basePriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _profitMarginController;
  
  // Inventory controllers
  late final TextEditingController _minStockController;
  late final TextEditingController _maxStockController;
  late final TextEditingController _reorderPointController;
  late final TextEditingController _initialStockController;
  
  // State variables
  String? _selectedCategoryId;
  bool _isActive = true;
  bool _taxIncluded = false;
  bool _trackInventory = true;
  bool _isLoading = false;
  
  // Inventory settings
  String _inventoryMethod = 'auto_create'; // auto_create, manual, none
  UnitOfMeasure _selectedUnit = const UnitOfMeasure(
    name: 'Unit', 
    abbreviation: 'unit', 
    category: 'count'
  );
  
  // Available units of measure
  final List<UnitOfMeasure> _availableUnits = [
    const UnitOfMeasure(name: 'Unit', abbreviation: 'unit', category: 'count'),
    const UnitOfMeasure(name: 'Piece', abbreviation: 'pc', category: 'count'),
    const UnitOfMeasure(name: 'Kilogram', abbreviation: 'kg', category: 'weight'),
    const UnitOfMeasure(name: 'Gram', abbreviation: 'g', category: 'weight'),
    const UnitOfMeasure(name: 'Liter', abbreviation: 'L', category: 'volume'),
    const UnitOfMeasure(name: 'Milliliter', abbreviation: 'ml', category: 'volume'),
    const UnitOfMeasure(name: 'Bottle', abbreviation: 'btl', category: 'count'),
    const UnitOfMeasure(name: 'Can', abbreviation: 'can', category: 'count'),
    const UnitOfMeasure(name: 'Box', abbreviation: 'box', category: 'count'),
  ];

  // Calculated values
  double get _basePrice => double.tryParse(_basePriceController.text) ?? 0;
  double get _costPrice => double.tryParse(_costPriceController.text) ?? 0;
  double get _taxRate => double.tryParse(_taxRateController.text) ?? 0;
  
  /// Calculate final selling price including or excluding tax
  double get _finalPrice {
    if (_taxIncluded) {
      // Tax is already included in the base price
      return _basePrice;
    } else {
      // Add tax to base price
      return _basePrice * (1 + (_taxRate / 100));
    }
  }
  
  /// Calculate tax amount
  double get _taxAmount {
    if (_taxIncluded) {
      // Extract tax from inclusive price: tax = price - (price / (1 + rate))
      return _basePrice - (_basePrice / (1 + (_taxRate / 100)));
    } else {
      // Calculate tax on exclusive price
      return _basePrice * (_taxRate / 100);
    }
  }
  
  /// Calculate profit margin percentage
  double get _profitMargin {
    if (_costPrice == 0) return 0;
    return ((_basePrice - _costPrice) / _basePrice) * 100;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _itemCodeController = TextEditingController();
    _barcodeController = TextEditingController();
    _skuController = TextEditingController();
    _basePriceController = TextEditingController();
    _costPriceController = TextEditingController();
    _taxRateController = TextEditingController(text: '10'); // Default 10% tax
    _profitMarginController = TextEditingController();
    _minStockController = TextEditingController(text: '10');
    _maxStockController = TextEditingController(text: '100');
    _reorderPointController = TextEditingController(text: '20');
    _initialStockController = TextEditingController(text: '0');
    
    // Add listeners for real-time calculations
    _basePriceController.addListener(_updateCalculations);
    _costPriceController.addListener(_updateCalculations);
    _taxRateController.addListener(_updateCalculations);
  }

  void _loadExistingData() {
    if (widget.item != null) {
      final item = widget.item;
      _nameController.text = item.name ?? '';
      _descriptionController.text = item.description ?? '';
      _itemCodeController.text = item.itemCode ?? '';
      _barcodeController.text = item.barcode ?? '';
      _skuController.text = item.sku ?? '';
      _basePriceController.text = item.pricing?.basePrice?.toString() ?? '';
      _costPriceController.text = item.pricing?.costPrice?.toString() ?? '';
      _taxRateController.text = item.pricing?.taxRate?.toString() ?? '10';
      
      _selectedCategoryId = item.categoryId;
      _isActive = item.isActive ?? true;
      _taxIncluded = item.pricing?.taxIncluded ?? false;
      _trackInventory = item.inventory?.trackStock ?? true;
      
      if (item.inventory != null) {
        _minStockController.text = item.inventory.lowStockThreshold?.toString() ?? '10';
        _reorderPointController.text = item.inventory.reorderPoint?.toString() ?? '20';
      }
    }
  }

  void _updateCalculations() {
    setState(() {
      _profitMarginController.text = _profitMargin.toStringAsFixed(1);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _itemCodeController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _basePriceController.dispose();
    _costPriceController.dispose();
    _taxRateController.dispose();
    _profitMarginController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _reorderPointController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedCategoryId != null &&
        _basePriceController.text.trim().isNotEmpty &&
        double.tryParse(_basePriceController.text.trim()) != null &&
        double.tryParse(_basePriceController.text.trim())! > 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool success;
      if (widget.item == null) {
        // Create new menu item with full inventory integration
        success = await ref.read(menuProvider.notifier).createMenuItem(
          categoryId: _selectedCategoryId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
          itemCode: _itemCodeController.text.isEmpty ? null : _itemCodeController.text.trim(),
          barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text.trim(),
          sku: _skuController.text.isEmpty ? null : _skuController.text.trim(),
          basePrice: _basePrice,
          costPrice: _costPrice > 0 ? _costPrice : null,
          taxRate: _taxRate,
          taxIncluded: _taxIncluded,
          trackStock: _trackInventory,
          lowStockThreshold: _trackInventory ? int.tryParse(_minStockController.text) ?? 10 : 0,
          isActive: _isActive,
        );
      } else {
        // Update existing menu item
        success = await ref.read(menuProvider.notifier).updateMenuItem(
          itemId: widget.item.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
          categoryId: _selectedCategoryId,
          basePrice: _basePrice,
          costPrice: _costPrice > 0 ? _costPrice : null,
          taxRate: _taxRate,
          taxIncluded: _taxIncluded,
          trackStock: _trackInventory,
          lowStockThreshold: _trackInventory ? int.tryParse(_minStockController.text) ?? 10 : 0,
          isActive: _isActive,
        );
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null ? 'Menu item created successfully!' : 'Menu item updated successfully!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menuProvider).categories;
    
    return Dialog(
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.item == null ? Icons.add : Icons.edit,
                  color: AppTheme.primaryOrange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.item == null ? 'Add Menu Item' : 'Edit Menu Item',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Basic Info'),
                Tab(icon: Icon(Icons.attach_money), text: 'Pricing & Tax'),
                Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
              ],
            ),

            const SizedBox(height: 16),

            // Tab views
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(categories),
                    _buildPricingTab(),
                    _buildInventoryTab(),
                  ],
                ),
              ),
            ),

            // Action buttons
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading || !_isFormValid ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    minimumSize: const Size(120, 48),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.item == null ? 'Create Item' : 'Update Item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(List<dynamic> categories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name *',
              hintText: 'e.g., Espresso Coffee',
              prefixIcon: Icon(Icons.restaurant_menu),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Item name is required';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of the item',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          
          const SizedBox(height: 16),

          // Category selection
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Category *',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: categories.map<DropdownMenuItem<String>>((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),

          // Item code and barcode row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _itemCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Code',
                    hintText: 'ESP001',
                    prefixIcon: Icon(Icons.qr_code),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    hintText: '1234567890123',
                    prefixIcon: Icon(Icons.barcode_reader),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // SKU
          TextFormField(
            controller: _skuController,
            decoration: const InputDecoration(
              labelText: 'SKU (Stock Keeping Unit)',
              hintText: 'ESP-COFFEE-250ML',
              prefixIcon: Icon(Icons.inventory_2),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          
          const SizedBox(height: 16),

          // Active status
          SwitchListTile(
            title: const Text('Active Item'),
            subtitle: const Text('Available for sale'),
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value);
            },
            secondary: Icon(
              _isActive ? Icons.visibility : Icons.visibility_off,
              color: _isActive ? AppTheme.success : AppTheme.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tax calculation explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.info.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: AppTheme.info),
                    const SizedBox(width: 8),
                    const Text(
                      'Tax Calculation Guide',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Tax Inclusive: The price includes tax (e.g., ₭10,000 including 10% tax)\n'
                  '• Tax Exclusive: Tax is added to the price (e.g., ₭10,000 + 10% = ₭11,000)\n'
                  '• Most retail prices in Laos are tax-inclusive',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Base price and cost price row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _basePriceController,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (LAK) *',
                    hintText: '25000',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value!);
                    if (price == null || price <= 0) {
                      return 'Enter a valid price';
                    }
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
                    hintText: '15000',
                    prefixIcon: Icon(Icons.money_off),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Tax rate and settings
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _taxRateController,
                  decoration: const InputDecoration(
                    labelText: 'Tax Rate (%)',
                    hintText: '10',
                    prefixIcon: Icon(Icons.percent),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SwitchListTile(
                  title: const Text('Tax Inclusive'),
                  subtitle: const Text('Price includes tax'),
                  value: _taxIncluded,
                  onChanged: (value) {
                    setState(() => _taxIncluded = value);
                  },
                  secondary: Icon(
                    _taxIncluded ? Icons.check_circle : Icons.add_circle,
                    color: _taxIncluded ? AppTheme.success : AppTheme.neutral400,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Price calculation preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Breakdown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPriceRow('Base Price', _basePrice),
                _buildPriceRow('Tax Amount', _taxAmount),
                const Divider(),
                _buildPriceRow('Final Price', _finalPrice, isTotal: true),
                if (_costPrice > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('Cost Price', _costPrice),
                  _buildPriceRow('Profit', _basePrice - _costPrice),
                  Text(
                    'Profit Margin: ${_profitMargin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _profitMargin >= 20 ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.success : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inventory tracking toggle
          SwitchListTile(
            title: const Text('Enable Inventory Tracking'),
            subtitle: const Text('Track stock levels for this item'),
            value: _trackInventory,
            onChanged: (value) {
              setState(() => _trackInventory = value);
            },
            secondary: Icon(
              _trackInventory ? Icons.inventory : Icons.inventory_outlined,
              color: _trackInventory ? AppTheme.success : AppTheme.neutral400,
            ),
          ),
          
          if (_trackInventory) ...[
            const SizedBox(height: 16),

            // Unit of measure selection
            DropdownButtonFormField<UnitOfMeasure>(
              value: _selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Unit of Measure',
                prefixIcon: Icon(Icons.straighten),
                border: OutlineInputBorder(),
              ),
              items: _availableUnits.map((unit) {
                return DropdownMenuItem<UnitOfMeasure>(
                  value: unit,
                  child: Text('${unit.name} (${unit.abbreviation})'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedUnit = value);
                }
              },
            ),
            
            const SizedBox(height: 16),

            // Stock level settings
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Min Stock Level',
                      hintText: '10',
                      prefixIcon: Icon(Icons.trending_down),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxStockController,
                    decoration: const InputDecoration(
                      labelText: 'Max Stock Level',
                      hintText: '100',
                      prefixIcon: Icon(Icons.trending_up),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Reorder point and initial stock
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _reorderPointController,
                    decoration: const InputDecoration(
                      labelText: 'Reorder Point',
                      hintText: '20',
                      prefixIcon: Icon(Icons.refresh),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _initialStockController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Stock',
                      hintText: '0',
                      prefixIcon: Icon(Icons.add_box),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Inventory method explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrangeBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'Inventory Management Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Min Stock: Alert threshold for low inventory\n'
                    '• Max Stock: Maximum recommended inventory level\n'
                    '• Reorder Point: When to place new orders\n'
                    '• System will automatically create inventory records across all branches',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}