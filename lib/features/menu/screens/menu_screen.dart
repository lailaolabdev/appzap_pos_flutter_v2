import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../inventory/widgets/stock_movement_tracker.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Menu Item'),
            content: Text('Are you sure you want to delete "$itemName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: const Text('Delete'),
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
              success ? 'Item deleted successfully' : 'Failed to delete item',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(String categoryId, String categoryName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text('Are you sure you want to delete "$categoryName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: const Text('Delete'),
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
                  ? 'Category deleted successfully'
                  : 'Failed to delete category',
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
          title: const Text('Menu Management'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Menu Items', icon: Icon(Icons.restaurant_menu)),
              Tab(text: 'Categories', icon: Icon(Icons.category)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Stock Movements',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StockMovementTracker(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => ref.read(menuProvider.notifier).refresh(),
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
                  _buildMenuItemsTab(menuState, isMobile),
                  _buildCategoriesTab(menuState, isMobile),
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

  Widget _buildMenuItemsTab(MenuState menuState, bool isMobile) {
    if (menuState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (menuState.items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_menu,
        title: 'No menu items yet',
        subtitle: 'Add your first product to start selling',
        actionLabel: 'Add Item',
        onAction: _showAddItemDialog,
      );
    }

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items...',
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
            onChanged: (value) {
              ref.read(menuProvider.notifier).search(value);
            },
          ),
        ),

        // Category filter chips with visible scrollbar
        if (menuState.categories.isNotEmpty)
          SizedBox(
            height: 60,
            child: Scrollbar(
              thumbVisibility: true, // ✅ Always show scrollbar
              thickness: 4, // ✅ Make it more visible
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
                        label: const Text('All'),
                        selected: menuState.categoryFilter == null,
                        onSelected:
                            null, // ✅ Disable built-in handler, use GestureDetector
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
                              null, // ✅ Disable built-in handler, use GestureDetector
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

        // Items list
        Expanded(
          child: ListView.builder(
            itemCount: menuState.items.length,
            itemBuilder: (context, index) {
              final item = menuState.items[index];
              return _buildMenuItemCard(item, isMobile);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(MenuState menuState, bool isMobile) {
    if (menuState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (menuState.categories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category,
        title: 'No categories yet',
        subtitle: 'Create categories to organize your menu items',
        actionLabel: 'Add Category',
        onAction: _showAddCategoryDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: menuState.categories.length,
      itemBuilder: (context, index) {
        final category = menuState.categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildMenuItemCard(dynamic item, bool isMobile) {
    Category? category;
    try {
      category = ref
          .read(menuProvider)
          .categories
          .firstWhere((c) => c.id == item.categoryId);
    } catch (e) {
      category = null;
    }
    final categoryName = category?.name ?? 'No Category';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading:
            item.images?.isNotEmpty == true
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.images!.first.url,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultItemIcon(),
                  ),
                )
                : _buildDefaultItemIcon(),
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
              const Text('Inactive', style: TextStyle(color: AppTheme.error)),
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

  Widget _buildCategoryCard(dynamic category) {
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
            Text('$itemCount items'),
            if (!category.isActive)
              const Text('Inactive', style: TextStyle(color: AppTheme.error)),
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
    required String actionLabel,
    required VoidCallback onAction,
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
        ),
      ),
    );
  }
}
