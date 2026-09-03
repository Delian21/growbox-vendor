import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum OnboardingStep { businessInfo, contactDetails, verification, success }

/// Describes one step in the onboarding indicator.
class _StepInfo {
  final String label;
  final OnboardingStep? step;
  final bool isPreCompleted;

  const _StepInfo(this.label, {this.step, this.isPreCompleted = false});
}

class OnboardingLayout extends StatelessWidget {
  final OnboardingStep currentStep;
  final String title;
  final String subtitle;
  final Widget child;

  const OnboardingLayout({
    super.key,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  // Goal Gradient: "Registered" is pre-completed so the user starts at ~20%
  static const _steps = [
    _StepInfo('Registered', isPreCompleted: true),
    _StepInfo('Business Info', step: OnboardingStep.businessInfo),
    _StepInfo('Contact Details', step: OnboardingStep.contactDetails),
    _StepInfo('Verification', step: OnboardingStep.verification),
    _StepInfo('Done', step: OnboardingStep.success),
  ];

  int get _currentOnboardingIndex =>
      _steps.indexWhere((s) => s.step == currentStep);

  void _handleBack(BuildContext context) {
    switch (currentStep) {
      case OnboardingStep.contactDetails:
        context.go('/onboarding/business-info');
      case OnboardingStep.verification:
        context.go('/onboarding/contact-details');
      case OnboardingStep.success:
        context.go('/onboarding/verification');
      case OnboardingStep.businessInfo:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.xl,
                vertical: AppDimensions.md,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: Image.asset(
                      isDark ? 'assets/images/growbox_logo.png' : 'assets/images/growbox_logo_light.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GROWBOX',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),

                  // ── Step Indicator (scrollable on narrow screens) ──
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_steps.length, (i) {
                          final step = _steps[i];
                          final isPreCompleted = step.isPreCompleted;
                          final isActive = step.step == currentStep;
                          final isCompleted = isPreCompleted ||
                              (step.step != null && _currentOnboardingIndex >= 0 &&
                               i < _currentOnboardingIndex);

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (i > 0)
                                Container(
                                  width: 16,
                                  height: 1,
                                  color: isCompleted
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorder : AppColors.border),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPreCompleted || (isCompleted && !isActive))
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: isActive
                                              ? Colors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                    Text(
                                      step.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                        color: isActive
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppDimensions.lg),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.xl),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
