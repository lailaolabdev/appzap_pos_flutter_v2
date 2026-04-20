import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/models/modifier.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/services/modifier_service.dart';

class ModifierFormDialog extends ConsumerStatefulWidget {
  final Modifier? modifier;

  const ModifierFormDialog({super.key, this.modifier});

  @override
  ConsumerState<ModifierFormDialog> createState() => _ModifierFormDialogState();
}

class _ModifierFormDialogState extends ConsumerState<ModifierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  // Dynamic option rows
  final List<_OptionRow> _options = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.modifier?.name ?? '');

    if (widget.modifier != null) {
      for (final opt in widget.modifier!.options) {
        _options.add(
          _OptionRow(
            existingId: opt.id,
            nameController: TextEditingController(text: opt.name),
            priceController: TextEditingController(
              text: opt.price > 0 ? opt.price.toStringAsFixed(0) : '0',
            ),
          ),
        );
      }
    }

    if (_options.isEmpty) {
      _addOption();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final opt in _options) {
      opt.nameController.dispose();
      opt.priceController.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add(
        _OptionRow(
          nameController: TextEditingController(),
          priceController: TextEditingController(text: '0'),
        ),
      );
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 1) return;
    setState(() {
      _options[index].nameController.dispose();
      _options[index].priceController.dispose();
      _options.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(modifierServiceProvider);

      final optionData =
          _options
              .where((o) => o.nameController.text.trim().isNotEmpty)
              .map(
                (o) => {
                  'name': o.nameController.text.trim(),
                  'price': double.tryParse(o.priceController.text.trim()) ?? 0,
                  if (o.existingId != null && o.existingId!.isNotEmpty)
                    'id': o.existingId,
                },
              )
              .toList();

      if (widget.modifier == null) {
        await service.createModifier(
          name: _nameController.text.trim(),
          options: optionData,
        );
      } else {
        await service.updateModifier(
          id: widget.modifier!.id,
          name: _nameController.text.trim(),
          options: optionData,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.modifier != null;
    final lang = ref.watch(localizationProvider).languageCode;

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
              ? Translations.get('edit_modifier', lang)
              : Translations.get('create_modifier', lang),
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

              // ─── Modifier Name ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextFormField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 16),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? Translations.get('name_is_required', lang)
                              : null,
                  decoration: InputDecoration(
                    labelText: Translations.get('modifier_name', lang),
                    hintText: 'e.g. Size, Toppings, Sugar Level',
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
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Options Section ───
              _sectionHeader(Translations.get('options', lang)),
              const SizedBox(height: 8),

              ...List.generate(
                _options.length,
                (i) => _buildOptionRow(i, lang),
              ),

              // ─── Add Option Button ───
              InkWell(
                onTap: _addOption,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.primaryOrange,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Translations.get('add_option', lang),
                        style: const TextStyle(
                          color: AppTheme.primaryOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.grey.shade50,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOptionRow(int index, String lang) {
    final opt = _options[index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(
              Icons.drag_handle,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),

          // Name + Price
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: opt.nameController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: Translations.get('option_name', lang),
                    isDense: true,
                    filled: false,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: opt.priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: Translations.get('price', lang),
                    prefixText: '₭',
                    isDense: true,
                    filled: false,
                    labelStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryOrange),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
            onPressed: _options.length > 1 ? () => _removeOption(index) : null,
          ),
        ],
      ),
    );
  }
}

class _OptionRow {
  final String? existingId;
  final TextEditingController nameController;
  final TextEditingController priceController;

  _OptionRow({
    this.existingId,
    required this.nameController,
    required this.priceController,
  });
}
