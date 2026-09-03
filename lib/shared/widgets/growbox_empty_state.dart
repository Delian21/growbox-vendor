import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'growbox_button.dart';

/// An animated empty state placeholder with icon, title, subtitle, and optional action.
///
/// Wraps everything in a subtle fade + scale entrance animation so the
/// empty state feels alive rather than static.
class GrowboxEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GrowboxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<GrowboxEmptyState> createState() => _GrowboxEmptyStateState();
}

class _GrowboxEmptyStateState extends State<GrowboxEmptyState>
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

    // Kick off animation after first frame
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
                  // ── Icon circle with gradient ──
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.primaryDark.withAlpha(40),
                                AppColors.primary.withAlpha(30),
                              ]
                            : [
                                AppColors.primarySurface,
                                AppColors.primary.withAlpha(20),
                              ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withAlpha(isDark ? 30 : 50),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 40,
                      color: AppColors.primary,
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

                  // ── Optional action button ──
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(height: 28),
                    GrowboxButton(
                      label: widget.actionLabel!,
                      onPressed: widget.onAction,
                      icon: Icons.add,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}