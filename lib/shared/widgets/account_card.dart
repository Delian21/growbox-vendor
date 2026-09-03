import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A structured account/menu card with icon, label, and chevron.
/// Matches the dark menu-item style: green icon square, text, arrow.
class AccountCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBgColor;

  const AccountCard({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Green icon square
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor ?? AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? Colors.white,
                ),
              ),
              const SizedBox(width: 14),

              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),

              // Chevron arrow
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
