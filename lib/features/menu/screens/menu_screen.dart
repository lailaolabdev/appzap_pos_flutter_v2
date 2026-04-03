import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/menu_item_form_dialog.dart';
import '../widgets/modifier_form_dialog.dart';
import '../../../core/models/modifier.dart';
import '../../../core/services/modifier_service.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  // 0 = main list, 1 = items, 2 = categories
  int _currentPage = 0;
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Multi-select
  final Set<String> _selectedItemIds = {};
  bool get _isItemSelectMode => _selectedItemIds.isNotEmpty;
  final Set<String> _selectedCategoryIds = {};
  bool get _isCategorySelectMode => _selectedCategoryIds.isNotEmpty;
  final Set<String> _selectedModifierIds = {};
  bool get _isModifierSelectMode => _selectedModifierIds.isNotEmpty;

  // Modifiers
  List<Modifier> _modifiers = [];
  bool _modifiersLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToPage(int page) => setState(() {
    _currentPage = page;
    _isSearchVisible = false;
    _searchController.clear();
    if (page != 1) ref.read(menuProvider.notifier).search('');
  });

  void _goBack() => _goToPage(0);

  // ─── Dialogs ───
  void _showAddItemDialog() {
    showDialog(context: context, builder: (_) => const MenuItemFormDialog());
  }

  void _showEditItemDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (_) => MenuItemFormDialog(item: item),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(context: context, builder: (_) => const CategoryFormDialog());
  }

  void _showEditCategoryDialog(dynamic category) {
    showDialog(
      context: context,
      builder: (_) => CategoryFormDialog(category: category),
    );
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedItems(String lang) async {
    // final count = _selectedItemIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(Translations.get('delete_menu_item_title', lang)),
            content: Text(
              Translations.get('delete_menu_item_confirmation', lang),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  Translations.get('cancel', lang).toUpperCase(),
                  style: const TextStyle(color: AppTheme.primaryOrange),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  Translations.get('delete', lang).toUpperCase(),
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final ids = List<String>.from(_selectedItemIds);
      setState(() => _selectedItemIds.clear());

      int successCount = 0;
      for (final id in ids) {
        final ok = await ref.read(menuProvider.notifier).deleteMenuItem(id);
        if (ok) successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount ${successCount == 1 ? 'item' : 'items'} deleted',
            ),
            backgroundColor:
                successCount > 0 ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final lang = ref.watch(localizationProvider).languageCode;
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        body: SafeArea(
          child:
              _currentPage == 0
                  ? _buildMainList(lang)
                  : _currentPage == 1
                  ? _buildItemsPage(menuState, lang)
                  : _currentPage == 2
                  ? _buildCategoriesPage(menuState, lang)
                  : _buildModifiersPage(lang),
        ),
        floatingActionButton:
            _currentPage != 0
                ? FloatingActionButton(
                  onPressed:
                      _currentPage == 1
                          ? _showAddItemDialog
                          : _currentPage == 2
                          ? _showAddCategoryDialog
                          : _showAddModifierDialog,
                  backgroundColor: AppTheme.primaryOrange,
                  child: const Icon(Icons.add, color: Colors.white),
                )
                : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Main List Page (Image 1)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildMainList(String lang) {
    return Column(
      children: [
        // AppBar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, size: 24),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 8),
              Text(
                Translations.get('menu_items_tab', lang),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.neutral200),

        // Menu sections
        Expanded(
          child: ListView(
            children: [
              _buildMenuItem(
                icon: Icons.format_list_bulleted,
                label: Translations.get('menu_items_tab', lang),
                onTap: () => _goToPage(1),
              ),
              _buildMenuItem(
                icon: Icons.copy_outlined,
                label: Translations.get('categories_tab', lang),
                onTap: () => _goToPage(2),
              ),
              _buildMenuItem(
                icon: Icons.tune,
                label: Translations.get('modifiers', lang),
                onTap: () {
                  _goToPage(3);
                  _loadModifiers();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppTheme.neutral600),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Items Page (Image 2)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildItemsPage(MenuState menuState, String lang) {
    return Column(
      children: [
        // AppBar — switches between normal and selection mode
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          color: _isItemSelectMode ? AppTheme.primaryOrangeLight : Colors.white,
          child:
              _isItemSelectMode
                  ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed:
                            () => setState(() => _selectedItemIds.clear()),
                      ),
                      Text(
                        '${_selectedItemIds.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                        onPressed: () => _deleteSelectedItems(lang),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _goBack,
                      ),
                      if (_isSearchVisible)
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onSubmitted:
                                (v) =>
                                    ref.read(menuProvider.notifier).search(v),
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: Translations.get(
                                'search_items_placeholder',
                                lang,
                              ),
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                            ),
                          ),
                        )
                      else ...[
                        Expanded(
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              ref
                                  .read(menuProvider.notifier)
                                  .filterByCategory(
                                    value == '_all_' ? null : value,
                                  );
                            },
                            offset: const Offset(0, 40),
                            color: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            itemBuilder:
                                (_) => [
                                  PopupMenuItem<String>(
                                    value: '_all_',
                                    child: Text(
                                      Translations.get('all_items', lang),
                                      style: TextStyle(
                                        fontWeight:
                                            menuState.categoryFilter == null
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  ...menuState.categories.map(
                                    (cat) => PopupMenuItem<String>(
                                      value: cat.id,
                                      child: Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontWeight:
                                              menuState.categoryFilter == cat.id
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getSelectedCategoryName(menuState, lang),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 28),
                              ],
                            ),
                          ),
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                          _isSearchVisible ? Icons.close : Icons.search,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchController.clear();
                              ref.read(menuProvider.notifier).search('');
                            }
                          });
                        },
                      ),
                    ],
                  ),
        ),
        Divider(
          height: 1,
          color:
              _isItemSelectMode
                  ? AppTheme.primaryOrangeLight
                  : AppTheme.neutral200,
        ),

        // Items list
        Expanded(
          child:
              menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : menuState.items.isEmpty
                  ? Center(
                    child: Text(
                      Translations.get('no_menu_items_yet', lang),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: () => ref.read(menuProvider.notifier).refresh(),
                    child: ListView.separated(
                      itemCount: menuState.items.length,
                      separatorBuilder:
                          (_, __) => const Divider(
                            height: 1,
                            color: AppTheme.neutral200,
                          ),
                      itemBuilder:
                          (_, i) => _buildItemRow(menuState.items[i], lang),
                    ),
                  ),
        ),
      ],
    );
  }

  String _getSelectedCategoryName(MenuState state, String lang) {
    if (state.categoryFilter == null)
      return Translations.get('all_items', lang);
    try {
      return state.categories
          .firstWhere((c) => c.id == state.categoryFilter)
          .name;
    } catch (_) {
      return Translations.get('all_items', lang);
    }
  }

  Widget _buildItemRow(Product item, String lang) {
    final hasImage = item.images.isNotEmpty && item.images.first.url.isNotEmpty;
    final stock = item.inventory?.currentStock;
    final isLowStock = item.inventory?.isLowStock ?? false;
    final price = item.pricing.basePrice;
    final colorIndex = item.name.hashCode % _fallbackColors.length;
    final circleColor = _fallbackColors[colorIndex.abs()];
    final isSelected = _selectedItemIds.contains(item.id);

    return InkWell(
      onTap:
          _isItemSelectMode
              ? () => _toggleItemSelection(item.id)
              : () => _showEditItemDialog(item),
      onLongPress: () {
        if (!_isItemSelectMode) {
          _toggleItemSelection(item.id);
        }
      },
      child: Container(
        color:
            isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Check circle when selected, otherwise image/shape
            SizedBox(
              width: 48,
              height: 48,
              child:
                  isSelected
                      ? Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.neutral800,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                      : hasImage
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          item.images.first.url,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  _colorCircle(item.name, circleColor),
                        ),
                      )
                      : _colorCircle(item.name, circleColor),
            ),
            const SizedBox(width: 16),

            // Name + stock
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (stock != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$stock ${Translations.get('in_stock', lang)}',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isLowStock ? AppTheme.error : Colors.grey.shade500,
                        fontWeight:
                            isLowStock ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price
            Text(
              price > 0
                  ? CurrencyFormatter.formatLAKWithSymbol(price)
                  : 'Variable',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Categories Page (Image 3)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCategoriesPage(MenuState menuState, String lang) {
    return Column(
      children: [
        // AppBar — switches between normal and selection mode
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          color:
              _isCategorySelectMode
                  ? AppTheme.primaryOrangeLight
                  : Colors.white,
          child:
              _isCategorySelectMode
                  ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed:
                            () => setState(() => _selectedCategoryIds.clear()),
                      ),
                      Text(
                        '${_selectedCategoryIds.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                        onPressed: () => _deleteSelectedCategories(lang),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _goBack,
                      ),
                      Text(
                        Translations.get('categories_tab', lang),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
        ),
        Divider(
          height: 1,
          color:
              _isCategorySelectMode
                  ? AppTheme.primaryOrangeLight
                  : AppTheme.neutral200,
        ),

        // Categories list
        Expanded(
          child:
              menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : menuState.categories.isEmpty
                  ? Center(
                    child: Text(
                      Translations.get('no_categories_yet', lang),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                  )
                  : ListView.separated(
                    itemCount: menuState.categories.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                          height: 1,
                          color: AppTheme.neutral200,
                        ),
                    itemBuilder:
                        (_, i) => _buildCategoryRow(
                          menuState.categories[i],
                          menuState,
                          lang,
                        ),
                  ),
        ),
      ],
    );
  }

  void _toggleCategorySelection(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedCategories(String lang) async {
    // final count = _selectedCategoryIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(Translations.get('delete_category_title', lang)),
            content: Text(
              Translations.get('delete_category_confirmation', lang),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  Translations.get('cancel', lang).toUpperCase(),
                  style: const TextStyle(color: AppTheme.primaryOrange),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  Translations.get('delete', lang).toUpperCase(),
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final ids = List<String>.from(_selectedCategoryIds);
      setState(() => _selectedCategoryIds.clear());

      int successCount = 0;
      for (final id in ids) {
        final ok = await ref.read(menuProvider.notifier).deleteCategory(id);
        if (ok) successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount ${successCount == 1 ? 'category' : 'categories'} deleted',
            ),
            backgroundColor:
                successCount > 0 ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildCategoryRow(Category cat, MenuState state, String lang) {
    final itemCount =
        state.items.where((item) => item.categoryId == cat.id).length;
    final color =
        cat.color != null
            ? Color(int.parse(cat.color!.replaceAll('#', '0xFF')))
            : AppTheme.neutral400;
    final isSelected = _selectedCategoryIds.contains(cat.id);

    return InkWell(
      onTap:
          _isCategorySelectMode
              ? () => _toggleCategorySelection(cat.id)
              : () => _showEditCategoryDialog(cat),
      onLongPress: () {
        if (!_isCategorySelectMode) {
          _toggleCategorySelection(cat.id);
        }
      },
      child: Container(
        color:
            isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Color circle or check
            if (isSelected)
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neutral800,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            const SizedBox(width: 16),

            // Name + count
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : Translations.get('items', lang)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Modifiers Page (Page 3)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _loadModifiers() async {
    setState(() => _modifiersLoading = true);
    try {
      final service = ref.read(modifierServiceProvider);
      final result = await service.getModifiers();
      if (mounted) setState(() => _modifiers = result);
    } catch (_) {}
    if (mounted) setState(() => _modifiersLoading = false);
  }

  void _showAddModifierDialog() async {
    final result = await showDialog(
      context: context,
      builder: (_) => const ModifierFormDialog(),
    );
    if (result == true) _loadModifiers();
  }

  void _showEditModifierDialog(Modifier modifier) async {
    final result = await showDialog(
      context: context,
      builder: (_) => ModifierFormDialog(modifier: modifier),
    );
    if (result == true) _loadModifiers();
  }

  void _toggleModifierSelection(String id) {
    setState(() {
      if (_selectedModifierIds.contains(id)) {
        _selectedModifierIds.remove(id);
      } else {
        _selectedModifierIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedModifiers(String lang) async {
    final count = _selectedModifierIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(Translations.get('delete_modifiers', lang)),
            content: Text(
              Translations.get(
                'delete_modifiers_confirmation',
                lang,
              ).replaceAll('{count}', count.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  Translations.get('cancel', lang),
                  style: TextStyle(color: AppTheme.primaryOrange),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  Translations.get('delete', lang),
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final ids = List<String>.from(_selectedModifierIds);
      setState(() => _selectedModifierIds.clear());
      final service = ref.read(modifierServiceProvider);
      for (final id in ids) {
        try {
          await service.deleteModifier(id);
        } catch (_) {}
      }
      _loadModifiers();
    }
  }

  Widget _buildModifiersPage(String lang) {
    return Column(
      children: [
        // AppBar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          color:
              _isModifierSelectMode
                  ? AppTheme.primaryOrangeLight
                  : Colors.white,
          child:
              _isModifierSelectMode
                  ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed:
                            () => setState(() => _selectedModifierIds.clear()),
                      ),
                      Text(
                        '${_selectedModifierIds.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                        onPressed: () => _deleteSelectedModifiers(lang),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _goBack,
                      ),
                      Text(
                        Translations.get('modifiers', lang),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                    ],
                  ),
        ),
        Divider(
          height: 1,
          color:
              _isModifierSelectMode
                  ? AppTheme.primaryOrangeLight
                  : AppTheme.neutral200,
        ),

        // Content
        Expanded(
          child:
              _modifiersLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _modifiers.isEmpty
                  ? _buildModifiersEmpty(lang)
                  : ListView.separated(
                    itemCount: _modifiers.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                          height: 1,
                          color: AppTheme.neutral200,
                        ),
                    itemBuilder: (_, i) => _buildModifierRow(_modifiers[i]),
                  ),
        ),
      ],
    );
  }

  Widget _buildModifiersEmpty(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.playlist_add_check,
              size: 56,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            Translations.get('no_modifiers_yet', lang),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              Translations.get('no_modifiers_hint', lang),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierRow(Modifier mod) {
    final isSelected = _selectedModifierIds.contains(mod.id);

    return InkWell(
      onTap:
          _isModifierSelectMode
              ? () => _toggleModifierSelection(mod.id)
              : () => _showEditModifierDialog(mod),
      onLongPress: () {
        if (!_isModifierSelectMode) _toggleModifierSelection(mod.id);
      },
      child: Container(
        color:
            isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon or check
            if (isSelected)
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neutral800,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: Icon(Icons.tune, color: Colors.grey.shade500, size: 24),
              ),
            const SizedBox(width: 16),

            // Name + options summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mod.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (mod.optionsSummary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      mod.optionsSummary,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _colorCircle(String name, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  static const _fallbackColors = [
    Color(0xFFFF6B00),
    Color(0xFFE4B800),
    Color(0xFFE53935),
    Color(0xFF7B1FA2),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
    Color(0xFFC2185B),
  ];
}
