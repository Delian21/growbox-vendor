import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GrowboxSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const GrowboxSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class GrowboxSkeletonCard extends StatelessWidget {
  const GrowboxSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GrowboxSkeleton(width: 120, height: 14),
          const SizedBox(height: 12),
          const GrowboxSkeleton(width: 80, height: 32),
          const SizedBox(height: 12),
          const GrowboxSkeleton(width: 160, height: 12),
        ],
      ),
    );
  }
}

class GrowboxSkeletonTable extends StatelessWidget {
  final int rows;

  const GrowboxSkeletonTable({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rows,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const GrowboxSkeleton(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GrowboxSkeleton(width: 150, height: 14),
                    const SizedBox(height: 6),
                    const GrowboxSkeleton(width: 100, height: 12),
                  ],
                ),
              ),
              const GrowboxSkeleton(width: 80, height: 28, borderRadius: 14),
            ],
          ),
        ),
      ),
    );
  }
}