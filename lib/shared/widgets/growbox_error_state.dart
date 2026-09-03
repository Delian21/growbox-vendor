import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'growbox_button.dart';

/// An animated error state placeholder with error icon, title, subtitle, and retry action.
///
/// Mirrors the GrowboxEmptyState pattern but uses the muted coral error palette
/// and includes a mandatory retry button.
class GrowboxErrorState extends StatefulWidget {
  final String title;
  final String subtitle;
  final String retryLabel;
  final VoidCallback onRetry;
  final IconData icon;
  final String? details;

  const GrowboxErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle = 'We couldn\'t load this content. Please try again.',
    this.retryLabel = 'Try Again',
    required this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.details,
  });

  @override
  State<GrowboxErrorState> createState() => _GrowboxErrorStateState();
}

class _GrowboxErrorStateState extends State<GrowboxErrorState>
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
      begin: const Offset(0, 0.1),
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Error icon circle ──
                  Container(
                    width: 88,
                    height: 88,
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
                        color: AppColors.error.withAlpha(isDark ? 30 : 50),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Title ──
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ──
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // ── Optional error details ──
                  if (widget.details != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.error.withAlpha(20)
                            : AppColors.errorLight,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Text(
                        widget.details!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // ── Retry button ──
                  const SizedBox(height: 28),
                  GrowboxButton(
                    label: widget.retryLabel,
                    onPressed: widget.onRetry,
                    icon: Icons.refresh_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
