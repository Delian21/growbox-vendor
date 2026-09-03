import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class GrowboxBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool isSmall;

  const GrowboxBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.isSmall = false,
  });

  const GrowboxBadge.pending({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.pendingLight,
        textColor = AppColors.pending;

  const GrowboxBadge.accepted({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.acceptedLight,
        textColor = AppColors.accepted;

  const GrowboxBadge.preparing({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.preparingLight,
        textColor = AppColors.preparing;

  const GrowboxBadge.ready({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.readyLight,
        textColor = AppColors.ready;

  const GrowboxBadge.completed({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.completedLight,
        textColor = AppColors.completed;

  const GrowboxBadge.cancelled({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.cancelledLight,
        textColor = AppColors.cancelled;

  const GrowboxBadge.success({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.successLight,
        textColor = AppColors.success;

  const GrowboxBadge.warning({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.warningLight,
        textColor = AppColors.warning;

  const GrowboxBadge.error({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.errorLight,
        textColor = AppColors.error;

  const GrowboxBadge.info({super.key, required this.label, this.isSmall = false})
      : backgroundColor = AppColors.infoLight,
        textColor = AppColors.info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmall ? 11 : 13,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}