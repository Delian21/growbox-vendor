import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/pending_approval_screen.dart';
import '../features/auth/suspended_store_screen.dart';
import '../features/onboarding/business_info_screen.dart';
import '../features/onboarding/contact_details_screen.dart';
import '../features/onboarding/verification_screen.dart';
import '../features/onboarding/onboarding_success_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/products/products_screen.dart';
import '../features/products/product_details_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/orders/order_details_screen.dart';
import '../features/sales/sales_screen.dart';
import '../features/store/store_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/help/help_support_screen.dart';
import '../shared/layouts/main_layout.dart';
import '../features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

// ══════════════════════════════════════════
// ── PAGE TRANSITIONS ──
// ══════════════════════════════════════════

/// Fade + slide up — used for auth screens (login, register)
CustomTransitionPage<void> _fadeSlideUpTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
  );
}

/// Simple cross-fade — used for shell navigation (dashboard, products, etc.)
CustomTransitionPage<void> _fadeTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
  );
}

/// Slide from right — used for detail screens (order details)
CustomTransitionPage<void> _slideFromRightTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
  );
}

/// Slide from right + slight scale — used for onboarding step transitions
CustomTransitionPage<void> _onboardingSlideTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ── Splash ──
    GoRoute(
      path: '/',
      name: 'splash',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ),
    // ── Auth Routes ──
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => _fadeSlideUpTransition(
        context,
        state,
        const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) => _fadeSlideUpTransition(
        context,
        state,
        const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verify-email',
      pageBuilder: (context, state) => _fadeSlideUpTransition(
        context,
        state,
        const VerifyEmailScreen(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      pageBuilder: (context, state) => _fadeSlideUpTransition(
        context,
        state,
        const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      pageBuilder: (context, state) => _fadeSlideUpTransition(
        context,
        state,
        const ResetPasswordScreen(),
      ),
    ),

    // ── Auth Status Routes ──
    GoRoute(
      path: '/pending-approval',
      name: 'pending-approval',
      pageBuilder: (context, state) => _fadeSlideUpTransition(
        context,
        state,
        const PendingApprovalScreen(),
      ),
    ),
    GoRoute(
      path: '/suspended',
      name: 'suspended',
      pageBuilder: (context, state) => _fadeSlideUpTransition(
        context,
        state,
        const SuspendedStoreScreen(),
      ),
    ),

    // ── Onboarding Routes ──
    GoRoute(
      path: '/onboarding/business-info',
      name: 'onboarding-business-info',
      pageBuilder: (context, state) => _onboardingSlideTransition(
        context,
        state,
        const BusinessInfoScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/contact-details',
      name: 'onboarding-contact-details',
      pageBuilder: (context, state) => _onboardingSlideTransition(
        context,
        state,
        const ContactDetailsScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/verification',
      name: 'onboarding-verification',
      pageBuilder: (context, state) => _onboardingSlideTransition(
        context,
        state,
        const VerificationScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/success',
      name: 'onboarding-success',
      pageBuilder: (context, state) => _onboardingSlideTransition(
        context,
        state,
        const OnboardingSuccessScreen(),
      ),
    ),

    // ── Main App (Shell) ──
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          pageBuilder: (context, state) => _fadeTransition(
            context,
            state,
            const DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/products',
          name: 'products',
          pageBuilder: (context, state) => _fadeTransition(
            context,
            state,
            const ProductsScreen(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              name: 'product-details',
              pageBuilder: (context, state) => _slideFromRightTransition(
                context,
                state,
                ProductDetailsScreen(
                  productId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/orders',
          name: 'orders',
          pageBuilder: (context, state) => _fadeTransition(
            context,
            state,
            const OrdersScreen(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              name: 'order-details',
              pageBuilder: (context, state) => _slideFromRightTransition(
                context,
                state,
                OrderDetailsScreen(
                  orderId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/sales',
          name: 'sales',
          pageBuilder: (context, state) => _fadeTransition(
            context,
            state,
            const SalesScreen(),
          ),
        ),
        GoRoute(
          path: '/store',
          name: 'store',
          pageBuilder: (context, state) => _fadeTransition(
            context,
            state,
            const StoreScreen(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          pageBuilder: (context, state) => _fadeTransition(
            context,
            state,
            const NotificationsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => _fadeTransition(
            context,
            state,
            const SettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/help',
          name: 'help',
          pageBuilder: (context, state) => _fadeTransition(
            context,
            state,
            const HelpSupportScreen(),
          ),
        ),
      ],
    ),
  ],
);