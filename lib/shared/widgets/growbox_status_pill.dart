import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// The app's single status pill (Dashboard, Orders, Sales — including the
/// order details page).
///
/// [status] is the status as a lowercase word — `OrderStatus.name` or the
/// string keys the dashboard/sales rows already carry — so every page
/// shares one label/colour map instead of four copies.
///
/// Theming:
///  * Light theme keeps the established look: pastel `*Light` fill with the
///    full-strength status colour for the text.
///  * Dark theme uses a dark, low-opacity tint of the status colour (16%
///    alpha over the dark surface) with a contrast-raised full-strength
///    text colour — the old bright-pastel fills were harsh on dark, and
///    amber-on-cream / cyan-on-cyan-cream failed contrast.
///  * A 6px leading dot in the text colour keeps the blue/violet/cyan
///    trio (Accepted / Preparing / Ready) instantly distinguishable.
///
/// Unknown keys render nothing, matching the old per-page switches'
/// `SizedBox.shrink()` fallback.
class GrowboxStatusPill extends StatelessWidget {
  final String status;

  const GrowboxStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final spec = _specs[status];
    if (spec == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg =
        isDark ? spec.statusColor.withValues(alpha: 0.16) : spec.lightBg;
    final Color fg = isDark ? spec.darkText : spec.lightText;

    return Container(
      // Same metrics as GrowboxBadge(isSmall: true) so pills keep their
      // size when pages swap them in.
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            spec.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSpec {
  const _StatusSpec({
    required this.label,
    required this.statusColor,
    required this.lightBg,
    required this.lightText,
    required this.darkText,
  });

  final String label;

  /// Base status colour — used as the dark theme's low-opacity tint.
  final Color statusColor;

  /// Light theme: current look (pastel fill + full-strength text).
  final Color lightBg;
  final Color lightText;

  /// Dark theme text: same hue, lifted to read against the dark tint.
  final Color darkText;
}

const Map<String, _StatusSpec> _specs = {
  'pending': _StatusSpec(
    label: 'Pending',
    statusColor: AppColors.pending,
    lightBg: AppColors.pendingLight,
    lightText: AppColors.pending,
    darkText: AppColors.pendingOnDark,
  ),
  'accepted': _StatusSpec(
    label: 'Accepted',
    statusColor: AppColors.accepted,
    lightBg: AppColors.acceptedLight,
    lightText: AppColors.accepted,
    darkText: AppColors.acceptedOnDark,
  ),
  'preparing': _StatusSpec(
    label: 'Preparing',
    statusColor: AppColors.preparing,
    lightBg: AppColors.preparingLight,
    lightText: AppColors.preparing,
    darkText: AppColors.preparingOnDark,
  ),
  'ready': _StatusSpec(
    label: 'Ready',
    statusColor: AppColors.ready,
    lightBg: AppColors.readyLight,
    lightText: AppColors.ready,
    darkText: AppColors.readyOnDark,
  ),
  'completed': _StatusSpec(
    label: 'Completed',
    statusColor: AppColors.completed,
    lightBg: AppColors.completedLight,
    lightText: AppColors.completed,
    darkText: AppColors.completedOnDark,
  ),
  'cancelled': _StatusSpec(
    label: 'Cancelled',
    statusColor: AppColors.cancelled,
    lightBg: AppColors.cancelledLight,
    lightText: AppColors.cancelled,
    darkText: AppColors.cancelledOnDark,
  ),
};
