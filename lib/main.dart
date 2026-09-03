import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'app/theme.dart';
import 'app/theme_provider.dart';
import 'app/router.dart';
import 'app/providers/auth_provider.dart';
import 'app/providers/products_provider.dart';
import 'app/providers/orders_provider.dart';
import 'app/providers/sales_provider.dart';
import 'app/providers/store_provider.dart';
import 'app/providers/notifications_provider.dart';

/// App-wide provider wiring, shared by [main] and the widget tests so the
/// test harness exercises the exact same dependency graph as production.
List<SingleChildWidget> growboxProviders() => [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ProductsProvider()),
      ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ChangeNotifierProvider(create: (_) => SalesProvider()),
      ChangeNotifierProvider(create: (_) => StoreProvider()..loadFromPrefs()),
      ChangeNotifierProvider(create: (_) => NotificationsProvider()),
    ];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(
    MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ),
  );
}

class GrowboxApp extends StatelessWidget {
  const GrowboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'GROWBOX Vendor',
      debugShowCheckedModeBanner: false,
      theme: GrowboxTheme.lightTheme,
      darkTheme: GrowboxTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return RootPopScope(child: child ?? const SizedBox.shrink());
      },
      routerConfig: appRouter,
    );
  }
}

class RootPopScope extends StatefulWidget {
  final Widget child;
  const RootPopScope({super.key, required this.child});

  @override
  State<RootPopScope> createState() => _RootPopScopeState();
}

class _RootPopScopeState extends State<RootPopScope> {
  DateTime? _lastBackPress;

  static const _shellRoutes = [
    '/dashboard',
    '/products',
    '/orders',
    '/sales',
    '/store',
    '/notifications',
    '/settings',
    '/help',
  ];

  static const _onboardingRoutes = [
    '/onboarding/business-info',
    '/onboarding/contact-details',
    '/onboarding/verification',
    '/onboarding/success',
  ];

  bool _isSubRoute(String location, List<String> routes) {
    return routes.any((r) => location.startsWith(r));
  }

  Future<bool> _onWillPop() async {
    final location = GoRouterState.of(context).uri.toString();

    if (_isSubRoute(location, _shellRoutes)) {
      if (location != '/dashboard') {
        context.go('/dashboard');
      } else {
        return await _showExitDialog();
      }
      return false;
    }

    if (location.contains('/orders/') && location != '/orders') {
      context.go('/orders');
      return false;
    }

    if (_isSubRoute(location, _onboardingRoutes)) {
      if (location == '/onboarding/contact-details') {
        context.go('/onboarding/business-info');
      } else if (location == '/onboarding/verification') {
        context.go('/onboarding/contact-details');
      } else if (location == '/onboarding/success') {
        context.go('/onboarding/verification');
      } else {
        context.go('/login');
      }
      return false;
    }

    if (location == '/register' || location == '/forgot-password') {
      context.go('/login');
      return false;
    }
    if (location == '/verify-email') {
      context.go('/login');
      return false;
    }
    if (location == '/reset-password') {
      context.go('/forgot-password');
      return false;
    }
    if (location == '/pending-approval' || location == '/suspended') {
      context.go('/login');
      return false;
    }

    return await _showExitDialog();
  }

  Future<bool> _showExitDialog() async {
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      return true;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }
}