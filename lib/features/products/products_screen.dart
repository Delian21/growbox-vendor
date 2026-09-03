import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/growbox_empty_state.dart';
import '../../shared/utils/snackbar_helper.dart';
import '../../app/providers/products_provider.dart';
import 'product_catalog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = true;
  String _selectedFilter = 'All';
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    // Rebuild as the user types so the search filter updates live.
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Live view of the catalog (via ProductsProvider) filtered by the current
  // search text and category. Recomputes on every build, so edits/deletes
  // made anywhere are reflected automatically.
  List<ProductItem> _visibleProducts(ProductsProvider provider) {
    final query = _searchController.text.toLowerCase().trim();
    return provider.products.where((product) {
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      final matchesCategory = _selectedFilter == 'All' ||
          product.category == _selectedFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: AppDimensions.lg),
            _buildSearchBar(context, isDark),
            const SizedBox(height: AppDimensions.lg),
            _buildFilterChips(isDark),
            const SizedBox(height: AppDimensions.lg),
            _buildProductsSection(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Products', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('42 products listed', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
          child: Row(
            children: [
              _viewToggle(Icons.grid_view_rounded, _isGridView, isDark, () => setState(() => _isGridView = true)),
              _viewToggle(Icons.view_list_rounded, !_isGridView, isDark, () => setState(() => _isGridView = false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _viewToggle(IconData icon, bool isActive, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        child: Icon(icon, size: 18, color: isActive ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return GrowboxCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.sm),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final provider = context.watch<ProductsProvider>();
    final visibleCount = _visibleProducts(provider).length;
    final totalCount = provider.products.length;
    final filters = [
      'All',
      'Vegetables',
      'Fruits',
      'Grains & Cereals',
      'Legumes & Pulses',
      'Tuber & Roots',
      'Oils',
      'Fresh Proteins',
      'Mushrooms',
      'Herbs & Spices',
      'Nut & Seeds',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
            itemBuilder: (context, index) {
              final isSelected = _selectedFilter == filters[index];
              return FilterChip(
                label: Text(filters[index]),
                selected: isSelected,
                onSelected: (_) => _onFilterChanged(filters[index]),
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
            backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          '$visibleCount of $totalCount products',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context, bool isDark) {
    final provider = context.watch<ProductsProvider>();
    final visible = _visibleProducts(provider);

    // Show empty state if no results
    if (visible.isEmpty) {
      return GrowboxCard(
        child: GrowboxEmptyState(
          icon: Icons.search_off_outlined,
          title: 'No products found',
          subtitle: 'Try adjusting your search or filters',
        ),
      );
    }

    if (_isGridView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
          return AnimationLimiter(
            child: GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols, crossAxisSpacing: AppDimensions.lg, mainAxisSpacing: AppDimensions.lg,
                childAspectRatio: cols >= 4 ? 0.85 : (cols == 3 ? 0.7 : 0.65),
              ),
              itemCount: visible.length,
              itemBuilder: (context, i) => AnimationConfiguration.staggeredGrid(
                position: i,
                columnCount: cols,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 30.0,
                  child: FadeInAnimation(
                    child: _buildGridCard(context, visible[i], isDark, i),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: visible.asMap().entries.map((entry) => _buildListCard(context, entry.value, isDark, entry.key)).toList(),
        ),
      ),
    );
  }

  // Renders the product photo with the original gradient + icon layered
  // underneath, so the fallback shows while loading or if the network image
  // fails to load.
  Widget _buildProductImage({
    required String? imageUrl,
    required List<Color> gradientColors,
    required IconData icon,
    required bool isDark,
    required double iconSize,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: gradientColors.length >= 2
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors[0].withValues(alpha: 0.8),
                  gradientColors[1].withValues(alpha: 0.9),
                ],
              )
            : null,
        color: gradientColors.isEmpty
            ? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(icon, size: iconSize, color: Colors.white.withValues(alpha: 0.9)),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, ProductItem p, bool isDark, int index) {
    final isTapped = _tappedIndex == index;
    return GestureDetector(
      onTap: () => context.go('/products/${p.id}'),
      onTapDown: (_) => setState(() => _tappedIndex = index),
      onTapUp: (_) => setState(() => _tappedIndex = null),
      onTapCancel: () => setState(() => _tappedIndex = null),
      child: AnimatedScale(
        scale: isTapped ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: GrowboxCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildProductImage(imageUrl: p.imageUrl, gradientColors: p.gradientColors, icon: p.icon, isDark: isDark, iconSize: 48, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)))),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.md, AppDimensions.sm, AppDimensions.md, AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(p.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  _buildActionsMenu(context, p, isDark),
                ]),
                const SizedBox(height: 2),
                Text(p.category, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)),
                const Spacer(),
                Row(children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text('\u20A6${p.price}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  Text('/${p.unit}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)),
                  const Spacer(),
                  Text('${p.stock} in stock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: p.stock > 10 ? AppColors.success : AppColors.error)),
                ]),
              ],
            ),
          )),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildListCard(BuildContext context, ProductItem p, bool isDark, int index) {
    final isTapped = _tappedIndex == index;
    return GestureDetector(
      onTap: () => context.go('/products/${p.id}'),
      onTapDown: (_) => setState(() => _tappedIndex = index),
      onTapUp: (_) => setState(() => _tappedIndex = null),
      onTapCancel: () => setState(() => _tappedIndex = null),
      child: AnimatedScale(
        scale: isTapped ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.md),
          child: GrowboxCard(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              children: [
                SizedBox(width: 64, height: 64, child: _buildProductImage(imageUrl: p.imageUrl, gradientColors: p.gradientColors, icon: p.icon, isDark: isDark, iconSize: 28, borderRadius: BorderRadius.circular(AppDimensions.radiusMd))),
                const SizedBox(width: AppDimensions.lg),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary))), _buildActionsMenu(context, p, isDark)]),
                  const SizedBox(height: 4),
                  Text(p.category, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ])),
                const SizedBox(width: AppDimensions.lg),
                Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text('\u20A6${p.price}/${p.unit}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  const SizedBox(height: 4),
                  Text('${p.stock} in stock', style: TextStyle(fontSize: 12, color: p.stock > 10 ? AppColors.success : AppColors.error)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions menu (Edit / Delete) ──
  Widget _buildActionsMenu(BuildContext context, ProductItem p, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
      ),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditProductSheet(context, p);
        } else if (value == 'delete') {
          _deleteProduct(context, p);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Edit Product'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('Delete Product', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _editProduct(BuildContext context, ProductItem updated) {
    context.read<ProductsProvider>().updateProduct(updated);
    SnackbarHelper.showSuccess(context, 'Product updated successfully!');
  }

  void _deleteProduct(BuildContext context, ProductItem p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${p.name}"?\n\nThis action cannot be undone.',
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
      context.read<ProductsProvider>().deleteProduct(p.id);
      SnackbarHelper.showSuccess(context, '"${p.name}" deleted');
    }
  }

  void _showEditProductSheet(BuildContext context, ProductItem product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductEditSheet(
        product: product,
        onSave: (updated) => _editProduct(context, updated),
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddProductSheet());
  }
}

class _AddProductSheet extends StatefulWidget {
  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  static const _allCategories = [
    'Vegetables',
    'Fruits',
    'Grains & Cereals',
    'Legumes & Pulses',
    'Tuber & Roots',
    'Oils',
    'Fresh Proteins',
    'Mushrooms',
    'Herbs & Spices',
    'Nut & Seeds',
  ];
  final _nameController = TextEditingController();
  final Set<String> _selectedCategories = {};
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.darkBorder : AppColors.border, borderRadius: BorderRadius.circular(AppDimensions.radiusFull))),
        Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Row(children: [
          Text('Add New Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
        ])),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Form(
            key: _formKey,
            child: Column(children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 2),
                    image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                  ),
                  child: _selectedImage == null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, size: 32, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary), const SizedBox(height: 8), Text('Tap to upload product image', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary))])
                      : Align(alignment: Alignment.bottomRight, child: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit, size: 16, color: Colors.white))),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              _field('Product Name', 'e.g. Fresh Tomatoes', isDark, controller: _nameController, validator: (v) => v == null || v.isEmpty ? 'Enter product name' : null),
              const SizedBox(height: AppDimensions.lg),
              _buildCategoryPicker(isDark),
              const SizedBox(height: AppDimensions.lg),
              Row(children: [Expanded(child: _field('Price (\u20A6)', '0.00', isDark, controller: _priceController, keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Enter price' : null)), const SizedBox(width: AppDimensions.md), Expanded(child: _field('Unit', 'e.g. kg', isDark, controller: _unitController, validator: (v) => v == null || v.isEmpty ? 'Enter unit' : null))]),
              const SizedBox(height: AppDimensions.lg),
              _field('Stock Quantity', '0', isDark, controller: _stockController, keyboardType: TextInputType.number, validator: (v) {
                if (v == null || v.isEmpty) return 'Enter stock quantity';
                if (int.tryParse(v) == null) return 'Enter valid number';
                return null;
              }),
              const SizedBox(height: AppDimensions.lg),
              _field('Description', 'Describe your product...', isDark, maxLines: 3, controller: _descriptionController),
              const SizedBox(height: AppDimensions.xl),
              GrowboxButton(
                label: 'Add Product',
                onPressed: () {
                  final valid = _formKey.currentState!.validate();
                  final catsValid = _selectedCategories.isNotEmpty;
                  if (!catsValid) {
                    setState(() => _showCategoryError = true);
                  }
                  if (valid && catsValid) {
                    final cats = _selectedCategories.join(', ');
                    Navigator.pop(context);
                    SnackbarHelper.showSuccess(context, 'Product added successfully! ($cats)');
                  }
                },
                isExpanded: true,
                icon: Icons.add,
              ),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _field(String label, String hint, bool isDark, {int maxLines = 1, TextEditingController? controller, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(hintText: hint),
      ),
    ]);
  }

  bool _showCategoryError = false;

  Widget _buildCategoryPicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
          const SizedBox(width: 4),
          Text('*', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.error)),
        ]),
        const SizedBox(height: 6),
        if (_showCategoryError && _selectedCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Select at least one category', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error)),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCategories.map((cat) {
            final selected = _selectedCategories.contains(cat);
            return FilterChip(
              label: Text(cat, style: TextStyle(fontSize: 13, color: selected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary))),
              selected: selected,
              selectedColor: AppColors.primary,
              backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: _showCategoryError && _selectedCategories.isEmpty
                    ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
                    : selected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
              ),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedCategories.add(cat);
                    _showCategoryError = false;
                  } else {
                    _selectedCategories.remove(cat);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════
// ── EDIT PRODUCT SHEET ──
// ══════════════════════════════════════════
class ProductEditSheet extends StatefulWidget {
  final ProductItem product;
  final void Function(ProductItem) onSave;

  const ProductEditSheet({super.key, required this.product, required this.onSave});

  @override
  State<ProductEditSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<ProductEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;
  final _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _categoryController = TextEditingController(text: p.category);
    _priceController = TextEditingController(text: p.price);
    _unitController = TextEditingController(text: p.unit);
    _stockController = TextEditingController(text: p.stock.toString());
    _descriptionController = TextEditingController(text: p.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              children: [
                Text(
                  'Edit Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 2),
                          image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                        ),
                        child: _selectedImage == null
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, size: 32, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary), const SizedBox(height: 8), Text('Tap to change product image', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary))])
                            : Align(alignment: Alignment.bottomRight, child: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit, size: 16, color: Colors.white))),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xl),
                    _field('Product Name', 'e.g. Fresh Tomatoes', isDark, controller: _nameController, validator: (v) => v == null || v.isEmpty ? 'Enter product name' : null),
                    const SizedBox(height: AppDimensions.lg),
                    _field('Category', 'e.g. Vegetables', isDark, controller: _categoryController, validator: (v) => v == null || v.isEmpty ? 'Enter category' : null),
                    const SizedBox(height: AppDimensions.lg),
                    Row(
                      children: [
                        Expanded(child: _field('Price (\u20A6)', '0.00', isDark, controller: _priceController, keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Enter price' : null)),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(child: _field('Unit', 'e.g. kg', isDark, controller: _unitController, validator: (v) => v == null || v.isEmpty ? 'Enter unit' : null)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _field('Stock Quantity', '0', isDark, controller: _stockController, keyboardType: TextInputType.number, validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter stock quantity';
                      if (int.tryParse(v) == null) return 'Enter valid number';
                      return null;
                    }),
                    const SizedBox(height: AppDimensions.lg),
                    _field('Description', 'Describe your product...', isDark, maxLines: 3, controller: _descriptionController),
                    const SizedBox(height: AppDimensions.xl),
                    GrowboxButton(
                      label: 'Save Changes',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSave(ProductItem(
                            id: widget.product.id,
                            name: _nameController.text.trim(),
                            category: _categoryController.text.trim(),
                            price: _priceController.text.trim(),
                            unit: _unitController.text.trim(),
                            stock: int.tryParse(_stockController.text.trim()) ?? 0,
                            icon: widget.product.icon,
                            gradientColors: widget.product.gradientColors,
                            imageUrl: widget.product.imageUrl,
                            description: _descriptionController.text.trim(),
                          ));
                          Navigator.pop(context);
                        }
                      },
                      isExpanded: true,
                      icon: Icons.check,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String hint, bool isDark, {int maxLines = 1, TextEditingController? controller, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}