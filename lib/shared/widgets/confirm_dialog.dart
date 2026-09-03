import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final IconData icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'Delete',
    this.icon = Icons.delete_outline,
  });

  /// Convenience method to show the dialog and return true if confirmed
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    IconData icon = Icons.delete_outline,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: () => Navigator.pop(context, true),
        icon: icon,
      ),
    );
    return result == true;
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
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.error),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}