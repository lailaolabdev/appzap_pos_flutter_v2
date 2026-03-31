import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/menu_item_form_dialog.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => const MenuItemFormDialog(),
    );
  }

  void _showEditItemDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => MenuItemFormDialog(item: item),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => const CategoryFormDialog(),
    );
  }

  void _showEditCategoryDialog(dynamic category) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(category: category),
    );
  }

  Future<void> _deleteItem(String itemId, String itemName) async {
    final languageCode = ref.read(localizationProvider).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              Translations.get('delete_menu_item_title', languageCode),
            ),
            content: Text(
              Translations.get(
                'delete_menu_item_confirmation',
                languageCode,
              ).replaceAll('{name}', itemName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(Translations.get('cancel', languageCode)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: Text(Translations.get('delete', languageCode)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(menuProvider.notifier)
          .deleteMenuItem(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? Translations.get('item_deleted_successfully', languageCode)
                  : Translations.get('failed_to_delete_item', languageCode),
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(String categoryId, String categoryName) async {
    final languageCode = ref.read(localizationProvider).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              Translations.get('delete_category_title', languageCode),
            ),
            content: Text(
              Translations.get(
                'delete_category_confirmation',
                languageCode,
              ).replaceAll('{name}', categoryName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(Translations.get('cancel', languageCode)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: Text(Translations.get('delete', languageCode)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(menuProvider.notifier)
          .deleteCategory(categoryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? Translations.get(
                    'category_deleted_successfully',
                    languageCode,
                  )
                  : Translations.get('failed_to_delete_category', languageCode),
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final localization = ref.watch(localizationProvider);
    final languageCode = localization.languageCode;
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          leading:
              isMobile
                  ? Builder(
                    builder:
                        (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                  )
                  : null,
          title: Text(Translations.get('menu_management', languageCode)),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: Translations.get('menu_items_tab', languageCode),
                icon: const Icon(Icons.restaurant_menu),
              ),
              Tab(
                text: Translations.get('categories_tab', languageCode),
                icon: const Icon(Icons.category),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: Translations.get('refresh', languageCode),
              onPressed: () {
                ref.read(menuProvider.notifier).refresh();
                ref.read(menuProvider.notifier).filterByCategory(null);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (menuState.error != null) ErrorBanner(message: menuState.error!),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMenuItemsTab(menuState, isMobile, languageCode),
                  _buildCategoriesTab(menuState, isMobile, languageCode),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 0) {
              _showAddItemDialog();
            } else {
              _showAddCategoryDialog();
            }
          },
          backgroundColor: AppTheme.primaryOrange,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMenuItemsTab(
    MenuState menuState,
    bool isMobile,
    String languageCode,
  ) {
    return Column(
      children: [
        // Search bar — always visible so user can clear search
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: Translations.get(
                'search_items_placeholder',
                languageCode,
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(menuProvider.notifier).search('');
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged:
                (_) => setState(() {}), // only update clear button visibility
            onSubmitted: (value) {
              ref.read(menuProvider.notifier).search(value);
            },
          ),
        ),

        // Category filter chips with visible scrollbar
        if (menuState.categories.isNotEmpty)
          SizedBox(
            height: 60,
            child: Scrollbar(
              thumbVisibility: true, // Always show scrollbar
              thickness: 4, // Make it more visible
              radius: const Radius.circular(2),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(menuProvider.notifier).filterByCategory(null);
                      },
                      child: FilterChip(
                        label: Text(Translations.get('all', languageCode)),
                        selected: menuState.categoryFilter == null,
                        onSelected:
                            null, // Disable built-in handler, use GestureDetector
                        backgroundColor: AppTheme.neutral100,
                        selectedColor: AppTheme.primaryOrange,
                        labelStyle: TextStyle(
                          color:
                              menuState.categoryFilter == null
                                  ? Colors.white
                                  : AppTheme.neutral700,
                          fontWeight:
                              menuState.categoryFilter == null
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                        ),
                        showCheckmark: false,
                      ),
                    ),
                  ),
                  ...menuState.categories.map((category) {
                    final isSelected = menuState.categoryFilter == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(menuProvider.notifier)
                              .filterByCategory(category.id);
                        },
                        child: FilterChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected:
                              null, // Disable built-in handler, use GestureDetector
                          backgroundColor: AppTheme.neutral100,
                          selectedColor: AppTheme.primaryOrange,
                          labelStyle: TextStyle(
                            color:
                                isSelected ? Colors.white : AppTheme.neutral700,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          showCheckmark: false,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // Items list, loading, or empty state
        Expanded(
          child:
              menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : menuState.items.isEmpty
                  ? _buildEmptyState(
                    icon: Icons.restaurant_menu,
                    title:
                        menuState.searchQuery.isNotEmpty
                            ? Translations.get('no_results_found', languageCode)
                            : Translations.get(
                              'no_menu_items_yet',
                              languageCode,
                            ),
                    subtitle:
                        menuState.searchQuery.isNotEmpty
                            ? Translations.get(
                              'try_different_search',
                              languageCode,
                            )
                            : Translations.get(
                              'add_first_product_to_sell',
                              languageCode,
                            ),
                    actionLabel:
                        menuState.searchQuery.isNotEmpty
                            ? null
                            : Translations.get('add_item', languageCode),
                    onAction:
                        menuState.searchQuery.isNotEmpty
                            ? null
                            : _showAddItemDialog,
                  )
                  : ListView.builder(
                    itemCount: menuState.items.length,
                    itemBuilder: (context, index) {
                      final item = menuState.items[index];
                      return _buildMenuItemCard(item, isMobile, languageCode);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(
    MenuState menuState,
    bool isMobile,
    String languageCode,
  ) {
    if (menuState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (menuState.categories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category,
        title: Translations.get('no_categories_yet', languageCode),
        subtitle: Translations.get(
          'create_categories_to_organize',
          languageCode,
        ),
        actionLabel: Translations.get('add_category', languageCode),
        onAction: _showAddCategoryDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: menuState.categories.length,
      itemBuilder: (context, index) {
        final category = menuState.categories[index];
        return _buildCategoryCard(category, languageCode);
      },
    );
  }

  Widget _buildMenuItemCard(dynamic item, bool isMobile, String languageCode) {
    Category? category;
    try {
      category = ref
          .read(menuProvider)
          .categories
          .firstWhere((c) => c.id == item.categoryId);
    } catch (e) {
      category = null;
    }
    final categoryName =
        category?.name ?? Translations.get('no_category', languageCode);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: () {
          final images = item.images as List<dynamic>;
          final imageUrl =
              images.isNotEmpty ? (images.first.url as String?) ?? '' : '';
          return imageUrl.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultItemIcon(),
                ),
              )
              : _buildDefaultItemIcon();
        }(),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(categoryName),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(item.pricing.basePrice),
              style: TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!item.isActive)
              Text(
                Translations.get('inactive', languageCode),
                style: const TextStyle(color: AppTheme.error),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.info),
              onPressed: () => _showEditItemDialog(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.error),
              onPressed: () => _deleteItem(item.id, item.name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category, String languageCode) {
    final itemCount =
        ref
            .read(menuProvider)
            .items
            .where((item) => item.categoryId == category.id)
            .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              category.color != null
                  ? Color(int.parse(category.color!.replaceAll('#', '0xFF')))
                  : AppTheme.primaryOrange,
          child: Text(
            category.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description != null) Text(category.description!),
            const SizedBox(height: 4),
            Text(
              '$itemCount ${Translations.get('items', languageCode)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!category.isActive)
              Text(
                Translations.get('inactive', languageCode),
                style: const TextStyle(color: AppTheme.error),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.info),
              onPressed: () => _showEditCategoryDialog(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.error),
              onPressed: () => _deleteCategory(category.id, category.name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultItemIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.neutral200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, color: AppTheme.neutral500),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.neutral300),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.neutral500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral400),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
