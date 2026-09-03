import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui';
import '../../app/theme_provider.dart';
import '../../app/providers/auth_provider.dart';
import '../../app/providers/notifications_provider.dart';
import '../../app/providers/orders_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../data/mock/mock_images.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  bool _sidebarCollapsed = false;
  bool _contentExpanded = true;
  bool _isHoveringSidebar = false;
  bool _showExpandedContent = true;
  Timer? _sidebarContentTimer;
  int _mobileNavIndex = 0;
  int? _pressedNavIndex;
  bool _isDockVisible = true;
  double _lastScrollOffset = 0;
  String _lastLocation = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _navRowKey = GlobalKey();
  late AnimationController _drawerFadeController;
  late Animation<double> _drawerFadeAnimation;
  AnimationController? _pillController;
  Animation<Offset> _pillAnimation = AlwaysStoppedAnimation(Offset.zero);
  Offset _pillStart = Offset.zero;
  Offset _pillTarget = Offset.zero;
  double _pillItemWidth = 0;

  // Mobile bottom nav items
  static const _mobileNavItems = [
    _MobileNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', route: '/dashboard'),
    _MobileNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders', route: '/orders'),
    _MobileNavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Products', route: '/products'),
    _MobileNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Sales', route: '/sales'),
  ];

    @override
  void initState() {
    super.initState();
    _drawerFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _drawerFadeAnimation = CurvedAnimation(
      parent: _drawerFadeController,
      curve: Curves.easeInOut,
    );
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _drawerFadeController.dispose();
    _pillController?.dispose();
    _sidebarContentTimer?.cancel();
    super.dispose();
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppDimensions.tablet;

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _getTitle(String location) {
    if (location.contains('/dashboard')) return AppStrings.dashboard;
    if (location.contains('/products')) return AppStrings.products;
    if (location.contains('/orders')) return AppStrings.orders;
    if (location.contains('/sales')) return AppStrings.sales;
    if (location.contains('/store')) return AppStrings.store;
    if (location.contains('/notifications')) return AppStrings.notifications;
    if (location.contains('/settings')) return AppStrings.settings;
    if (location.contains('/help')) return AppStrings.helpSupport;
    return AppStrings.dashboard;
  }

  DateTime? _lastBackPress;

  Future<bool> _handleBackNavigation() async {
    final location = GoRouterState.of(context).uri.toString();

    // If on dashboard, show exit confirmation
    if (location == '/dashboard') {
      final now = DateTime.now();
      if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
        return true; // Actually exit
      }
      _lastBackPress = now;
      if (!mounted) return true;

      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit GROWBOX Vendor?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Exit'),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    // For any other shell route, navigate back to dashboard
    context.go('/dashboard');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final title = _getTitle(location);
    final isMobile = _isMobile(context);
    final isDark = _isDark(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Update mobile nav index based on current location
    if (isMobile) {
      if (location != _lastLocation) {
        _lastLocation = location;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _lastScrollOffset = 0;
            if (!_isDockVisible) {
              setState(() => _isDockVisible = true);
            }
          }
        });
      }
      _updateMobileNavIndex(location);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? _buildDrawer(context, location, isDark) : null,
      body: Stack(
        children: [
          // 1. Full-screen content behind everything
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 0 : (_sidebarCollapsed && !_isHoveringSidebar)
                    ? AppDimensions.sidebarCollapsedWidth
                    : AppDimensions.sidebarWidth,
              ),
            child: Padding(
              padding: EdgeInsets.only(
                top: statusBarHeight + AppDimensions.headerHeight,
              ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? AppDimensions.lg : AppDimensions.xl,
                  ),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (isMobile && notification is ScrollUpdateNotification) {
                        final currentPixels = notification.metrics.pixels;
                        final delta = currentPixels - _lastScrollOffset;
                        _lastScrollOffset = currentPixels;

                        if (delta.abs() > 2) {
                          final scrollingDown = delta > 0;
                          final atTop = currentPixels <= notification.metrics.minScrollExtent + 10;
                          if (_isDockVisible && scrollingDown && !atTop) {
                            setState(() => _isDockVisible = false);
                          } else if (!_isDockVisible && atTop) {
                            setState(() => _isDockVisible = true);
                          }
                        }
                      }
                      return false;
                    },
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
          // 2. Sidebar floats on top (desktop only)
          if (!isMobile)
            Positioned(
              left: 0,
              top: statusBarHeight,
              bottom: 0,
              child: _buildSidebar(context, location, isDark),
            ),
          // 3. Header floats on top with glassmorphism
          Positioned(
            left: isMobile ? 0 : (_sidebarCollapsed && !_isHoveringSidebar)
                ? AppDimensions.sidebarCollapsedWidth
                : AppDimensions.sidebarWidth,
            right: 0,
            top: statusBarHeight,
            child: _buildHeader(context, title, isMobile, isDark),
          ),
          // 4. Bottom nav floats on top (mobile only)
          if (isMobile)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              bottom: _isDockVisible ? 0 : -120,
              child: _buildBottomNav(context, location, isDark),
            ),
        ],
      ),
    ),
    );
  }

  // ══════════════════════════════════════════
  // ── SIDEBAR ──
  // ══════════════════════════════════════════
  Widget _buildSidebar(BuildContext context, String location, bool isDark) {
    // Determine if sidebar should appear expanded:
    // - If not collapsed, always expanded
    // - If collapsed but hovering, temporarily expand
    final isEffectivelyExpanded = !_sidebarCollapsed || _isHoveringSidebar;
    final width = isEffectivelyExpanded
        ? AppDimensions.sidebarWidth
        : AppDimensions.sidebarCollapsedWidth;

    // When hovering a collapsed sidebar, show expanded content after a delay
    // so text doesn't appear while the sidebar width is still animating
    final showExpandedContent = !_sidebarCollapsed ? true : _showExpandedContent;

    return MouseRegion(
      onEnter: (_) {
        if (!mounted || !_sidebarCollapsed) return;
        _isHoveringSidebar = true;
        // Delay content expansion so text appears after width has expanded
        _sidebarContentTimer?.cancel();
        _sidebarContentTimer = Timer(const Duration(milliseconds: 200), () {
          if (mounted && _isHoveringSidebar) {
            setState(() => _showExpandedContent = true);
          }
        });
        setState(() {});
      },
      onExit: (_) {
        if (!mounted) return;
        _sidebarContentTimer?.cancel();
        if (_isHoveringSidebar) {
          _isHoveringSidebar = false;
          // Hide content immediately before width collapses
          _showExpandedContent = false;
          setState(() {});
        }
      },
      child: ClipRect(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: width,
          height: double.infinity,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.glassDark
                    : AppColors.darkBackground,
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.darkBorder,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildLogo(!showExpandedContent, isDark),
                  Divider(
                    height: 1,
                    color: AppColors.darkBorder.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.md,
                      ),
                      child: Column(
                        children: [
                          _buildNavSection(
                            'MAIN',
                            [
                              _NavItem(Icons.dashboard_outlined, Icons.dashboard, AppStrings.dashboard, '/dashboard'),
                              _NavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, AppStrings.products, '/products'),
                              _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, AppStrings.orders, '/orders', badgeCount: _getNavBadgeCount('/orders')),
                              _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, AppStrings.sales, '/sales'),
                            ],
                            location,
                            !showExpandedContent,
                            isDark,
                          ),
                          const SizedBox(height: AppDimensions.lg),
                          _buildNavSection(
                            'MANAGE',
                            [
                              _NavItem(Icons.store_outlined, Icons.store, AppStrings.store, '/store'),
                              _NavItem(Icons.notifications_outlined, Icons.notifications, AppStrings.notifications, '/notifications', badgeCount: _getNavBadgeCount('/notifications')),
                              _NavItem(Icons.help_outline, Icons.help, AppStrings.helpSupport, '/help'),
                              _NavItem(Icons.settings_outlined, Icons.settings, AppStrings.settings, '/settings'),
                            ],
                            location,
                            !showExpandedContent,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.darkBorder.withValues(alpha: 0.4),
                  ),
                  _buildMyAccountSection(isDark, !isEffectivelyExpanded),
                  if (!_isMobile(context))
                    _buildCollapseToggle(_contentExpanded, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isCollapsed, bool isDark) {
    return Container(
      height: AppDimensions.headerHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? AppDimensions.sm : AppDimensions.lg,
      ),
      child: Row(
  children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Image.asset(
        'assets/images/growbox_logo.png',
        width: 52,
        height: 52,
        fit: BoxFit.contain,
      ),
    ),
    AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isCollapsed ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: isCollapsed
            ? const SizedBox(width: 0)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: AppDimensions.md),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GROWBOX',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Vendor Portal',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : const Color(0xB3FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildNavSection(
    String sectionTitle,
    List<_NavItem> items,
    String location,
    bool isCollapsed,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.lg,
              top: AppDimensions.sm,
              bottom: AppDimensions.sm,
            ),
            child: Text(
              sectionTitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : const Color(0x80FFFFFF),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...items.map(
          (item) => _buildNavItem(item, location, isCollapsed, isDark),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    _NavItem item,
    String location,
    bool isCollapsed,
    bool isDark,
  ) {
    final isActive = location.startsWith(item.route);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(          onTap: () {
            context.go(item.route);
            _sidebarContentTimer?.cancel();
            if (_isMobile(context)) {
              HapticFeedback.lightImpact();
              _drawerFadeController.reverse();
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? AppDimensions.sm : AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                      ? AppColors.darkPrimary.withAlpha(25)
                      : const Color(0x26FFFFFF))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 20,
                      color: isActive
                          ? (isDark ? AppColors.darkPrimary : Colors.white)
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xB3FFFFFF)),
                    ),
                    if (isCollapsed && item.badgeCount != null && item.badgeCount! > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.error : AppColors.warning,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBackground : Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? (isDark ? AppColors.darkPrimary : Colors.white)
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xB3FFFFFF)),
                      ),
                    ),
                  ),
                  if (item.badgeCount != null && item.badgeCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.error : AppColors.warning,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.badgeCount! > 9 ? '9+' : '${item.badgeCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildCollapseToggle(bool isExpanded, bool isDark) {
    return InkWell(
      onTap: () {
        final willCollapse = !_sidebarCollapsed;
        if (willCollapse) {
          // Collapsing: switch content first, then animate width
          setState(() {
            _contentExpanded = false;
            _sidebarCollapsed = true;
          });
        } else {
          // Expanding: animate width first, then switch content
          setState(() {
            _sidebarCollapsed = false;
          });
          Future.delayed(const Duration(milliseconds: 260), () {
            if (mounted) {
              setState(() {
                _contentExpanded = true;
              });
            }
          });
        }
      },
      child: Container(
        height: AppDimensions.headerHeight,
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? AppDimensions.lg : 0,
        ),
        child: Row(
          mainAxisAlignment: isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_left
                  : Icons.keyboard_arrow_right,
              size: 20,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : const Color(0xB3FFFFFF),
            ),
            if (isExpanded) ...[
              const SizedBox(width: AppDimensions.md),
              Text(
                'Collapse',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : const Color(0xB3FFFFFF),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── HEADER ──
  // ══════════════════════════════════════════
  Widget _buildHeader(
      BuildContext context, String title, bool isMobile, bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isMobile ? 14 : 6,
          sigmaY: isMobile ? 14 : 6,
        ),
        child: Container(
          height: AppDimensions.headerHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppDimensions.lg : AppDimensions.xl,
          ),              decoration: BoxDecoration(
            color: isDark
                ? AppColors.glassDark
                : AppColors.darkBackground,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.darkBorder,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    size: 24,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _drawerFadeController.forward();
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              if (isMobile) const SizedBox(width: AppDimensions.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // ── Theme Toggle ──
              _buildThemeToggle(context, isDark),
              const SizedBox(width: AppDimensions.md),
              // ── Notification Bell ──
              _buildHeaderIcon(
                icon: Icons.notifications_outlined,
                badge: _getNavBadgeCount('/notifications'),
                onTap: () => context.go('/notifications'),
                isDark: isDark,
              ),

            ],
          ),
        ),
      ),
    );
  }

  void _updateMobileNavIndex(String location) {
    for (int i = 0; i < _mobileNavItems.length; i++) {
      if (location.startsWith(_mobileNavItems[i].route)) {
        if (_mobileNavIndex != i) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _mobileNavIndex = i);
              _animatePillTo(i);
            }
          });
        }
        return;
      }
    }
  }

  void _animatePillTo(int index) {
    if (_pillController == null) return;
    final row = _navRowKey.currentContext?.findRenderObject() as RenderBox?;
    if (row == null) return;
    final rowWidth = row.size.width;
    _pillItemWidth = rowWidth / _mobileNavItems.length;
    final targetCenter = _pillItemWidth * index + _pillItemWidth / 2;

    _pillStart = Offset(_pillTarget.dx, 0);
    _pillTarget = Offset(targetCenter, 0);

    _pillAnimation = Tween<Offset>(
      begin: _pillStart,
      end: _pillTarget,
    ).animate(CurvedAnimation(
      parent: _pillController!,
      curve: Curves.easeOutCubic,
    ));
    _pillController!.forward(from: 0);
  }

  /// Returns the number of unread items for a given nav route.
  int _getNavBadgeCount(String route) {
    switch (route) {
      case '/notifications':
        try {
          final count = context.read<NotificationsProvider>().unreadCount;
          return count;
        } catch (_) {
          return 0;
        }
      case '/orders':
        try {
          final count = context.read<OrdersProvider>().pendingCount;
          return count;
        } catch (_) {
          return 0;
        }
      default:
        return 0;
    }
  }

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    final themeProvider = context.read<ThemeProvider>();

    // Determine which icon to show based on current mode
    IconData icon;
    String tooltip;
    switch (themeProvider.themeMode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto_outlined;
        tooltip = 'System theme';
        break;
      case ThemeMode.light:
        icon = Icons.light_mode_outlined;
        tooltip = 'Light theme';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode_outlined;
        tooltip = 'Dark theme';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: themeProvider.toggleTheme,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : const Color(0x26FFFFFF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    int? badge,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Stack(
        children: [
          Container(
            width: 48,
            height: 48,              decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : const Color(0x26FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : Colors.white,
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════


  // ══════════════════════════════════════════
  // ── LOGOUT CONFIRMATION ──
  // ══════════════════════════════════════════
  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout,
                size: 20,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.lg,
                vertical: AppDimensions.md,
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // Account avatar — the store photo layered over a person/initials fallback
  // that shows while the image loads or if it fails.
  Widget _buildAccountAvatar({double size = 36, String? fallbackLabel}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: fallbackLabel != null
                ? Text(
                    fallbackLabel,
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_outline, size: 20, color: Colors.white),
          ),
          ClipOval(
            child: Image.asset(
              MockImages.storeLogo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── MY ACCOUNT SECTION ──
  // ══════════════════════════════════════════
  Widget _buildMyAccountSection(bool isDark, bool isCollapsed) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'settings':
            context.go('/settings');
            break;
          case 'logout':
            _showLogoutConfirmation(context);
            break;
        }
      },
      offset: const Offset(0, -60),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'header',
          enabled: false,
          child: Row(
            children: [
              _buildAccountAvatar(size: 32, fallbackLabel: 'FA'),
              const SizedBox(width: AppDimensions.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm Fresh Ltd',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Vendor',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.md),
              Text(
                'View Profile',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.md),
              Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                size: 20,
                color: AppColors.error,
              ),
              const SizedBox(width: AppDimensions.md),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.all(isCollapsed ? AppDimensions.xs : AppDimensions.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: isCollapsed
            ? _buildAccountAvatar()
            : Row(
          children: [
            _buildAccountAvatar(),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'My Account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Farm Fresh Ltd',
                    style: TextStyle(
                      fontSize: 11,
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

  // ══════════════════════════════════════════
  // ── MOBILE BOTTOM NAV (Floating Dock) ──
  // ══════════════════════════════════════════
  Widget _buildBottomNav(BuildContext context, String location, bool isDark) {
    final accentColor = AppColors.primary;
    final activeContentColor = Colors.white;
    final inactiveColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final pillBgColor = AppColors.primary;

    // Trigger initial pill position after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pillTarget == Offset.zero && _pillItemWidth == 0) {
        _animatePillTo(_mobileNavIndex);
      }
    });

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppDimensions.lg,
          right: AppDimensions.lg,
          bottom: AppDimensions.xs,
        ),
        child: ClipRect(
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.5)
                  : AppColors.primary.withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: BackdropFilter(
              filter: ImageFilter.compose(
                outer: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                inner: ImageFilter.matrix((Matrix4.identity()..setEntry(1, 1, 1.06)..setEntry(0, 1, 0.008)).storage),
              ),
              child: Container(
                color: isDark
                    ? AppColors.glassDark
                    : AppColors.glassLight,
                child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                child: Stack(
                  children: [
                    // ── Sliding highlight pill ──
                    AnimatedBuilder(
                      animation: _pillController ?? AlwaysStoppedAnimation(Offset.zero),
                      builder: (context, _) {
                        final offset = _pillAnimation.value;
                        if (_pillItemWidth == 0) return const SizedBox.shrink();
                        return Positioned(
                          left: offset.dx - _pillItemWidth / 2,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: _pillItemWidth,
                            decoration: BoxDecoration(
                              color: pillBgColor,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            ),
                          ),
                        );
                      },
                    ),
                    // ── Nav items ──
                    Row(
                      key: _navRowKey,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _mobileNavItems.asMap().entries.map((entry) {
                        final item = entry.value;
                        final isSelected = location.startsWith(item.route);
                        final badgeCount = _getNavBadgeCount(item.route);

                        return Expanded(
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _pressedNavIndex = entry.key),
                            onTapUp: (_) => setState(() => _pressedNavIndex = null),
                            onTapCancel: () => setState(() => _pressedNavIndex = null),
                            child: InkWell(
                              onTap: () {
                                // Haptic feedback on tap
                                HapticFeedback.lightImpact();
                                context.go(item.route);
                              },
                              splashColor: accentColor.withAlpha(30),
                              highlightColor: accentColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                              child: AnimatedScale(
                                scale: _pressedNavIndex == entry.key ? 0.88 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeOutCubic,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppDimensions.xs + 2,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Icon + badge stack
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            child: Icon(
                                              isSelected ? item.activeIcon : item.icon,
                                              key: ValueKey('$isSelected'),
                                              size: 22,
                                              color: isSelected ? activeContentColor : inactiveColor,
                                            ),
                                          ),
                                          // Badge / notification dot
                                          if (badgeCount > 0)
                                            Positioned(
                                              right: -6,
                                              top: -4,
                                              child: Container(
                                                width: badgeCount > 9 ? 18 : 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: isDark ? AppColors.error : AppColors.warning,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    badgeCount > 9 ? '9+' : '$badgeCount',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                      height: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected ? activeContentColor : inactiveColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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

  // ══════════════════════════════════════════
  // ── MOBILE DRAWER ──
  // ══════════════════════════════════════════
  Widget _buildDrawer(BuildContext context, String location, bool isDark) {
    // Use SafeArea to properly constrain drawer content inside the safe
    // region. The Drawer itself keeps a transparent background so it never
    // paints behind the status bar or the gesture / navigation bar.
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: FadeTransition(
          opacity: _drawerFadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.05, 0),
              end: Offset.zero,
            ).animate(_drawerFadeAnimation),
            child: ColoredBox(
              color: isDark ? AppColors.darkSurface : AppColors.darkBackground,
              child: Column(
                children: [
                  _buildLogo(false, isDark),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.primaryLight,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.md,
                      ),
                      child: Column(
                        children: [
                          _buildNavSection(
                            'MANAGE',
                            [
                              _NavItem(Icons.store_outlined, Icons.store, AppStrings.store, '/store'),
                              _NavItem(Icons.help_outline, Icons.help, AppStrings.helpSupport, '/help'),
                              _NavItem(Icons.settings_outlined, Icons.settings, AppStrings.settings, '/settings'),
                            ],
                            location,
                            false,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildMyAccountSection(isDark, false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final int? badgeCount;

  _NavItem(this.icon, this.activeIcon, this.label, this.route, {this.badgeCount});
}

class _MobileNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _MobileNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}