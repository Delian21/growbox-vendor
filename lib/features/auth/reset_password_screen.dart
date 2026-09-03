import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                    AppColors.darkBackground,
                  ]
                : [
                    AppColors.bgGradientStart,
                    AppColors.background,
                    AppColors.primarySurface,
                    AppColors.bgGradientEnd,
                  ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.glassDark : AppColors.glassLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.glassBorderLight,
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Logo ──
                          Image.asset(
                            'assets/images/growbox_logo.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Vendor Portal',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Title ──
                          Text(
                            'Reset your password',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a new password for your account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── New Password ──
                          GrowboxTextField(
                            label: 'New Password',
                            hint: 'Enter new password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefix: const Icon(Icons.lock_outlined, size: 20),
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Confirm Password ──
                          GrowboxTextField(
                            label: 'Confirm Password',
                            hint: 'Re-enter password',
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            prefix: const Icon(Icons.lock_outlined, size: 20),
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // ── Reset Button ──
                          GrowboxButton(
                            label: 'Reset Password',
                            onPressed: _isLoading ? null : _handleReset,
                            isExpanded: true,
                            isLoading: _isLoading,
                            icon: Icons.lock_reset,
                          ),
                          const SizedBox(height: 20),

                          // ── Back to Login ──
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Back to login',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
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
          ),
        ),
      ),
    );
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/login');
  }
}
