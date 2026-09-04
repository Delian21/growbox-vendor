import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../app/providers/store_provider.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_text_field.dart';
import 'onboarding_layout.dart';

class BusinessInfoScreen extends StatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController(
    text: 'We provide fresh, high-quality produce sourced directly from trusted farms.',
  );
  final Set<String> _selectedCategories = {};
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  // Operating hours
  final List<bool> _selectedDays = [true, true, true, true, true, false, false]; // Mon–Fri on by default
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 18, minute: 0);

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _categories = [
    'Grains & Cereals',
    'Fruits',
    'Legumes & Pulses',
    'Vegetables',
    'Tuber & Roots',
    'Oils',
    'Fresh Proteins',
    'Mushrooms',
    'Herbs & Spices',
    'Nut & Seeds',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OnboardingLayout(
      currentStep: OnboardingStep.businessInfo,
      title: 'Tell us about your business',
      subtitle: 'Provide information about your business',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Business Name ──
            GrowboxTextField(
              label: 'Business Name',
              hint: 'Green Harvest Farms',
              controller: _nameController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ── Business Categories (multi-select) ──
            _buildCategoryChips(isDark),
            const SizedBox(height: 20),

            // ── Description ──
            GrowboxTextField(
              label: 'Business Description',
              hint: 'We supply fresh farm products directly from our farm to customers.',
              controller: _descriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // ── Operating Hours ──
            Text(
              'Operating Hours',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set your available days and business hours',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // ── Day Chips ──
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final selected = _selectedDays[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedDays[i] = !_selectedDays[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // ── Time Pickers ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 400;
                final timeRow = Row(
                  children: [
                    // Opening time
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Opening Time',
                        time: _openTime,
                        isDark: isDark,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _openTime,
                          );
                          if (picked != null) setState(() => _openTime = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Closing time
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Closing Time',
                        time: _closeTime,
                        isDark: isDark,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _closeTime,
                          );
                          if (picked != null) setState(() => _closeTime = picked);
                        },
                      ),
                    ),
                  ],
                );
                return isWide ? timeRow : Column(children: [
                  _buildTimePicker(
                    label: 'Opening Time',
                    time: _openTime,
                    isDark: isDark,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _openTime,
                      );
                      if (picked != null) setState(() => _openTime = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTimePicker(
                    label: 'Closing Time',
                    time: _closeTime,
                    isDark: isDark,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _closeTime,
                      );
                      if (picked != null) setState(() => _closeTime = picked);
                    },
                  ),
                ]);
              },
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── Continue Button ──
            Align(
              alignment: Alignment.centerRight,
              child: GrowboxButton(
                label: 'Continue',
                onPressed: _handleContinue,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.access_time_outlined, size: 20),
              suffixIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
            ),
            child: Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Business Categories',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            if (_selectedCategories.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_selectedCategories.length} selected',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select all that apply',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final selected = _selectedCategories.contains(category);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedCategories.remove(category);
                  } else {
                    _selectedCategories.add(category);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // Validation error if none selected
        if (_submitted && _selectedCategories.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one category',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Future<void> _handleContinue() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) return;

    // ── Persist opening hours ──
    final days = <String>[];
    for (var i = 0; i < 7; i++) {
      if (_selectedDays[i]) days.add(_dayLabels[i]);
    }
    final open = _formatTime(_openTime);
    final close = _formatTime(_closeTime);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('store_operating_days', days);
    await prefs.setString('store_open_time', open);
    await prefs.setString('store_close_time', close);

    if (mounted) {
      context.read<StoreProvider>().updateOpeningHours(
        operatingDays: days,
        openTime: open,
        closeTime: close,
      );
      context.go('/onboarding/contact-details');
    }
  }
}
