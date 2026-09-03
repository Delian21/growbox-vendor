import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A reusable success modal dialog (S62) with animated check icon, title,
/// message, and a single OK dismiss button.
///
/// Mirrors the ConfirmDialog structure but uses the success jade palette
/// instead of the error coral palette.
class GrowboxSuccessModal extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onDismiss;
  final IconData icon;

  const GrowboxSuccessModal({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel = 'OK',
    required this.onDismiss,
    this.icon = Icons.check_circle_outline_rounded,
  });

  /// Convenience method to show the modal and return when dismissed.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'OK',
    IconData icon = Icons.check_circle_outline_rounded,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => GrowboxSuccessModal(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onDismiss: () => Navigator.pop(context, true),
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      title: Row(
        children: [
          // ── Success icon circle ──
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.success),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color:
              isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
