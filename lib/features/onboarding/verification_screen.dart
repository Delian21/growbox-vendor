import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';
import 'onboarding_layout.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String? _cacFileName;
  String? _idFileName;
  String? _utilityFileName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OnboardingLayout(
      currentStep: OnboardingStep.verification,
      title: 'Verify your business',
      subtitle: 'Upload necessary documents to verify your business',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── CAC Certificate ──
          _buildUploadRow(
            label: 'CAC Certificate',
            fileName: _cacFileName,
            onUpload: () => setState(() => _cacFileName = 'certificate_cac.pdf'),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // ── Valid ID ──
          _buildUploadRow(
            label: 'Valid ID (Owner)',
            fileName: _idFileName,
            onUpload: () => setState(() => _idFileName = 'id_card.jpg'),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // ── Utility Bill ──
          _buildUploadRow(
            label: 'Utility Bill / Address Proof',
            fileName: _utilityFileName,
            onUpload: () => setState(() => _utilityFileName = 'utility.pdf'),
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.xl),

          // ── Buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GrowboxButton(
                label: 'Back',
                onPressed: () => context.go('/onboarding/contact-details'),
                variant: GrowboxButtonVariant.outline,
                icon: Icons.arrow_back,
              ),
              GrowboxButton(
                label: 'Continue',
                onPressed: _handleContinue,
                icon: Icons.arrow_forward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadRow({
    required String label,
    required String? fileName,
    required VoidCallback onUpload,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Label
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),

          // File name or placeholder
          if (fileName != null)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Icon(Icons.description, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            const Spacer(flex: 3),

          const SizedBox(width: 12),

          // Upload button
          GestureDetector(
            onTap: onUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Upload File',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    context.go('/onboarding/success');
  }
}
