import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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
                            'assets/images/growbox_logo_light.png',
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
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter your email or phone number and we'll send you a link to reset your password.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Email/Phone ──
                          GrowboxTextField(
                            label: 'Email or Phone Number',
                            hint: 'vendor@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefix: const Icon(Icons.contact_mail_outlined, size: 20),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email or phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Send Reset Link Button ──
                          GrowboxButton(
                            label: 'Send Reset Link',
                            onPressed: _isLoading ? null : _handleSendReset,
                            isExpanded: true,
                            isLoading: _isLoading,
                            icon: Icons.send_outlined,
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

  Future<void> _handleSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset link sent! Check your inbox.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/reset-password');
  }
}
