import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/cart.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/payment.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../customers/widgets/customer_lookup_dialog.dart';
import '../../customers/widgets/redeem_points_dialog.dart';
import '../../payment/providers/payment_provider.dart';
import '../../payment/widgets/cash_payment_dialog.dart';
import '../../payment/widgets/phaypay_dialog.dart';
import '../providers/pos_provider.dart';
import '../widgets/category_bar.dart';
import '../widgets/product_grid.dart';
import '../widgets/cart_panel.dart';
import '../widgets/pos_search_bar.dart';
import '../widgets/barcode_scanner_widget.dart';

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

  Future<void> _handleBarcodeScan(String barcode) async {
    // First try local search (synchronous)
    final localProduct = ref
        .read(productsProvider.notifier)
        .findByBarcode(barcode);

    if (localProduct != null) {
      // Found locally - add to cart immediately
      ref.read(cartProvider.notifier).addProduct(localProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${localProduct.name}'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppTheme.success,
        ),
      );
      return;
    }

    // Not found locally - show loading and search via API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Searching product...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.neutral600,
      ),
    );

    try {
      final apiProduct = await ref
          .read(productsProvider.notifier)
          .findByBarcodeAsync(barcode);

      if (!mounted) return;

      if (apiProduct != null) {
        // Found via API - add to cart
        ref.read(cartProvider.notifier).addProduct(apiProduct);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${apiProduct.name} (found online)'),
            duration: const Duration(seconds: 20),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        // Not found anywhere
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product not found: $barcode'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  /// Open barcode scanner camera
  Future<void> _openBarcodeScanner() async {
    try {
      // Navigate to barcode scanner
      final String? scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder:
              (context) => BarcodeScannerWidget(
                onBarcodeScanned: (barcode) {
                  // This will be called when a barcode is detected
                  _handleBarcodeScan(barcode);
                },
              ),
        ),
      );

      // Handle the scanned barcode if returned
      if (scannedCode != null && scannedCode.isNotEmpty) {
        _handleBarcodeScan(scannedCode);
      }
    } catch (e) {
      // Handle any errors (like camera permissions)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open scanner: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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

    // Show payment method selection
    // ✅ Capture parent context before showing modal
    final parentContext = context;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _PaymentBottomSheet(
            cart: cart,
            parentContext: parentContext, // Pass parent context
          ),
    );

    if (result == true) {
      // Payment successful - clear cart
      ref.read(cartProvider.notifier).clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleApplyLoyalty() async {
    // Step 1: Look up customer
    final Customer? customer = await showDialog<Customer>(
      context: context,
      builder: (context) => const CustomerLookupDialog(),
    );

    if (customer == null) return;

    // Step 2: Show redemption dialog
    final cart = ref.read(cartProvider);
    final int? pointsRedeemed = await showDialog<int>(
      context: context,
      builder:
          (context) => RedeemPointsDialog(
            customer: customer,
            orderTotal: cart.total,
            orderId:
                'TEMP-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
          ),
    );

    if (pointsRedeemed != null && pointsRedeemed > 0 && mounted) {
      // Calculate discount (100 points = 10,000 LAK, so 1 point = 100 LAK)
      final discountAmount = pointsRedeemed * 100.0;

      // Add customer to cart
      ref.read(cartProvider.notifier).setCustomer(customer);

      // Add loyalty discount to cart
      ref
          .read(cartProvider.notifier)
          .addDiscount(
            CartDiscount(
              type: DiscountType.fixed,
              value: discountAmount,
              reason: 'Loyalty Points ($pointsRedeemed pts)',
            ),
          );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Applied $pointsRedeemed loyalty points (${CurrencyFormatter.format(discountAmount)} discount)',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        // Add drawer for mobile
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar:
            isMobile
                ? AppBar(
                  toolbarHeight: 70,
                  title: Row(
                    children: [
                      // Search bar
                      Expanded(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.neutral200),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _handleSearch,
                            decoration: InputDecoration(
                              hintText: 'Search products or scan barc...',
                              hintStyle: TextStyle(
                                color: AppTheme.neutral400,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppTheme.neutral500,
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Barcode scanner button
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryOrange.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.qr_code_scanner,
                            color: AppTheme.primaryOrange,
                            size: 22,
                          ),
                          tooltip: 'Scan Barcode',
                          padding: EdgeInsets.zero,
                          onPressed: _openBarcodeScanner,
                        ),
                      ),
                    ],
                  ),
                )
                : AppBar(
                  // Tablet/Desktop - keep simple
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Scan Barcode',
                      onPressed: _openBarcodeScanner,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
        body:
            isMobile
                ? _buildMobileLayout(productsState, cart)
                : _buildTabletLayout(productsState, cart),
        // Bottom bar for mobile only
        bottomNavigationBar:
            isMobile ? _buildBottomBar(cart, cartItemCount) : null,
      ),
    );
  }

  /// Mobile layout: Full-screen products + cart modal
  Widget _buildMobileLayout(dynamic productsState, Cart cart) {
    return Column(
      children: [
        // Category Bar
        CategoryBar(
          categories: productsState.categories,
          selectedCategoryId: productsState.selectedCategoryId,
          onCategorySelected: (categoryId) {
            ref.read(productsProvider.notifier).selectCategory(categoryId);
          },
        ),

        // Products Grid
        Expanded(child: _buildProductsGrid(productsState)),
      ],
    );
  }

  /// Tablet layout: Products + Cart side by side
  Widget _buildTabletLayout(dynamic productsState, Cart cart) {
    return Row(
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
                onBarcodeScan: (barcode) => _handleBarcodeScan(barcode),
              ),

              // Category Bar
              CategoryBar(
                categories: productsState.categories,
                selectedCategoryId: productsState.selectedCategoryId,
                onCategorySelected: (categoryId) {
                  ref
                      .read(productsProvider.notifier)
                      .selectCategory(categoryId);
                },
              ),

              // Products Grid
              Expanded(child: _buildProductsGrid(productsState)),
            ],
          ),
        ),

        // Divider
        Container(width: 1, color: AppTheme.neutral200),

        // Right: Cart Panel
        SizedBox(
          width: 350,
          child: CartPanel(
            cart: cart,
            onUpdateQuantity: (productId, quantity) {
              ref
                  .read(cartProvider.notifier)
                  .updateQuantity(productId, quantity);
            },
            onRemoveItem: (productId) {
              ref.read(cartProvider.notifier).removeItem(productId);
            },
            onClearCart: () {
              ref.read(cartProvider.notifier).clear();
            },
            onApplyLoyalty: _handleApplyLoyalty,
            onCheckout: _handleCheckout,
          ),
        ),
      ],
    );
  }

  /// Bottom bar with SAVE and checkout buttons (mobile only - 2 buttons, single line)
  Widget _buildBottomBar(Cart cart, int cartItemCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // SAVE button (no icon, single line)
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      cart.items.isEmpty
                          ? null
                          : () {
                            // TODO: Implement save/on hold functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Save feature coming soon'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color:
                          cart.items.isEmpty
                              ? AppTheme.neutral300
                              : AppTheme.neutral600,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          cart.items.isEmpty
                              ? AppTheme.neutral400
                              : AppTheme.neutral800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Checkout button - orange, price only with count
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      cart.items.isEmpty
                          ? null
                          : () => _showMobileCart(context), // Show cart first
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: AppTheme.neutral300,
                  ),
                  child: Text(
                    cart.items.isEmpty
                        ? '0 ₭ (0)'
                        : '${CurrencyFormatter.formatLAKWithSymbol(cart.total)} ($cartItemCount)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Products grid (shared by mobile and tablet)
  Widget _buildProductsGrid(dynamic productsState) {
    if (productsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
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
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(productsProvider.notifier).refresh();
      },
      child: ProductGrid(
        products: productsState.filteredProducts,
        onProductTap: (product) {
          ref.read(cartProvider.notifier).addProduct(product);
        },
      ),
    );
  }

  /// Show cart modal on mobile (reactive with Consumer)
  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Cart panel - Using Consumer to watch cart changes
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final cart = ref.watch(cartProvider);

                          return CartPanel(
                            cart: cart,
                            onUpdateQuantity: (productId, quantity) {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(productId, quantity);
                            },
                            onRemoveItem: (productId) {
                              ref
                                  .read(cartProvider.notifier)
                                  .removeItem(productId);
                            },
                            onClearCart: () {
                              ref.read(cartProvider.notifier).clear();
                            },
                            onApplyLoyalty: _handleApplyLoyalty,
                            onCheckout: () {
                              Navigator.pop(context); // Close modal first
                              _handleCheckout();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

/// Payment bottom sheet with payment method selection
class _PaymentBottomSheet extends ConsumerWidget {
  final Cart cart;
  final BuildContext parentContext; // ✅ Parent context from POSScreen

  const _PaymentBottomSheet({required this.cart, required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    padding: const EdgeInsets.all(12),
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
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                            fontSize: 24,
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
                    onTap: () async {
                      // ✅ Get cart notifier BEFORE closing bottom sheet
                      final cartNotifier = ref.read(cartProvider.notifier);

                      // ✅ Close bottom sheet (using modal's context)
                      Navigator.pop(context);

                      // ✅ Handle payment using PARENT context (POSScreen context, still mounted!)
                      await _handleCashPayment(
                        parentContext,
                        cartNotifier,
                        cart,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // PhayPay
                  _PaymentMethodButton(
                    icon: Icons.qr_code_2,
                    label: 'PhayPay (QR)',
                    subtitle: 'JDB, BCEL, LDB, IB',
                    onTap: () {
                      // ✅ Close bottom sheet (using modal's context)
                      Navigator.pop(context);

                      // ✅ Handle payment using PARENT context (POSScreen context, still mounted!)
                      _handlePhayPayPayment(parentContext, ref, cart);
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

/// Handle cash payment (free function)
/// Opens cash dialog which handles payment processing internally with its own ref
Future<void> _handleCashPayment(
  BuildContext context,
  CartNotifier cartNotifier,
  Cart cart,
) async {
  // Navigate to full-screen cash payment page
  print('📱 Opening CashPaymentDialog...');

  // ✅ Dialog handles payment internally (no disposal issues!)
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder:
          (context) => CashPaymentDialog(totalAmount: cart.total, cart: cart),
    ),
  );

  print('📥 CashPaymentDialog returned with result: $result');
  print('   context.mounted (after dialog): ${context.mounted}');

  // If dialog was cancelled (null) or failed
  if (result == null || result['success'] != true) {
    print('❌ Payment cancelled or failed');
    print('   result == null: ${result == null}');
    print('   result[success]: ${result?['success']}');
    return;
  }

  print('✅ Payment result is success, proceeding...');

  // ✅ Success! Dialog is already closed, show success on main screen
  if (!context.mounted) {
    print('⚠️  Context not mounted, aborting success dialog');
    return;
  }

  print('✅ Context is mounted, proceeding with success flow...');

  final tendered = result['tendered'] as double? ?? cart.total;
  final change = result['change'] as double? ?? 0;

  print('💰 Payment amounts:');
  print('   Total: ${cart.total}');
  print('   Tendered: $tendered');
  print('   Change: $change');

  // ✅ Clear cart immediately after successful payment (using global Riverpod state)
  print('🔄 Clearing cart (Riverpod global state)...');
  try {
    cartNotifier.clear();
    print('✅ Cart cleared successfully');
  } catch (e) {
    print('❌ Error clearing cart: $e');
  }

  print('🎉 Showing success dialog for 2 seconds...');

  try {
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: AppTheme.success,
              size: 64,
            ),
            title: const Text('Payment Successful!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${CurrencyFormatter.formatLAKWithSymbol(cart.total)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tendered: ${CurrencyFormatter.formatLAKWithSymbol(tendered)}',
                ),
                Text(
                  'Change: ${CurrencyFormatter.formatLAKWithSymbol(change)}',
                ),
                const SizedBox(height: 12),
                const Text(
                  '✓ Order created successfully',
                  style: TextStyle(color: AppTheme.success),
                ),
              ],
            ),
          ),
    );
    print('✅ Success dialog shown');

    // ✅ Auto-dismiss after 2 seconds
    print('⏱️  Waiting 2 seconds...');
    await Future.delayed(const Duration(seconds: 2));
    print('⏱️  2 seconds elapsed');

    if (context.mounted) {
      Navigator.pop(context); // Close success dialog
      print('✅ Success dialog auto-closed');
    } else {
      print('⚠️  Context not mounted, cannot close dialog');
    }
  } catch (e, stackTrace) {
    print('❌ Error showing/closing success dialog: $e');
    print('📍 Stack trace: $stackTrace');
  }
}

/// Handle PhayPay payment (free function)
/// Shows loading on main screen (no layering issues!)
Future<void> _handlePhayPayPayment(
  BuildContext context,
  WidgetRef ref,
  Cart cart,
) async {
  // Navigate to full-screen bank selection page
  final bankMethod = await Navigator.push<PhayPayBankMethod>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder:
          (context) => PhayPayBankSelectionDialog(
            amount: cart.total,
            onBankSelected: (bank) {
              Navigator.pop(context, bank);
            },
          ),
    ),
  );

  if (bankMethod == null) {
    print('❌ PhayPay payment cancelled - no bank selected');
    return;
  }

  if (!context.mounted) {
    print('⚠️ Context not mounted after bank selection, aborting...');
    return;
  }

  // Create payment
  final success = await ref
      .read(paymentProvider.notifier)
      .processPhayPayPayment(
        amount: cart.total,
        bankMethod: bankMethod,
        cart: cart,
      );

  if (!success) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create payment. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
    return;
  }

  if (!context.mounted) {
    print('⚠️ Context not mounted after payment creation, aborting...');
    return;
  }

  // Navigate to full-screen QR page
  await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => const PhayPayQRDialog(),
    ),
  );
}
