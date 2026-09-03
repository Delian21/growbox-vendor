import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendSeconds = 45;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _resendSeconds = 45;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Mail Icon ──
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mail_outline,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Title ──
                        Text(
                          'Verify your email',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We've sent a 6-digit code to\nvendor@email.com",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── OTP Boxes ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return Container(
                              width: 44,
                              height: 52,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: KeyboardListener(
                                focusNode: FocusNode(),
                                onKeyEvent: (event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey == LogicalKeyboardKey.backspace &&
                                      _controllers[index].text.isEmpty &&
                                      index > 0) {
                                    _controllers[index - 1].clear();
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                },
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: isDark ? AppColors.darkBorder : AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: _controllers[index].text.isNotEmpty
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkBorder : AppColors.border),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                    if (value.isNotEmpty && index < 5) {
                                      _focusNodes[index + 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        // ── Resend Timer ──
                        if (!_canResend)
                          Text(
                            'Resend code in 00:${_resendSeconds.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _startTimer,
                            child: const Text(
                              'Resend code',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // ── Change Email ──
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Change email?',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Verify Button ──
                        GrowboxButton(
                          label: 'Verify',
                          onPressed: _handleVerify,
                          isExpanded: true,
                          icon: Icons.check,
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
    );
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    // TODO: Mock verification
    context.go('/onboarding/business-info');
  }
}
