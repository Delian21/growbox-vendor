import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../app/providers/store_provider.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/growbox_badge.dart';
import '../../shared/utils/snackbar_helper.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: AppDimensions.xl),
          _buildStoreBanner(context, isDark),
          const SizedBox(height: AppDimensions.xl),
          _buildStoreInfo(context, isDark),
          const SizedBox(height: AppDimensions.xl),
          _buildContactDetails(context, isDark),
          const SizedBox(height: AppDimensions.xl),
          _buildStoreStatus(context, isDark),
        ],
      ),
    );
  }

  // ── STORE PHOTOS ──
  // Renders a store photo from whatever source its value points to: a bundled
  // asset, or a base64 data-URL picked through the Edit Store sheet (data
  // URLs keep photo picks working on web and desktop alike).
  Widget _storePhoto(String value, {required BoxFit fit}) {
    if (value.startsWith('data:image')) {
      final parts = value.split(',');
      if (parts.length < 2) return const SizedBox.shrink();
      try {
        return Image.memory(
          base64Decode(parts[1]),
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return Image.asset(
      value,
      fit: fit,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  // Tap-to-pick a store photo and return it as a data-URL string (or null if
  // the user cancels).
  Future<String?> _pickStorePhoto(BuildContext context) async {
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
    if (source == null) return null;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // Label + tappable preview box used by the Edit Store sheet.
  Widget _photoPicker(
    BuildContext context, {
    required String label,
    required String value,
    required Future<void> Function() onTap,
    double height = 120,
    String emptyHint = 'Tap to add a photo',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: value.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 26,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emptyHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _storePhoto(value, fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera_outlined, size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Change', style: TextStyle(fontSize: 11, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Store',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _showEditStoreSheet(context),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit Store'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  // ── STORE BANNER + LOGO ──
  Widget _buildStoreBanner(BuildContext context, bool isDark) {
    final store = context.watch<StoreProvider>().store;

    return GrowboxCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + overlapping logo
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner
              Container(
                height: 140,
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Icon(
                        Icons.landscape,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    if (store.bannerUrl.isNotEmpty)
                      Positioned.fill(
                        child: _storePhoto(store.bannerUrl, fit: BoxFit.cover),
                      ),
                  ],
                ),
              ),
              // Logo overlapping banner bottom
              Positioned(
                left: AppDimensions.lg,
                bottom: -32,
                child: Container(
                  width: 64,
                  height: 64,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Center(
                        child: Icon(Icons.store, size: 30, color: AppColors.primary),
                      ),
                      if (store.logoUrl.isNotEmpty)
                        _storePhoto(store.logoUrl, fit: BoxFit.cover),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Name + Status (with top padding to accommodate logo)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.lg, 44, AppDimensions.lg, AppDimensions.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 64 + AppDimensions.md), // space for logo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        store.businessCategory,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GrowboxBadge(
                  label: store.isOpen ? 'Open' : 'Closed',
                  backgroundColor: store.isOpen ? AppColors.successLight : AppColors.errorLight,
                  textColor: store.isOpen ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STORE INFO ──
  Widget _buildStoreInfo(BuildContext context, bool isDark) {
    final store = context.watch<StoreProvider>().store;

    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Store Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _infoRow('Description', store.description, isDark),
          const SizedBox(height: AppDimensions.md),
          _infoRow('Category', store.businessCategory, isDark),
          const SizedBox(height: AppDimensions.md),
          _infoRow('Location', store.location, isDark),
          const SizedBox(height: AppDimensions.md),
          _buildOpeningHours(context, isDark, store),
        ],
      ),
    );
  }

  // ── OPENING HOURS ──
  Widget _buildOpeningHours(BuildContext context, bool isDark, store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening Hours',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.access_time_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '${store.openTime} – ${store.closeTime}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
            final isOperating = store.operatingDays.contains(day);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOperating
                    ? AppColors.primarySurface
                    : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(
                  color: isOperating
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                ),
              ),
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isOperating
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── CONTACT DETAILS ──
  Widget _buildContactDetails(BuildContext context, bool isDark) {
    final store = context.watch<StoreProvider>().store;

    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _contactRow(Icons.phone_outlined, 'Phone', store.phone, isDark),
          const SizedBox(height: AppDimensions.md),
          _contactRow(Icons.email_outlined, 'Email', store.email, isDark),
          const SizedBox(height: AppDimensions.md),
          _contactRow(Icons.location_on_outlined, 'Address', store.location, isDark),
        ],
      ),
    );
  }

  // ── STORE STATUS TOGGLE ──
  Widget _buildStoreStatus(BuildContext context, bool isDark) {
    final storeProvider = context.watch<StoreProvider>();
    final store = storeProvider.store;

    return GrowboxCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: store.isOpen ? AppColors.successLight : AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              store.isOpen ? Icons.store_outlined : Icons.storefront_outlined,
              size: 22,
              color: store.isOpen ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.isOpen ? 'Store is Open' : 'Store is Closed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  store.isOpen
                      ? 'Customers can see and order from your store'
                      : 'Your store is hidden from customers',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: store.isOpen,
            onChanged: (_) => storeProvider.toggleStoreStatus(),
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS ──
  Widget _infoRow(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppDimensions.sm),
        Column(
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
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── EDIT STORE BOTTOM SHEET ──
  void _showEditStoreSheet(BuildContext context) {
    final storeProvider = context.read<StoreProvider>();
    final store = storeProvider.store;
    final nameController = TextEditingController(text: store.name);
    final descController = TextEditingController(text: store.description);
    final phoneController = TextEditingController(text: store.phone);
    final emailController = TextEditingController(text: store.email);
    final locationController = TextEditingController(text: store.location);
    final formKey = GlobalKey<FormState>();
    // Photos picked in this sheet (data URLs). Null keeps the current image.
    String? pickedBanner;
    String? pickedLogo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: AppDimensions.xl,
              right: AppDimensions.xl,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.xl,
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(top: AppDimensions.lg),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Store',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      _photoPicker(
                        ctx,
                        label: 'Banner Photo',
                        value: pickedBanner ?? store.bannerUrl,
                        height: 120,
                        emptyHint: 'Tap to add a banner photo',
                        onTap: () async {
                          final data = await _pickStorePhoto(ctx);
                          if (data != null) setSheetState(() => pickedBanner = data);
                        },
                      ),
                      const SizedBox(height: AppDimensions.md),
                      _photoPicker(
                        ctx,
                        label: 'Store Logo',
                        value: pickedLogo ?? store.logoUrl,
                        height: 96,
                        emptyHint: 'Tap to add a logo photo',
                        onTap: () async {
                          final data = await _pickStorePhoto(ctx);
                          if (data != null) setSheetState(() => pickedLogo = data);
                        },
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      _buildValidatedField('Store Name', nameController, validator: (v) => v == null || v.isEmpty ? 'Enter store name' : null),
                      const SizedBox(height: AppDimensions.md),
                      _buildValidatedField('Description', descController, maxLines: 3, validator: (v) => v == null || v.isEmpty ? 'Enter description' : null),
                      const SizedBox(height: AppDimensions.md),
                      _buildValidatedField('Phone', phoneController, keyboardType: TextInputType.phone, validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null),
                      const SizedBox(height: AppDimensions.md),
                      _buildValidatedField('Email', emailController, keyboardType: TextInputType.emailAddress, validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        if (!v.contains('@')) return 'Enter valid email';
                        return null;
                      }),
                      const SizedBox(height: AppDimensions.md),
                      _buildValidatedField('Location', locationController, validator: (v) => v == null || v.isEmpty ? 'Enter location' : null),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        storeProvider.updateStore(
                          name: nameController.text,
                          description: descController.text,
                          phone: phoneController.text,
                          email: emailController.text,
                          location: locationController.text,
                          logoUrl: pickedLogo ?? store.logoUrl,
                          bannerUrl: pickedBanner ?? store.bannerUrl,
                        );
                        Navigator.pop(ctx);
                        SnackbarHelper.showSuccess(context, 'Store updated successfully!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}