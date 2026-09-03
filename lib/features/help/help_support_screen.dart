import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/utils/snackbar_helper.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find answers or get in touch with our team',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── FAQ Section ──
            GrowboxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  _buildFaqItem(isDark, 'How do I add a new product?', 'Tap the "+ Add Product" button on the Products screen. Fill in the product details including name, category, price, and stock quantity.'),
                  const Divider(),
                  _buildFaqItem(isDark, 'How do I accept or reject orders?', 'Go to Orders, tap on a pending order, and you\'ll see Accept and Reject buttons. Accepting an order notifies the customer immediately.'),
                  const Divider(),
                  _buildFaqItem(isDark, 'How do I update my store hours?', 'Your operating hours are set during onboarding. To change them, contact support or update them from the Store Profile screen.'),
                  const Divider(),
                  _buildFaqItem(isDark, 'When do I get paid?', 'Payments are processed weekly. Your earnings (minus GROWBOX commission) are transferred to your registered bank account every Monday.'),
                  const Divider(),
                  _buildFaqItem(isDark, 'How do I turn my store offline?', 'Use the Open/Closed toggle on your Store Profile or Dashboard to pause incoming orders temporarily.'),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── Contact Support ──
            GrowboxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  _buildSupportOption(
                    isDark: isDark,
                    icon: Icons.email_outlined,
                    title: 'Email Us',
                    subtitle: 'support@growbox.com',
                    onTap: () => SnackbarHelper.showSuccess(context, 'Opening email client...'),
                  ),
                  const Divider(),
                  _buildSupportOption(
                    isDark: isDark,
                    icon: Icons.chat_bubble_outline,
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team (8 AM – 6 PM WAT)',
                    onTap: () => SnackbarHelper.showSuccess(context, 'Live chat coming soon!'),
                  ),
                  const Divider(),
                  _buildSupportOption(
                    isDark: isDark,
                    icon: Icons.phone_outlined,
                    title: 'Call Us',
                    subtitle: '+234 800 GROWBOX (476 9269)',
                    onTap: () => SnackbarHelper.showSuccess(context, 'Opening phone dialer...'),
                  ),
                  const Divider(),
                  _buildSupportOption(
                    isDark: isDark,
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Bug',
                    subtitle: 'Found something wrong? Let us know.',
                    onTap: () => SnackbarHelper.showSuccess(context, 'Bug report form coming soon!'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── App Info ──
            GrowboxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  _buildInfoRow(isDark, 'App Version', '1.0.0 (MVP)'),
                  const Divider(),
                  _buildInfoRow(isDark, 'Build', '2026.08'),
                  const Divider(),
                  _buildInfoRow(isDark, 'Terms of Service', 'View'),
                  const Divider(),
                  _buildInfoRow(isDark, 'Privacy Policy', 'View'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(bool isDark, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
