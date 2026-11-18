import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/features/auth/login_screen.dart';
import 'package:growbox_vendor/features/splash/splash_screen.dart';

void main() {
  testWidgets('App boots into the splash screen and reaches login within 1s',
      (WidgetTester tester) async {
    // SharedPreferences is used by ThemeProvider and StoreProvider at
    // startup; provide an in-memory store so no platform channel is needed.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));

    // The splash screen is shown first.
    expect(find.byType(SplashScreen), findsOneWidget);

    // It holds for the 1s minimum, so the logo animation is not cut off...
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(SplashScreen), findsOneWidget);

    // ...and the app leaves for login as soon as that minimum is up.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Vendor Portal'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('Splash stays up for startup work that outlasts the minimum',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          // Real startup work taking longer than the 1s minimum.
          builder: (_, _) => SplashScreen(
            startup: () => Future<void>.delayed(const Duration(seconds: 3)),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(SplashScreen), findsOneWidget);

    // The minimum has elapsed, but the work has not finished: still here.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    // The work finishes, and only then does the app move on.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}
