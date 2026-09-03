import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';

/// Full-screen status shown when a store's application is under review (S60).
///
/// Displays an animated "under review" illustration, explanatory text,
/// and a contact-support action. The screen is non-dismissible — the user
/// must contact support or wait for approval.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

    // Gentle pulse for the clock icon
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
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
                    // ── Animated clock icon ──
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    AppColors.warning.withAlpha(40),
                                    AppColors.warningLight.withAlpha(30),
                                  ]
                                : [
                                    AppColors.warningLight,
                                    AppColors.warning.withAlpha(20),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.warning
                                .withAlpha(isDark ? 30 : 50),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 44,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Title ──
                    Text(
                      'Your Store is Under Review',
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
                      'We\'re reviewing your business information and documents. '
                      'This usually takes 1–3 business days.',
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

                    // ── Info card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.lg),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.warning.withAlpha(15)
                            : AppColors.warningLight.withAlpha(120),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(
                          color: AppColors.warning.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Text(
                              'You\'ll receive a notification once your store is approved. '
                              'In the meantime, you can contact our support team for any questions.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Contact support button ──
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
