import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/theme.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/currency_formatter.dart';

/// Product grid for POS display
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.neutral300,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.neutral500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine cross axis count based on screen width
        final width = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        if (width < 600) {
          // Mobile: 3 columns
          crossAxisCount = 3;
          childAspectRatio = 0.68; // Slightly taller for 3 columns
        } else if (width < 900) {
          // Tablet: 4 columns
          crossAxisCount = 4;
          childAspectRatio = 0.75;
        } else {
          // Desktop: 5 columns
          crossAxisCount = 5;
          childAspectRatio = 0.8;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              onTap: () => onProductTap(product),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = !product.isInStock;
    final isLowStock = product.isLowStock;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isOutOfStock
                      ? AppTheme.error.withValues(alpha: 0.3)
                      : AppTheme.neutral200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      child:
                          product.primaryImageUrl != null
                              ? CachedNetworkImage(
                                imageUrl: product.primaryImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder:
                                    (context, url) => Container(
                                      color: AppTheme.neutral100,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) =>
                                        _buildPlaceholder(),
                              )
                              : _buildPlaceholder(),
                    ),

                    // Out of stock overlay
                    if (isOutOfStock)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),

                    // Low stock badge
                    if (isLowStock && !isOutOfStock)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Low: ${product.inventory?.currentStock}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color:
                            isOutOfStock
                                ? AppTheme.neutral400
                                : AppTheme.neutral900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Price
                    Text(
                      CurrencyFormatter.formatLAKWithSymbol(
                        product.pricing.basePrice,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color:
                            isOutOfStock
                                ? AppTheme.neutral400
                                : AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.neutral100,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: AppTheme.neutral300),
      ),
    );
  }
}
