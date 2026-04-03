import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../providers/menu_provider.dart';

class MenuItemFormDialog extends ConsumerStatefulWidget {
  final dynamic item;

  const MenuItemFormDialog({super.key, this.item});

  @override
  ConsumerState<MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends ConsumerState<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _lowStockController;
  late final TextEditingController _initialStockController;

  String? _selectedCategoryId;
  bool _trackStock = true;
  bool _isLoading = false;

  // Image picker
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _basePriceController = TextEditingController(
      text: widget.item?.pricing.basePrice.toString() ?? '',
    );
    _costPriceController = TextEditingController(
      text: widget.item?.pricing.costPrice?.toString() ?? '',
    );
    _skuController = TextEditingController(text: widget.item?.sku ?? '');
    _barcodeController = TextEditingController(
      text: widget.item?.barcode ?? '',
    );
    _lowStockController = TextEditingController(
      text: (widget.item?.inventory?.lowStockThreshold ?? 10).toString(),
    );
    _initialStockController = TextEditingController(
      text:
          widget.item == null
              ? '0'
              : (widget.item?.inventory?.currentStock ?? 0).toString(),
    );
    _selectedCategoryId = widget.item?.categoryId;
    _trackStock =
        widget.item?.inventory?.trackStock ??
        (widget.item == null ? true : false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _basePriceController.dispose();
    _costPriceController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _lowStockController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      final lang = ref.read(localizationProvider).languageCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.get('select_category_required_message', lang),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String? imageToSave = _pickedImage?.path;

    final bool success;
    if (widget.item == null) {
      success = await ref
          .read(menuProvider.notifier)
          .createMenuItem(
            categoryId: _selectedCategoryId!,
            name: _nameController.text,
            basePrice: double.parse(_basePriceController.text),
            costPrice:
                _costPriceController.text.isEmpty
                    ? null
                    : double.parse(_costPriceController.text),
            sku: _skuController.text.isEmpty ? null : _skuController.text,
            barcode:
                _barcodeController.text.isEmpty
                    ? null
                    : _barcodeController.text,
            trackStock: _trackStock,
            lowStockThreshold: int.parse(_lowStockController.text),
            initialStock:
                _trackStock ? int.parse(_initialStockController.text) : 0,
            isActive: true,
            imagePath: imageToSave,
          );
    } else {
      success = await ref
          .read(menuProvider.notifier)
          .updateMenuItem(
            itemId: widget.item.id,
            name: _nameController.text,
            categoryId: _selectedCategoryId,
            basePrice: double.parse(_basePriceController.text),
            costPrice:
                _costPriceController.text.isEmpty
                    ? null
                    : double.parse(_costPriceController.text),
            trackStock: _trackStock,
            lowStockThreshold: int.parse(_lowStockController.text),
            isActive: true,
            imagePath: imageToSave,
          );
    }

    setState(() => _isLoading = false);

    if (mounted && success) {
      Navigator.pop(context);
      final lang = ref.read(localizationProvider).languageCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item == null
                ? Translations.get('menu_item_created_success', lang)
                : Translations.get('menu_item_updated_success', lang),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menuProvider).categories;
    final lang = ref.watch(localizationProvider).languageCode;
    final isEditing = widget.item != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing
              ? Translations.get('edit_menu_item_title', lang)
              : Translations.get('add_menu_item_title', lang),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                (_isLoading || _nameController.text.trim().isEmpty)
                    ? null
                    : _save,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      Translations.get('save', lang).toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            _nameController.text.trim().isEmpty
                                ? Colors.grey.shade400
                                : AppTheme.primaryOrange,
                      ),
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 1, color: Colors.grey.shade200),

              // ─── Name ───
              _field(
                controller: _nameController,
                label: Translations.get('name', lang),
                onChanged: (_) => setState(() {}),
                validator:
                    (v) =>
                        v?.isEmpty == true
                            ? Translations.get('name_required', lang)
                            : null,
              ),

              // ─── Category ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get('category_label', lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: Translations.get('no_category', lang),
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: false,
                        isDense: true,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryOrange),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      items:
                          categories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(cat.name),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ],
                ),
              ),

              // ─── Price ───
              _field(
                controller: _basePriceController,
                label: Translations.get('sale_price_label', lang),
                hint: Translations.get('sale_price_hint', lang),
                keyboard: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v?.isEmpty == true)
                    return Translations.get('required_field', lang);
                  if (double.tryParse(v!) == null)
                    return Translations.get('invalid_number', lang);
                  return null;
                },
              ),
              // ─── Cost ───
              _field(
                controller: _costPriceController,
                label: Translations.get('cost_price_label', lang),
                prefix: '₭',
                keyboard: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),

              // ─── SKU ───
              _field(controller: _skuController, label: 'SKU'),
              _helperText(Translations.get('sku_helper', lang)),

              // ─── Barcode ───
              _field(
                controller: _barcodeController,
                label: Translations.get('barcode_label', lang),
              ),

              // ─── Inventory Section ───
              _sectionDivider(),

              // Track stock toggle
              SwitchListTile(
                title: Text(
                  Translations.get('track_stock', lang),
                  style: const TextStyle(fontSize: 16),
                ),
                value: _trackStock,
                activeTrackColor: AppTheme.primaryOrange,
                onChanged: (v) => setState(() => _trackStock = v),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),

              if (_trackStock) ...[
                _field(
                  controller: _initialStockController,
                  label: Translations.get('initial_stock_label', lang),
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _field(
                  controller: _lowStockController,
                  label: Translations.get('low_stock_threshold_label', lang),
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _helperText(Translations.get('low_stock_hint', lang)),
              ],

              // ─── Image ───
              _sectionDivider(),

              // Image picker
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Image preview
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          _pickedImage != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              )
                              : (widget.item?.primaryImageUrl != null &&
                                  widget.item!.primaryImageUrl!.isNotEmpty)
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.item!.primaryImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      ),
                                ),
                              )
                              : Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                    ),
                    const SizedBox(width: 20),

                    // Buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.folder, size: 18),
                          label: const Text('CHOOSE PHOTO'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.neutral700,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('TAKE PHOTO'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) setState(() => _pickedImage = image);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          isDense: true,
          filled: false,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          hintStyle: TextStyle(color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primaryOrange),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.error),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.error),
          ),
        ),
      ),
    );
  }

  Widget _helperText(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _sectionDivider() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      height: 8,
      color: Colors.grey.shade100,
    );
  }
}
