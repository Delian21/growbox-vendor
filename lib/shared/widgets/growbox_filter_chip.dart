import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// The app's single filter chip (Products, Orders, Sales).
///
/// One size, one selected style and one unselected treatment everywhere:
///  * selected   → primary fill, white label + white checkmark, no border;
///  * unselected → surface-variant fill with a visible 1px border
///                 (`border` in light, `darkBorder` in dark) so chips never
///                 blend into the off-white light background;
///  * [count]    → appended to the label as "Pending (3)" (Orders tabs);
///  * [avatar]   → optional leading dot (Products category colours);
///  * [borderColor] → replaces the default unselected border where a page
///                   needs one (the add-product sheet's validation error).
class GrowboxFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final int? count;
  final Widget? avatar;
  final Color? borderColor;

  const GrowboxFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
    this.avatar,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      avatar: avatar,
      label: Text(count == null ? label : '$label ($count)'),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: selected
            ? Colors.white
            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
      ),
      backgroundColor:
          isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : (borderColor ??
                (isDark ? AppColors.darkBorder : AppColors.border)),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
