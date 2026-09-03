import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum GrowboxButtonVariant { primary, secondary, outline, text, danger }

class GrowboxButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final GrowboxButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double? width;

  const GrowboxButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GrowboxButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.width,
  });

  @override
  State<GrowboxButton> createState() => _GrowboxButtonState();
}

class _GrowboxButtonState extends State<GrowboxButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _feedbackController;
  late Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // ── Emerald palette per state ──
  static const Color _defaultBg = Color(0xFF1A7F50);
  static const Color _defaultFg = Colors.white;
  static const Color _hoverBg = Color(0xFF22A064);
  static const Color _hoverFg = Colors.white;
  static const Color _pressedBg = Color(0xFF14603A);
  static const Color _pressedFg = Colors.white;
  static const Color _disabledBg = Color(0xFFC8D4C8);
  static const Color _disabledFg = Color(0xFF94A494);

  // ── Secondary palette ──
  static const Color _secondaryBg = Color(0xFFE8F5EE);
  static const Color _secondaryFg = Color(0xFF1A7F50);
  static const Color _secondaryHoverBg = Color(0xFFD4EDDE);
  static const Color _secondaryPressedBg = Color(0xFFC0E4CE);
  static const Color _secondaryDisabledBg = Color(0xFFF0F3F0);
  static const Color _secondaryDisabledFg = Color(0xFF94A494);

  // ── Danger palette ──
  static const Color _dangerBg = Color(0xFFDC2626);
  static const Color _dangerFg = Colors.white;
  static const Color _dangerHoverBg = Color(0xFFC41E1E);
  static const Color _dangerPressedBg = Color(0xFFAB1818);
  static const Color _dangerDisabledBg = Color(0xFFF0A8A8);
  static const Color _dangerDisabledFg = Color(0xFFB48880);

  ({Color bg, Color fg}) get _colors {
    if (!_isEnabled) {
      return switch (widget.variant) {
        GrowboxButtonVariant.primary => (bg: _disabledBg, fg: _disabledFg),
        GrowboxButtonVariant.secondary =>
          (bg: _secondaryDisabledBg, fg: _secondaryDisabledFg),
        GrowboxButtonVariant.outline =>
          (bg: Colors.transparent, fg: AppColors.textTertiary),
        GrowboxButtonVariant.text =>
          (bg: Colors.transparent, fg: AppColors.textTertiary),
        GrowboxButtonVariant.danger =>
          (bg: _dangerDisabledBg, fg: _dangerDisabledFg),
      };
    }

    if (_isPressed) {
      return switch (widget.variant) {
        GrowboxButtonVariant.primary => (bg: _pressedBg, fg: _pressedFg),
        GrowboxButtonVariant.secondary =>
          (bg: _secondaryPressedBg, fg: _secondaryFg),
        GrowboxButtonVariant.outline =>
          (bg: AppColors.border, fg: AppColors.primary),
        GrowboxButtonVariant.text =>
          (bg: AppColors.surfaceVariant, fg: AppColors.primary),
        GrowboxButtonVariant.danger =>
          (bg: _dangerPressedBg, fg: _dangerFg),
      };
    }

    if (_isHovered) {
      return switch (widget.variant) {
        GrowboxButtonVariant.primary => (bg: _hoverBg, fg: _hoverFg),
        GrowboxButtonVariant.secondary =>
          (bg: _secondaryHoverBg, fg: _secondaryFg),
        GrowboxButtonVariant.outline =>
          (bg: AppColors.primarySurface, fg: AppColors.primary),
        GrowboxButtonVariant.text =>
          (bg: AppColors.primarySurface, fg: AppColors.primary),
        GrowboxButtonVariant.danger =>
          (bg: _dangerHoverBg, fg: _dangerFg),
      };
    }

    // Default state
    return switch (widget.variant) {
      GrowboxButtonVariant.primary => (bg: _defaultBg, fg: _defaultFg),
      GrowboxButtonVariant.secondary => (bg: _secondaryBg, fg: _secondaryFg),
      GrowboxButtonVariant.outline =>
        (bg: Colors.transparent, fg: AppColors.primary),
      GrowboxButtonVariant.text =>
        (bg: Colors.transparent, fg: AppColors.primary),
      GrowboxButtonVariant.danger => (bg: _dangerBg, fg: _dangerFg),
    };
  }

  BoxBorder? get _boxBorder {
    if (widget.variant != GrowboxButtonVariant.outline) return null;
    if (!_isEnabled) {
      return Border.all(color: AppColors.border, width: 1.5);
    }
    if (_isPressed) {
      return Border.all(color: AppColors.primary, width: 2);
    }
    if (_isHovered) {
      return Border.all(
        color: AppColors.primary.withAlpha(180),
        width: 1.5,
      );
    }
    return Border.all(color: AppColors.primary, width: 1.5);
  }

  double get _elevation {
    if (!_isEnabled ||
        widget.variant == GrowboxButtonVariant.outline ||
        widget.variant == GrowboxButtonVariant.text) {
      return 0;
    }
    if (_isPressed) return 0;
    if (_isHovered) return 3;
    return 1;
  }

  Color get _shadowColor {
    if (widget.variant == GrowboxButtonVariant.danger) {
      return _dangerBg.withAlpha(_isHovered ? 50 : 30);
    }
    return _defaultBg.withAlpha(_isHovered ? 50 : 30);
  }

  void _onTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
    _feedbackController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
    _feedbackController.reverse();
  }

  void _onTapCancel() {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
    _feedbackController.reverse();
  }

  void _onTap() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    Widget child = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: TextStyle(
        color: colors.fg,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.fg,
              ),
            )
          else ...[
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: colors.fg),
              const SizedBox(width: AppDimensions.sm),
            ],
            Text(widget.label),
          ],
        ],
      ),
    );

    child = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: _boxBorder,
        boxShadow: _elevation > 0
            ? [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: _elevation * 2,
                  offset: Offset(0, _elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    // Scale animation for immediate press feedback
    child = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: child,
    );

    // MouseRegion for hover detection
    child = MouseRegion(
      cursor:
          _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: child,
    );

    // GestureDetector for press tracking
    child = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );

    if (widget.isExpanded || widget.width != null) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        child: child,
      );
    }

    return child;
  }
}