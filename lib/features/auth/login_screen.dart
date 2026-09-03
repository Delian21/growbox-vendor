import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.glassDark
                          : AppColors.glassLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.glassBorderLight,
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
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Email ──
                          GrowboxTextField(
                            label: 'Email Address',
                            hint: 'vendor@growbox.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefix: const Icon(Icons.email_outlined, size: 20),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Password ──
                          GrowboxTextField(
                            label: 'Password',
                            hint: 'Enter your password',
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
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Forgot Password ──
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Login Button ──
                          GrowboxButton(
                            label: 'Log In',
                            onPressed: _isLoading ? null : _handleLogin,
                            isExpanded: true,
                            isLoading: _isLoading,
                            icon: Icons.arrow_forward,
                          ),
                          const SizedBox(height: 24),

                          // ── Divider ──
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Sign Up Link ──
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/register'),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Preview: Onboarding (dev link) ──
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => context.go('/onboarding/business-info'),
                            child: Text(
                              'Preview: Onboarding Flow',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.brandOrange,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Footer ──
                          Text(
                            '© 2026 UIAN. All rights reserved.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.textTertiary,
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // TODO: Mock login — will connect to auth later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Welcome back!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/dashboard');
  }
}