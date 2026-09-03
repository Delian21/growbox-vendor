import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/account_card.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/utils/snackbar_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTab = 0;
  final _accountFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();

  final _tabs = [
    'Account Settings',
    'Account Security',
    'Notification Preferences',
    'Payout Settings',
    'Manage Staff',
    'Help & Support',
  ];

  final _tabIcons = [
    Icons.person_outline,
    Icons.security_outlined,
    Icons.notifications_outlined,
    Icons.payment_outlined,
    Icons.people_outline,
    Icons.help_outline,
  ];

  // ── Controllers for form fields ──
  final _fullNameController = TextEditingController(text: 'Oluwaseun Adebayo');
  final _emailController = TextEditingController(text: 'adebayo@greenharvest.com');
  final _phoneController = TextEditingController(text: '+234 801 234 5678');
  final _businessNameController = TextEditingController(text: 'Green Harvest Farms');
  final _businessEmailController = TextEditingController(text: 'contact@greenharvest.com');
  final _businessPhoneController = TextEditingController(text: '+234 801 234 5678');
  final _businessAddressController = TextEditingController(text: 'Ogun State, Nigeria');
  final _storeTypeController = TextEditingController(text: 'Farm Fresh');

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _storeTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _buildHeader(isDark),
          const SizedBox(height: AppDimensions.xl),
          
          // ── Main Content ──
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return _buildDesktopLayout(isDark);
              }
              return _buildMobileLayout(isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(
            Icons.settings_outlined,
            size: 22,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                'Manage your account and store preferences',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left Sidebar ──
        SizedBox(
          width: 240,
          child: _buildSidebar(isDark),
        ),
        const SizedBox(width: AppDimensions.xl),
        
        // ── Right Content ──
        Expanded(
          child: _buildContent(isDark),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        // ── Mobile Tab Selector ──
        _buildMobileTabSelector(isDark),
        const SizedBox(height: AppDimensions.lg),
        
        // ── Content ──
        _buildContent(isDark),
      ],
    );
  }

  Widget _buildMobileTabSelector(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primarySurface
                    : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tabIcons[index],
                    size: 16,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppDimensions.xs),
                  Text(
                    _tabs[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return GrowboxCard(
      padding: const EdgeInsets.all(AppDimensions.sm),
      child: Column(
        children: [
          ...List.generate(_tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.xs),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = index),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _tabIcons[index],
                          size: 20,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (_selectedTab) {
        0 => _buildAccountSettings(isDark),
        1 => _buildAccountSecurity(isDark),
        2 => _buildNotificationPreferences(isDark),
        3 => _buildPayoutSettings(isDark),
        4 => _buildManageStaff(isDark),
        5 => _buildHelpSupport(isDark),
        _ => _buildAccountSettings(isDark),
      },
    );
  }

  // ══════════════════════════════════════════
  // ── ACCOUNT SETTINGS ──
  // ══════════════════════════════════════════
  Widget _buildAccountSettings(bool isDark) {
    return Column(
      key: const ValueKey('account_settings'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Business Profile Card ──
        _buildBusinessProfileCard(isDark),
        const SizedBox(height: AppDimensions.xl),
        
        // ── Account Information Card ──
        _buildAccountInfoCard(isDark),
      ],
    );
  }

  Widget _buildBusinessProfileCard(bool isDark) {
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _businessNameController.text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          const Divider(),
          const SizedBox(height: AppDimensions.lg),
          Text(
            'Business Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Form(
            key: _businessFormKey,
            child: Column(
              children: [
                _buildFormRow(
                  isDark: isDark,
                  children: [
                    _buildTextField(
                      label: 'Business Name',
                      controller: _businessNameController,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? 'Enter business name' : null,
                    ),
                    _buildTextField(
                      label: 'Business Email',
                      controller: _businessEmailController,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        if (!v.contains('@')) return 'Enter valid email';
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildFormRow(
                  isDark: isDark,
                  children: [
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _businessPhoneController,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
                    ),
                    _buildTextField(
                      label: 'Business Address',
                      controller: _businessAddressController,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? 'Enter address' : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildFormRow(
                  isDark: isDark,
                  children: [
                    _buildTextField(
                      label: 'Store Type',
                      controller: _storeTypeController,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? 'Enter store type' : null,
                    ),
                    const SizedBox.shrink(), // Empty space for alignment
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Align(
            alignment: Alignment.centerRight,
            child: GrowboxButton(
              label: 'Save Changes',
              icon: Icons.save_outlined,
              onPressed: () {
                if (_businessFormKey.currentState!.validate()) {
                  SnackbarHelper.showSuccess(context, 'Business profile saved!');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(bool isDark) {
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Form(
            key: _accountFormKey,
            child: Column(
              children: [
                _buildFormRow(
                  isDark: isDark,
                  children: [
                    _buildTextField(
                      label: 'Full Name',
                      controller: _fullNameController,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? 'Enter full name' : null,
                    ),
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        if (!v.contains('@')) return 'Enter valid email';
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildFormRow(
                  isDark: isDark,
                  children: [
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Align(
            alignment: Alignment.centerRight,
            child: GrowboxButton(
              label: 'Save Changes',
              icon: Icons.save_outlined,
              onPressed: () {
                if (_accountFormKey.currentState!.validate()) {
                  SnackbarHelper.showSuccess(context, 'Account info saved!');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── ACCOUNT SECURITY ──
  // ══════════════════════════════════════════
  Widget _buildAccountSecurity(bool isDark) {
    return GrowboxCard(
      key: const ValueKey('account_security'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Security',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildSecurityOption(
            isDark: isDark,
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Change'),
            ),
          ),
          const Divider(),              _buildSecurityOption(
            isDark: isDark,
            icon: Icons.phone_outlined,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeThumbColor: AppColors.primary,
            ),
          ),
          const Divider(),
          _buildSecurityOption(
            isDark: isDark,
            icon: Icons.devices_outlined,
            title: 'Active Sessions',
            subtitle: 'Manage your logged-in devices',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── NOTIFICATION PREFERENCES ──
  // ══════════════════════════════════════════
  Widget _buildNotificationPreferences(bool isDark) {
    return GrowboxCard(
      key: const ValueKey('notification_preferences'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildNotificationOption(
            isDark: isDark,
            title: 'Order Notifications',
            subtitle: 'Get notified when you receive new orders',
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          _buildNotificationOption(
            isDark: isDark,
            title: 'Email Notifications',
            subtitle: 'Receive order updates via email',
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          _buildNotificationOption(
            isDark: isDark,
            title: 'SMS Notifications',
            subtitle: 'Get text messages for urgent updates',
            value: false,
            onChanged: (value) {},
          ),
          const Divider(),
          _buildNotificationOption(
            isDark: isDark,
            title: 'Marketing Emails',
            subtitle: 'Receive tips and promotional content',
            value: false,
            onChanged: (value) {},
          ),
          const SizedBox(height: AppDimensions.xl),
          Align(
            alignment: Alignment.centerRight,
            child: GrowboxButton(
              label: 'Save Preferences',
              icon: Icons.save_outlined,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── PAYOUT SETTINGS ──
  // ══════════════════════════════════════════
  Widget _buildPayoutSettings(bool isDark) {
    return GrowboxCard(
      key: const ValueKey('payout_settings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payout Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildPayoutInfo(
            isDark: isDark,
            label: 'Bank Name',
            value: 'Guaranty Trust Bank',
          ),
          const Divider(),
          _buildPayoutInfo(
            isDark: isDark,
            label: 'Account Number',
            value: '0123456789',
          ),
          const Divider(),
          _buildPayoutInfo(
            isDark: isDark,
            label: 'Account Name',
            value: 'Green Harvest Farms',
          ),
          const SizedBox(height: AppDimensions.xl),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Update Bank Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.md,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── MANAGE STAFF ──
  // ══════════════════════════════════════════
  Widget _buildManageStaff(bool isDark) {
    return GrowboxCard(
      key: const ValueKey('manage_staff'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manage Staff',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              GrowboxButton(
                label: 'Add Staff',
                icon: Icons.person_add_outlined,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildStaffItem(
            isDark: isDark,
            name: 'John Doe',
            email: 'john@greenharvest.com',
            role: 'Manager',
          ),
          const Divider(),
          _buildStaffItem(
            isDark: isDark,
            name: 'Jane Smith',
            email: 'jane@greenharvest.com',
            role: 'Staff',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── HELP & SUPPORT ──
  // ══════════════════════════════════════════
  Widget _buildHelpSupport(bool isDark) {
    return Column(
      key: const ValueKey('help_support'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
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
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── HELPER WIDGETS ──
  // ══════════════════════════════════════════
  Widget _buildFormRow({
    required bool isDark,
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          return Row(
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: AppDimensions.lg),
              Expanded(child: children[1]),
            ],
          );
        }
        return Column(
          children: [
            children[0],
            const SizedBox(height: AppDimensions.md),
            children[1],
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityOption({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
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
          trailing,
        ],
      ),
    );
  }

  Widget _buildNotificationOption({
    required bool isDark,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
      child: Row(
        children: [
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutInfo({
    required bool isDark,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
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
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffItem({
    required bool isDark,
    required String name,
    required String email,
    required String role,
  }) {
    return AccountCard(
      label: '$name — $role',
      icon: Icons.person_outline,
      iconBgColor: AppColors.info,
      onTap: () async {
        final dialogContext = context;
        final confirmed = await ConfirmDialog.show(
          context: dialogContext,
          title: 'Remove Staff',
          message: 'Are you sure you want to remove $name from your team? This action cannot be undone.',
        );
        if (confirmed && mounted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$name has been removed')),
            );
          }
        }
      },
    );
  }
}