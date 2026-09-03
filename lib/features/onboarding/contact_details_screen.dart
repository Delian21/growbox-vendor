import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_text_field.dart';
import 'onboarding_layout.dart';

class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({super.key});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      currentStep: OnboardingStep.contactDetails,
      title: 'Contact information',
      subtitle: "We'll use this to reach you",
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Row: Name + Phone ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GrowboxTextField(
                          label: 'Full Name',
                          hint: 'John Green',
                          controller: _fullNameController,
                          prefix: const Icon(Icons.person_outlined, size: 20),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GrowboxTextField(
                          label: 'Phone Number',
                          hint: '0805 123 4567',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefix: const Icon(Icons.phone_outlined, size: 20),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    GrowboxTextField(
                      label: 'Full Name',
                      hint: 'John Green',
                      controller: _fullNameController,
                      prefix: const Icon(Icons.person_outlined, size: 20),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    GrowboxTextField(
                      label: 'Phone Number',
                      hint: '0805 123 4567',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefix: const Icon(Icons.phone_outlined, size: 20),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Email ──
            GrowboxTextField(
              label: 'Email Address',
              hint: 'john@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.email_outlined, size: 20),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Address ──
            GrowboxTextField(
              label: 'Address',
              hint: 'Abuja, FCT, Nigeria',
              controller: _addressController,
              prefix: const Icon(Icons.location_on_outlined, size: 20),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── Buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GrowboxButton(
                  label: 'Back',
                  onPressed: () => context.go('/onboarding/business-info'),
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
      ),
    );
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;
    context.go('/onboarding/success');
  }
}
