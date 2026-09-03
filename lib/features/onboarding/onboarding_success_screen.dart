import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';

class OnboardingSuccessScreen extends StatelessWidget {
  const OnboardingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Store Illustration ──
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Congratulations ──
                Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account is pending approval.\nWe will review your information and activate your store\nwithin 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Go to Dashboard Button ──
                GrowboxButton(
                  label: 'Go to Dashboard',
                  onPressed: () => context.go('/dashboard'),
                  isExpanded: true,
                  icon: Icons.dashboard_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
