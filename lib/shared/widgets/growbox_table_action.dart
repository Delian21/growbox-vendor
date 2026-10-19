import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Visual treatment for a compact in-table action.
enum GrowboxTableActionVariant {
  /// Solid emerald fill — the primary row action (Accept).
  solid,

  /// Transparent fill with a 1px error border — the ghost alternative
  /// (Reject), so destructive actions weigh less than the primary one.
  outline,

  /// Quiet theme border with a secondary label — a non-destructive action
  /// on a read-only table (the Sales transaction "View"), which must
  /// neither borrow the destructive red nor claim the emerald decision
  /// signal. Hover turns it primary-tinted so it still reads as clickable.
  neutral,
}

/// The compact action button shared by the Dashboard's Recent Orders table,
/// the Orders table's desktop rows and the Sales transactions table, so
/// every page shows the IDENTICAL button: 10×5 padding, 12/w600 label,
/// radiusMd — solid green for Accept, outlined red for Reject, neutral for
/// View. Deliberately smaller than [GrowboxButton], which is sized for
/// card-level actions (24×14 padding); in-table actions must sit on one
/// line with the row they belong to.
///
/// Hover is theme-aware and the cursor switches to a pointer, so rows read
/// as clickable on desktop in BOTH themes: light deepens the fill for
/// depth, dark washes the shared surface tint over it (a flat emerald on a
/// dark card barely moves). Without a pointer over it, the rendering is
/// exactly the old stateless button.
class GrowboxTableAction extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final GrowboxTableActionVariant variant;

  const GrowboxTableAction({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = GrowboxTableActionVariant.solid,
  });

  @override
  State<GrowboxTableAction> createState() => _GrowboxTableActionState();
}

class _GrowboxTableActionState extends State<GrowboxTableAction> {
  /// True while the pointer is over the button — drives the hover fill.
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resting colours are identical to the old stateless build — only the
    // hover state reads the theme.
    final (:background, :border, :label) = switch (widget.variant) {
      GrowboxTableActionVariant.solid => (
          background: _hovered
              ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
              : AppColors.primary,
          border: null,
          label: Colors.white,
        ),
      GrowboxTableActionVariant.outline => (
          // A tint, never a saturated red fill — that would outweigh the
          // Accept button sitting beside it.
          background: _hovered
              ? (isDark
                  ? AppColors.error.withValues(alpha: 0.16)
                  : AppColors.errorLight)
              : Colors.transparent,
          border: AppColors.error,
          label: AppColors.error,
        ),
      GrowboxTableActionVariant.neutral => (
          background: _hovered
              ? (isDark
                  ? AppColors.darkPrimarySurface
                  : AppColors.primarySurface)
              : Colors.transparent,
          border: _hovered
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isDark ? AppColors.darkBorder : AppColors.secondaryBorder),
          label: _hovered
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary),
        ),
    };

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            border:
                border == null ? null : Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: label,
            ),
          ),
        ),
      ),
    );
  }
}
