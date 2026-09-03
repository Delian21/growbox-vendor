import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A single shimmer block that animates a gradient sweep.
class ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppDimensions.radiusMd,
  });

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final highlightColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(-_controller.value * 2, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton layout for an order card (used on the Orders screen)
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              ShimmerBlock(width: 90, height: 16),
              Spacer(),
              ShimmerBlock(width: 70, height: 22, borderRadius: 999),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          const ShimmerBlock(width: 140, height: 14),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: const [
              ShimmerBlock(width: 110, height: 14),
              Spacer(),
              ShimmerBlock(width: 70, height: 14),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          const ShimmerBlock(width: 200, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton layout for a product card (used on the Products grid)
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBlock(width: double.infinity, height: 100, borderRadius: AppDimensions.radiusLg),
        const SizedBox(height: AppDimensions.md),
        const ShimmerBlock(width: 120, height: 16),
        const SizedBox(height: AppDimensions.sm),
        const ShimmerBlock(width: 80, height: 12),
        const Spacer(),
        Row(
          children: const [
            ShimmerBlock(width: 70, height: 18),
            Spacer(),
            ShimmerBlock(width: 50, height: 12),
          ],
        ),
      ],
    );
  }
}

/// Skeleton layout for a dashboard stat card
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBlock(width: 36, height: 36, borderRadius: 999),
        const SizedBox(height: AppDimensions.md),
        const ShimmerBlock(width: 100, height: 14),
        const SizedBox(height: AppDimensions.sm),
        const ShimmerBlock(width: 60, height: 24),
      ],
    );
  }
}