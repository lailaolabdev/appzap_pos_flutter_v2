import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/models/cart.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../customers/widgets/customer_lookup_dialog.dart';
import '../../customers/widgets/redeem_points_dialog.dart';
import '../../payment/widgets/cash_payment_dialog.dart';
import '../../../core/services/checkout_service.dart';
import '../providers/pos_provider.dart';
import '../widgets/cart_panel.dart';
import '../widgets/barcode_scanner_widget.dart';

/// Main POS Screen — Loyverse-style design
class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // Business Logic (unchanged)
  // ═══════════════════════════════════════════════════════════════════

  void _handleSearch(String query) {
    ref.read(productsProvider.notifier).search(query);
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    final lang = ref.read(localizationProvider).languageCode;
    final localProduct = ref
        .read(productsProvider.notifier)
        .findByBarcode(barcode);

    if (localProduct != null) {
      ref.read(cartProvider.notifier).addProduct(localProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Translations.get('added_product', lang)} ${localProduct.name}',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: AppTheme.success,
        ),
      );
      return;
    }

    try {
      final apiProduct = await ref
          .read(productsProvider.notifier)
          .findByBarcodeAsync(barcode);
      if (!mounted) return;
      if (apiProduct != null) {
        ref.read(cartProvider.notifier).addProduct(apiProduct);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Translations.get('product_not_found', lang)}: $barcode',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Translations.get('search_failed', lang)}: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _openBarcodeScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                BarcodeScannerWidget(onBarcodeScanned: _handleBarcodeScan),
      ),
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _handleBarcodeScan(scannedCode);
    }
  }

  Future<void> _handleCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      final lang = ref.read(localizationProvider).languageCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.get('cart_is_empty', lang)),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final cartNotifier = ref.read(cartProvider.notifier);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) => CashPaymentDialog(totalAmount: cart.total, cart: cart),
      ),
    );

    if (result == null || result['success'] != true) return;
    if (!mounted) return;

    cartNotifier.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Translations.get(
            'payment_successful',
            ref.read(localizationProvider).languageCode,
          ),
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  // Future<void> _handleApplyLoyalty() async {
  //   final lang = ref.read(localizationProvider).languageCode;
  //   final Customer? customer = await showDialog<Customer>(
  //     context: context,
  //     builder: (context) => const CustomerLookupDialog(),
  //   );
  //   if (customer == null) return;

  //   final cart = ref.read(cartProvider);
  //   final int? pointsRedeemed = await showDialog<int>(
  //     context: context,
  //     builder:
  //         (context) => RedeemPointsDialog(
  //           customer: customer,
  //           orderTotal: cart.total,
  //           orderId: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
  //         ),
  //   );

  //   if (pointsRedeemed != null && pointsRedeemed > 0 && mounted) {
  //     final discountAmount = pointsRedeemed * 100.0;
  //     ref.read(cartProvider.notifier).setCustomer(customer);
  //     ref
  //         .read(cartProvider.notifier)
  //         .addDiscount(
  //           CartDiscount(
  //             type: DiscountType.fixed,
  //             value: discountAmount,
  //             reason: 'Loyalty Points ($pointsRedeemed pts)',
  //           ),
  //         );
  //   }
  // }

  void _addToCart(Product product) {
    ref.read(cartProvider.notifier).addProduct(product);
  }

  Future<void> _handleSaveOrder(Cart cart) async {
    final lang = ref.read(localizationProvider).languageCode;
    try {
      final checkoutService = ref.read(checkoutServiceProvider);
      await checkoutService.saveOrderAsPending(cart: cart);
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.get('order_saved', lang)),
            backgroundColor: AppTheme.success,
          ),
        );
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
  }

  // ═══════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final isMobile = Responsive.isMobile(context);
    final lang = ref.watch(localizationProvider).languageCode;

    return AppShell(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        body: SafeArea(
          child:
              isMobile
                  ? _buildMobileLayout(productsState, cart, cartItemCount, lang)
                  : _buildTabletLayout(productsState, cart, lang),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Mobile Layout — Loyverse style
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(
    dynamic productsState,
    Cart cart,
    int cartItemCount,
    String lang,
  ) {
    return Column(
      children: [
        // ─── Dark AppBar ───
        _buildDarkAppBar(cart, cartItemCount, lang),

        // ─── SAVE / CHARGE Buttons ───
        _buildActionButtons(cart, lang),

        // ─── Category Dropdown + Search ───
        _buildCategorySearchBar(productsState, lang),

        // ─── Product List ───
        Expanded(child: _buildProductList(productsState, lang)),
      ],
    );
  }

  Widget _buildTabletLayout(dynamic productsState, Cart cart, String lang) {
    return Row(
      children: [
        // Left: Product Panel
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildDarkAppBar(cart, ref.watch(cartItemCountProvider), lang),
              _buildCategorySearchBar(productsState, lang),
              Expanded(child: _buildProductList(productsState, lang)),
            ],
          ),
        ),
        // Right: Cart Panel
        Container(width: 1, color: AppTheme.neutral700),
        SizedBox(
          width: 350,
          child: CartPanel(
            cart: cart,
            onUpdateQuantity:
                (id, qty) =>
                    ref.read(cartProvider.notifier).updateQuantity(id, qty),
            onRemoveItem:
                (id) => ref.read(cartProvider.notifier).removeItem(id),
            onClearCart: () => ref.read(cartProvider.notifier).clear(),
            // onApplyLoyalty: _handleApplyLoyalty,
            onCheckout: _handleCheckout,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dark AppBar
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildDarkAppBar(Cart cart, int cartItemCount, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          // Hamburger menu
          IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.neutral800, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),

          // Ticket title + badge
          Text(
            Translations.get('ticket', lang),
            style: const TextStyle(
              color: AppTheme.neutral900,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          if (cartItemCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.neutral400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$cartItemCount',
                style: const TextStyle(
                  color: AppTheme.neutral800,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const Spacer(),

          // More options
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: AppTheme.neutral800,
              size: 22,
            ),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'scan') _openBarcodeScanner();
              if (value == 'clear') {
                ref.read(cartProvider.notifier).clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Translations.get('cart_cleared', lang)),
                    backgroundColor: AppTheme.success,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'scan',
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner, size: 20),
                        const SizedBox(width: 12),
                        Text(Translations.get('scan_barcode', lang)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    enabled: cart.items.isNotEmpty,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color:
                              cart.items.isNotEmpty
                                  ? AppTheme.error
                                  : AppTheme.neutral300,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          Translations.get('clear', lang),
                          style: TextStyle(
                            color:
                                cart.items.isNotEmpty
                                    ? AppTheme.error
                                    : AppTheme.neutral300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SAVE / CHARGE Buttons
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildActionButtons(Cart cart, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppTheme.neutral100,
      child: Row(
        children: [
          // SAVE button
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed:
                    cart.items.isEmpty ? null : () => _handleSaveOrder(cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  disabledBackgroundColor: AppTheme.primaryOrange.withValues(
                    alpha: 0.4,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  Translations.get('save', lang).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // CHARGE button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed:
                    cart.items.isEmpty ? null : () => _showMobileCart(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  disabledBackgroundColor: AppTheme.primaryOrange.withValues(
                    alpha: 0.4,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  '${Translations.get('charge', lang).toUpperCase()}  ${CurrencyFormatter.formatLAKWithSymbol(cart.total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Category Dropdown + Search
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCategorySearchBar(dynamic productsState, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
      ),
      child: Row(
        children: [
          // Swap between dropdown and search field
          Expanded(
            child:
                _isSearchVisible
                    // ── Search TextField ──
                    ? SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _handleSearch,
                        style: const TextStyle(
                          color: AppTheme.neutral900,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: Translations.get(
                            'search_products_or_scan_barcode',
                            lang,
                          ),
                          hintStyle: const TextStyle(
                            color: AppTheme.neutral400,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryOrange,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryOrange,
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.neutral400,
                            size: 20,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 36,
                          ),
                        ),
                      ),
                    )
                    // ── Category Dropdown ──
                    : Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.neutral300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: productsState.selectedCategoryId,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.neutral600,
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            color: AppTheme.neutral900,
                            fontSize: 14,
                          ),
                          hint: Text(
                            Translations.get('all_items', lang),
                            style: const TextStyle(
                              color: AppTheme.neutral600,
                              fontSize: 14,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(Translations.get('all_items', lang)),
                            ),
                            ...productsState.categories
                                .map<DropdownMenuItem<String?>>((cat) {
                                  return DropdownMenuItem<String?>(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  );
                                }),
                          ],
                          onChanged: (value) {
                            ref
                                .read(productsProvider.notifier)
                                .selectCategory(value);
                          },
                        ),
                      ),
                    ),
          ),
          const SizedBox(width: 8),

          // Search toggle button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  _isSearchVisible
                      ? AppTheme.primaryOrange
                      : AppTheme.neutral100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    _isSearchVisible
                        ? AppTheme.primaryOrange
                        : AppTheme.neutral300,
              ),
            ),
            child: IconButton(
              icon: Icon(
                _isSearchVisible ? Icons.close : Icons.search,
                color: _isSearchVisible ? Colors.white : AppTheme.neutral600,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchController.clear();
                    _handleSearch('');
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Product List
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildProductList(dynamic productsState, String lang) {
    if (productsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (productsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              productsState.error!,
              style: const TextStyle(color: AppTheme.neutral600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(productsProvider.notifier).refresh(),
              child: Text(Translations.get('retry', lang)),
            ),
          ],
        ),
      );
    }

    final products = productsState.filteredProducts as List<Product>;

    if (products.isEmpty) {
      return Center(
        child: Text(
          Translations.get('no_products_found', lang),
          style: const TextStyle(color: AppTheme.neutral400, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsProvider.notifier).refresh(),
      child: ListView.separated(
        itemCount: products.length,
        separatorBuilder:
            (_, __) => const Divider(height: 1, color: AppTheme.neutral200),
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductItem(product);
        },
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final hasImage =
        product.images.isNotEmpty && product.images.first.url.isNotEmpty;
    final price = product.pricing.basePrice;

    final colorIndex = product.name.hashCode % _itemColors.length;
    final circleColor = _itemColors[colorIndex.abs()];

    return InkWell(
      onTap: () => _addToCart(product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.white,
        child: Row(
          children: [
            // Product image or colored shape
            hasImage
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    product.images.first.url,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                            _buildColorCircle(product.name, circleColor),
                  ),
                )
                : _buildColorCircle(product.name, circleColor),
            const SizedBox(width: 16),

            // Product name
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  color: AppTheme.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Price
            Text(
              price > 0 ? CurrencyFormatter.formatLAKWithSymbol(price) : '–',
              style: const TextStyle(color: AppTheme.neutral600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(String name, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Mobile Cart Modal
  // ═══════════════════════════════════════════════════════════════════

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
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final cart = ref.watch(cartProvider);
                          return CartPanel(
                            cart: cart,
                            onUpdateQuantity:
                                (id, qty) => ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(id, qty),
                            onRemoveItem:
                                (id) => ref
                                    .read(cartProvider.notifier)
                                    .removeItem(id),
                            onClearCart:
                                () => ref.read(cartProvider.notifier).clear(),
                            // onApplyLoyalty: _handleApplyLoyalty,
                            onCheckout: () {
                              Navigator.pop(context);
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

  // Colors for product circles (Loyverse style)
  static const _itemColors = [
    Color(0xFFFF6B00), // orange
    Color(0xFFE4B800), // yellow
    Color(0xFFE53935), // red
    Color(0xFF7B1FA2), // purple
    Color(0xFF1E88E5), // blue
    Color(0xFF43A047), // green
    Color(0xFF00897B), // teal
    Color(0xFF6D4C41), // brown
    Color(0xFF546E7A), // blue-grey
    Color(0xFFC2185B), // pink
  ];
}
