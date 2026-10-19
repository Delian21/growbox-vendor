import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// One table style for Dashboard, Orders and Sales:
/// header row treatment, row height, divider colour and the cell-text
/// contrast ladder — so columns look and read identically on every page.
class GrowboxTable {
  const GrowboxTable._();

  /// One divider colour for the header rule and every row border.
  static Color dividerColor(bool isDark) =>
      isDark ? AppColors.darkBorder : AppColors.border;

  /// Column-heading text: 12 / w600 / tertiary / +0.5 tracking.
  static TextStyle headerStyle(bool isDark) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        letterSpacing: 0.5,
      );

  /// A single column heading.
  static Widget headerCell(String text, bool isDark) =>
      Text(text, style: headerStyle(isDark));

  /// The shared header row shell: lg horizontal, md vertical padding.
  /// Column layout (flexes / fixed widths) stays with each page.
  static Widget headerRow({required List<Widget> children}) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        child: Row(children: children),
      );

  /// The rule under the header row.
  static Widget headerDivider(bool isDark) =>
      Divider(height: 1, color: dividerColor(isDark));

  /// One row shell: lg×md padding on desktop rows, lg padding on the mobile
  /// card layout, and a 0.5px bottom divider in the shared colour — the
  /// same row height everywhere. [onTap] wraps the row in an InkWell.
  static Widget row({
    required bool isDark,
    bool mobile = false,
    VoidCallback? onTap,
    required Widget child,
  }) {
    final wrapped = Container(
      padding: mobile
          ? const EdgeInsets.all(AppDimensions.lg)
          : const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: dividerColor(isDark), width: 0.5),
        ),
      ),
      child: child,
    );
    return onTap == null
        ? wrapped
        : InkWell(
            onTap: onTap,
            // Pin the hover tint so rows read as clickable in BOTH themes:
            // ThemeData's default hover colour can be invisible against
            // the dark card surface, while the shared tinted surface
            // tokens are visible on light and dark alike.
            hoverColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
            child: wrapped,
          );
  }

  // ── Cell contrast ladder ──

  /// 14 / w600 / primary text — row ids and amounts.
  static TextStyle strongStyle(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      );

  /// 13 / secondary — item descriptions and quantities.
  static TextStyle secondaryStyle(bool isDark) => TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      );

  /// 12 / secondary — customer names, time and date columns.
  static TextStyle metaStyle(bool isDark) => TextStyle(
        fontSize: 12,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      );

  /// 11 / tertiary — sub-lines such as unit prices.
  static TextStyle mutedStyle(bool isDark) => TextStyle(
        fontSize: 11,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
      );
}
