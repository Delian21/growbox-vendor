import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/features/auth/login_screen.dart';
import 'package:growbox_vendor/features/splash/splash_screen.dart';

void main() {
  testWidgets('App boots into the splash screen and lands on login',
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

    // Once the 5s splash timer fires, the app routes to the login screen.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Vendor Portal'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}