import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_badge.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/utils/snackbar_helper.dart';
import '../../app/providers/products_provider.dart';
import 'product_catalog.dart';
import 'products_screen.dart' show ProductEditSheet;

class ProductDetailsScreen extends StatelessWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    // ProductsProvider forwards catalog changes, so this page rebuilds
    // automatically when the product is edited or deleted from anywhere.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = context.watch<ProductsProvider>().getProductById(productId);

    if (product == null) {
      return _buildNotFound(context, isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, product),
          const SizedBox(height: AppDimensions.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return _buildDesktopLayout(context, isDark, product);
              }
              return _buildMobileLayout(context, isDark, product);
            },
          ),
        ],
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context, bool isDark, ProductItem product) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          onPressed: () => context.go('/products'),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  _availabilityBadge(product),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                product.category,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── LAYOUTS ──
  Widget _buildDesktopLayout(BuildContext context, bool isDark, ProductItem product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: photo (large) + description
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoCard(context, isDark, product),
              const SizedBox(height: AppDimensions.lg),
              _buildDescriptionCard(context, isDark, product),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.xl),
        // Right: pricing + details
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildPriceCard(context, isDark, product),
              const SizedBox(height: AppDimensions.lg),
              _buildDetailsCard(context, isDark, product),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark, ProductItem product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoCard(context, isDark, product),
        const SizedBox(height: AppDimensions.lg),
        _buildPriceCard(context, isDark, product),
        const SizedBox(height: AppDimensions.lg),
        _buildDetailsCard(context, isDark, product),
        const SizedBox(height: AppDimensions.lg),
        _buildDescriptionCard(context, isDark, product),
      ],
    );
  }

  // ── LARGE PRODUCT PHOTO ──
  Widget _buildPhotoCard(BuildContext context, bool isDark, ProductItem product) {
    final hasGradient = product.gradientColors.length >= 2;
    return GrowboxCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: hasGradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      product.gradientColors[0].withValues(alpha: 0.8),
                      product.gradientColors[1].withValues(alpha: 0.9),
                    ],
                  )
                : null,
            color: hasGradient
                ? null
                : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(
                  product.icon,
                  size: 96,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                Image.asset(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PRICE / CTA CARD ──
  Widget _buildPriceCard(BuildContext context, bool isDark, ProductItem product) {
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\u20A6${product.price}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/${product.unit}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          SizedBox(
            width: double.infinity,
            child: GrowboxButton(
              label: 'Edit Product',
              onPressed: () => _showEditSheet(context, product),
              isExpanded: true,
              icon: Icons.edit_outlined,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, product),
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              label: const Text('Delete Product', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── EDIT / DELETE ──
  void _showEditSheet(BuildContext context, ProductItem product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductEditSheet(
        product: product,
        onSave: (updated) {
          context.read<ProductsProvider>().updateProduct(updated);
          if (context.mounted) {
            SnackbarHelper.showSuccess(context, 'Product updated successfully!');
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductItem product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ProductsProvider>().deleteProduct(product.id);
      SnackbarHelper.showSuccess(context, '"${product.name}" deleted');
      context.go('/products');
    }
  }

  // ── PRODUCT INFO ROWS ──
  Widget _buildDetailsCard(BuildContext context, bool isDark, ProductItem product) {
    final lowStock = product.isLowStock && product.stock > 0;
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _infoRow(context, Icons.category_outlined, 'Category', product.category, isDark),
          const SizedBox(height: AppDimensions.md),
          _infoRow(context, Icons.straighten_outlined, 'Sold by', product.unit, isDark),
          const SizedBox(height: AppDimensions.md),
          _infoRow(context, Icons.inventory_2_outlined, 'Stock', '${product.stock} ${product.unit}', isDark),
          if (product.stock > 0) ...[
            const SizedBox(height: AppDimensions.md),
            _infoRow(
              context,
              Icons.verified_outlined,
              'Status',
              lowStock ? 'Low stock — reorder soon' : 'Available',
              isDark,
              valueColor: lowStock ? AppColors.warning : AppColors.success,
            ),
          ],
          if (lowStock) ...[
            const SizedBox(height: AppDimensions.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'Only ${product.stock} left in stock',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── DESCRIPTION ──
  Widget _buildDescriptionCard(BuildContext context, bool isDark, ProductItem product) {
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            product.description.isEmpty
                ? 'No description provided for this product yet.'
                : product.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ??
                      (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _availabilityBadge(ProductItem product) {
    if (product.stock <= 0) {
      return const GrowboxBadge(
        label: 'Out of Stock',
        backgroundColor: AppColors.errorLight,
        textColor: AppColors.error,
        isSmall: true,
      );
    }
    if (product.isLowStock) {
      return const GrowboxBadge(
        label: 'Low Stock',
        backgroundColor: AppColors.warningLight,
        textColor: AppColors.warning,
        isSmall: true,
      );
    }
    return const GrowboxBadge(
      label: 'Available',
      backgroundColor: AppColors.successLight,
      textColor: AppColors.success,
      isSmall: true,
    );
  }

  // ── NOT FOUND ──
  Widget _buildNotFound(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            'Product not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          GrowboxButton(
            label: 'Back to Products',
            onPressed: () => context.go('/products'),
          ),
        ],
      ),
    );
  }
}
