import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              constraints: const BoxConstraints(maxWidth: 560),
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
                            'Create Your Vendor Account',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Full Name ──
                          GrowboxTextField(
                            label: 'Full Name',
                            hint: 'e.g. Farm Fresh Enterprises',
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            prefix: const Icon(Icons.person_outlined, size: 20),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

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

                          // ── Phone ──
                          GrowboxTextField(
                            label: 'Phone Number',
                            hint: '+234 800 000 0000',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefix: const Icon(Icons.phone_outlined, size: 20),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                              if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-]'), ''))) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Password ──
                          GrowboxTextField(
                            label: 'Password',
                            hint: 'Create a strong password',
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
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Confirm Password ──
                          GrowboxTextField(
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            prefix: const Icon(Icons.lock_outlined, size: 20),
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirm = !_obscureConfirm);
                              },
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Terms ──
                          Row(
                            children: [
                              Checkbox(
                                value: _agreeTerms,
                                onChanged: (value) {
                                  setState(() => _agreeTerms = value ?? false);
                                },
                                activeColor: AppColors.primary,
                              ),
                              Expanded(
                                child: Text(
                                  'I agree to the Terms of Service and Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ── Sign Up Button ──
                          GrowboxButton(
                            label: 'Create Account',
                            onPressed: (_agreeTerms && !_isLoading) ? _handleRegister : null,
                            isExpanded: true,
                            isLoading: _isLoading,
                            icon: Icons.person_add_outlined,
                          ),
                          const SizedBox(height: 24),

                          // ── Login Link ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Log In',
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // TODO: Mock registration — will connect to auth later
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please verify your email.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/verify-email');
    }
  }
}