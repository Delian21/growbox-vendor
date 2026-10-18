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
}

/// The compact action button shared by the Dashboard's Recent Orders table
/// and the Orders table's desktop rows, so both pages show the IDENTICAL
/// button: 10×5 padding, 12/w600 label, radiusMd — solid green for Accept,
/// outlined red for Reject. Deliberately smaller than [GrowboxButton],
/// which is sized for card-level actions (24×14 padding); in-table actions
/// must sit on one line with the row they belong to.
class GrowboxTableAction extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isSolid = variant == GrowboxTableActionVariant.solid;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSolid ? AppColors.primary : Colors.transparent,
          border: isSolid ? null : Border.all(color: AppColors.error, width: 1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSolid ? Colors.white : AppColors.error,
          ),
        ),
      ),
    );
  }
}
