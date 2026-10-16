import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class GrowboxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hasBorder;

  /// Explicit border color/width. When set, the card gets this border in
  /// BOTH themes (only the color differs) — same structure everywhere.
  /// Unset keeps the legacy rule (always bordered in light, opt-in in dark).
  final Color? borderColor;
  final double borderWidth;
  final bool hasShadow;
  final Color? backgroundColor;
  final Clip clipBehavior;

  const GrowboxCard({
    super.key,
    required this.child,
    this.padding,
    this.hasBorder = false,
    this.borderColor,
    this.borderWidth = 0.5,
    this.hasShadow = true,
    this.backgroundColor,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = backgroundColor ?? (isDark ? AppColors.darkSurface : AppColors.secondarySurface);

    return ClipRRect(
      clipBehavior: clipBehavior,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : hasBorder || !isDark
                ? Border.all(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.4)
                        : AppColors.borderLight,
                    width: 0.5,
                  )
                : null,
        boxShadow: hasShadow
            ? [
                // Soft, diffused shadow — Nordic feel
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isDark ? 20 : 16,
                  offset: const Offset(0, 2),
                  spreadRadius: isDark ? 0 : 1,
                ),
                // Subtle color bleed in dark mode
                if (isDark)
                  BoxShadow(
                    color: AppColors.darkPrimary.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 0),
                    spreadRadius: -4,
                  ),
              ]
            : null,
      ),
      child: child,
    ),
    );
  }
}