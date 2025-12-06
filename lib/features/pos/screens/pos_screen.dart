import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/pos_provider.dart';
import '../widgets/category_bar.dart';
import '../widgets/product_grid.dart';
import '../widgets/cart_panel.dart';
import '../widgets/pos_search_bar.dart';

/// Main POS Screen with product grid and cart
class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    ref.read(productsProvider.notifier).search(query);
  }

  void _handleBarcodeScan(String barcode) {
    final product = ref.read(productsProvider.notifier).findByBarcode(barcode);
    if (product != null) {
      ref.read(cartProvider.notifier).addProduct(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product.name}'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found: $barcode'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Show payment dialog
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PaymentBottomSheet(),
    );

    if (result == true) {
      ref.read(cartProvider.notifier).clear();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final productsState = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AppZap POS'),
            if (user?.branch?.name != null)
              Text(
                user!.branch!.name!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral500,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          // Inventory
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Inventory',
            onPressed: () => context.push(AppRoutes.inventory),
          ),
          // Customers
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Customers',
            onPressed: () => context.push(AppRoutes.customers),
          ),
          // Reports
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Reports',
            onPressed: () => context.push(AppRoutes.reports),
          ),
          // User menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppTheme.primaryOrangeBackground,
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutral900,
                      ),
                    ),
                    Text(
                      user?.role ?? 'Cashier',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left: Products Panel
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Search Bar
                POSSearchBar(
                  controller: _searchController,
                  onSearch: _handleSearch,
                  onBarcodeScan: _handleBarcodeScan,
                ),

                // Category Bar
                CategoryBar(
                  categories: productsState.categories,
                  selectedCategoryId: productsState.selectedCategoryId,
                  onCategorySelected: (categoryId) {
                    ref.read(productsProvider.notifier).selectCategory(categoryId);
                  },
                ),

                // Products Grid
                Expanded(
                  child: productsState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : productsState.error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: AppTheme.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(productsState.error!),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref.read(productsProvider.notifier).refresh();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await ref.read(productsProvider.notifier).refresh();
                              },
                              child: ProductGrid(
                                products: productsState.filteredProducts,
                                onProductTap: (product) {
                                  ref.read(cartProvider.notifier).addProduct(product);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            color: AppTheme.neutral200,
          ),

          // Right: Cart Panel
          SizedBox(
            width: 380,
            child: CartPanel(
              cart: cart,
              onUpdateQuantity: (productId, quantity) {
                ref.read(cartProvider.notifier).updateQuantity(productId, quantity);
              },
              onRemoveItem: (productId) {
                ref.read(cartProvider.notifier).removeItem(productId);
              },
              onClearCart: () {
                ref.read(cartProvider.notifier).clear();
              },
              onCheckout: _handleCheckout,
            ),
          ),
        ],
      ),

      // Mobile: Show cart button if items exist
      floatingActionButton: MediaQuery.of(context).size.width < 800 && cartItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: _handleCheckout,
              backgroundColor: AppTheme.primaryOrange,
              icon: Badge(
                label: Text(cartItemCount.toString()),
                child: const Icon(Icons.shopping_cart),
              ),
              label: Text(CurrencyFormatter.formatLAKWithSymbol(cart.total)),
            )
          : null,
    );
  }
}

/// Payment bottom sheet (placeholder - we'll expand this)
class _PaymentBottomSheet extends ConsumerWidget {
  const _PaymentBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Payment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),

          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrangeBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatLAKWithSymbol(cart.total),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment methods
                  Text(
                    'Select Payment Method',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Cash
                  _PaymentMethodButton(
                    icon: Icons.payments_outlined,
                    label: 'Cash',
                    onTap: () {
                      // TODO: Implement cash payment
                      Navigator.pop(context, true);
                    },
                  ),
                  const SizedBox(height: 12),

                  // PhayPay
                  _PaymentMethodButton(
                    icon: Icons.qr_code_2,
                    label: 'PhayPay (QR)',
                    subtitle: 'JDB, BCEL, LDB, IB',
                    onTap: () {
                      // TODO: Implement PhayPay
                      Navigator.pop(context, true);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.neutral200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrangeBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryOrange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutral500,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}

