import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// The shared page-header pattern: an optional title above a one-line
/// subtitle, with an optional trailing action slot.
///
/// Pages must NOT pass the [title] the top bar already shows — the top bar
/// names every route ("Products", "Orders", "Sales", "Dashboard"), so pages
/// pass `subtitle` only. A distinct heading can still be passed as [title]
/// where one is genuinely wanted.
///
/// Typography matches the pattern the Orders page established:
/// 24 / w700 / primary-text title, 4px gap, 14 / secondary one-line
/// subtitle (ellipsized so it can never wrap).
class GrowboxPageHeader extends StatelessWidget {
  const GrowboxPageHeader({
    super.key,
    this.title,
    required this.subtitle,
    this.trailing,
  });

  /// Omit when the top bar already shows the page name (the usual case).
  final String? title;

  /// One-line supporting line: counts, status lines, descriptions.
  final String subtitle;

  /// Right-aligned actions (buttons, toggles, badges).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppDimensions.lg),
          trailing!,
        ],
      ],
    );
  }
}
