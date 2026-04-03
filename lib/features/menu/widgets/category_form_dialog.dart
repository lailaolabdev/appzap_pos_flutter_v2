import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../providers/menu_provider.dart';

class CategoryFormDialog extends ConsumerStatefulWidget {
  final dynamic category; // ProductCategory model

  const CategoryFormDialog({super.key, this.category});

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  int _selectedColorIndex = 0;
  bool _isLoading = false;

  // Same 8 colors as menu item form
  static const _colorHex = [
    '#9E9E9E', // grey
    '#E53935', // red
    '#E91E90', // pink
    '#FF6B00', // orange
    '#BDB500', // yellow-green
    '#43A047', // green
    '#1E88E5', // blue
    '#7B1FA2', // purple
  ];

  static const _colors = [
    Color(0xFF9E9E9E),
    Color(0xFFE53935),
    Color(0xFFE91E90),
    Color(0xFFFF6B00),
    Color(0xFFBDB500),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF7B1FA2),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');

    // Initialize selected color from existing category
    if (widget.category?.color != null) {
      final idx = _colorHex.indexOf(widget.category!.color!);
      if (idx >= 0) _selectedColorIndex = idx;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = ref.read(localizationProvider).languageCode;

    setState(() => _isLoading = true);

    final bool success;
    if (widget.category == null) {
      success = await ref
          .read(menuProvider.notifier)
          .createCategory(
            name: _nameController.text,
            color: _colorHex[_selectedColorIndex],
          );
    } else {
      success = await ref
          .read(menuProvider.notifier)
          .updateCategory(
            categoryId: widget.category!.id,
            name: _nameController.text,
            color: _colorHex[_selectedColorIndex],
          );
    }

    setState(() => _isLoading = false);

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.category == null
                ? Translations.get('category_created_successfully', lang)
                : Translations.get('category_updated_successfully', lang),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localizationProvider).languageCode;
    final isEditing = widget.category != null;

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
              ? Translations.get('edit_category_dialog_title', lang)
              : Translations.get('add_category_dialog_title', lang),
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

              // ─── Category Name ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 16),
                  onChanged: (_) => setState(() {}),
                  validator:
                      (v) =>
                          v?.isEmpty == true
                              ? Translations.get('name_required', lang)
                              : null,
                  decoration: InputDecoration(
                    labelText: Translations.get('name', lang),
                    isDense: true,
                    filled: false,
                    labelStyle: TextStyle(color: Colors.grey.shade500),
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
              ),

              const SizedBox(height: 32),

              // ─── Category Color Label ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  Translations.get('category_color', lang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Color Grid (4x2) ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: _colors.length,
                  itemBuilder: (_, i) {
                    final selected = _selectedColorIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _colors[i],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            selected
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 28,
                                )
                                : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: Colors.grey.shade200),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
