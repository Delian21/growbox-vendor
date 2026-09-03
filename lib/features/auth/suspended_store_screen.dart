import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';

/// Full-screen status shown when a store has been suspended (S61).
///
/// Displays a clear explanation, suspension reason placeholder, and
/// prominent contact-support action. Non-dismissible — the user must
/// reach out to resolve the suspension.
class SuspendedStoreScreen extends StatefulWidget {
  const SuspendedStoreScreen({super.key});

  @override
  State<SuspendedStoreScreen> createState() => _SuspendedStoreScreenState();
}

class _SuspendedStoreScreenState extends State<SuspendedStoreScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Suspended icon ──
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.error.withAlpha(40),
                                  AppColors.errorLight.withAlpha(30),
                                ]
                              : [
                                  AppColors.errorLight,
                                  AppColors.error.withAlpha(20),
                                ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              AppColors.error.withAlpha(isDark ? 30 : 50),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        size: 44,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Title ──
                    Text(
                      'Store Suspended',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // ── Description ──
                    Text(
                      'Your store has been suspended due to a violation of our terms of service. '
                      'You will not be able to receive orders until the issue is resolved.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // ── Reason card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.lg),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.error.withAlpha(15)
                            : AppColors.errorLight.withAlpha(120),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(
                          color: AppColors.error.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.gavel_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Suspension Reason',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Policy violation detected. Please contact our support team for details and resolution steps.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Contact support (primary action) ──
                    GrowboxButton(
                      label: 'Contact Support',
                      onPressed: () {
                        // TODO: Navigate to support or open email
                      },
                      icon: Icons.support_agent_rounded,
                    ),
                    const SizedBox(height: 12),

                    // ── Logout link ──
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
