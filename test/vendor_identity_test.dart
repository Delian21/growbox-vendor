import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/providers/auth_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/shared/layouts/main_layout.dart';

/// Pumps the real app shell at desktop width and lands on /dashboard, where
/// the sidebar's My Account strip is visible.
Future<AuthProvider> pumpShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'theme_mode': 1});
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MultiProvider(
    providers: growboxProviders(),
    child: const GrowboxApp(),
  ));

  // Splash (1s) → login, then straight into the shell, as the other app tests
  // do; the router does not gate this route on _isAuthenticated.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  appRouter.go('/dashboard');
  await tester.pumpAndSettle();

  return Provider.of<AuthProvider>(
    tester.element(find.byType(MainLayout)),
    listen: false,
  );
}

/// Runs the mock login, advancing the clock past its 1s latency.
Future<void> signIn(WidgetTester tester, AuthProvider auth) async {
  final pending = auth.login('vendor@example.com', 'secret123');
  await tester.pump(const Duration(seconds: 1));
  await pending;
  await tester.pumpAndSettle();
}

void main() {
  test('initials take the first letters of the first two words, uppercase', () {
    // Two words → two initials (AuthProvider's real business name).
    expect(MainLayout.vendorInitials('Farm Fresh Enterprises'), 'FF');
    // One word → its single initial.
    expect(MainLayout.vendorInitials('Growbox'), 'G');
    // Empty / whitespace / missing → a neutral fallback, never a blank avatar.
    expect(MainLayout.vendorInitials(''), '?');
    expect(MainLayout.vendorInitials('   '), '?');
    expect(MainLayout.vendorInitials(null), '?');
  });

  test('display name falls back to a neutral placeholder', () {
    expect(MainLayout.vendorDisplayName('Farm Fresh Enterprises'),
        'Farm Fresh Enterprises');
    expect(MainLayout.vendorDisplayName(null), 'Your store');
    expect(MainLayout.vendorDisplayName('  '), 'Your store');
  });

  testWidgets('the strip shows the provider name, not the old hardcoded one',
      (tester) async {
    final auth = await pumpShell(tester);
    await signIn(tester, auth);

    expect(find.text('Farm Fresh Enterprises'), findsOneWidget,
        reason: 'the strip reads AuthProvider.vendorName');
    expect(find.text('Farm Fresh Ltd'), findsNothing,
        reason: 'the hardcoded placeholder must be gone');
  });

  testWidgets('a missing name shows the placeholder, not a blank line',
      (tester) async {
    await pumpShell(tester); // never signed in → vendorName is null

    expect(find.text('Your store'), findsOneWidget);
    expect(find.text('Farm Fresh Ltd'), findsNothing);
  });

  testWidgets('a long name stays on one line and never overflows', (tester) async {
    // The rail is a fixed 260px whatever the window does, so the strip's text
    // column stays ~142px — narrower than the 21-character mock business
    // name, which is exactly what forces the ellipsis path.
    final auth = await pumpShell(tester);
    await signIn(tester, auth);

    expect(tester.takeException(), isNull,
        reason: 'the strip must ellipsize, not throw a RenderFlex overflow');

    final name = find.text('Farm Fresh Enterprises');
    expect(name, findsOneWidget);
    expect(tester.getSize(name).height, lessThan(20),
        reason: 'maxLines: 1 keeps the name out of a second line');
  });

  testWidgets('the account popup shows the same name without overflowing',
      (tester) async {
    final auth = await pumpShell(tester);
    await signIn(tester, auth);

    await tester.tap(find.text('Farm Fresh Enterprises'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'the popup header must ellipsize a long name too');
    // Strip + popup header now both carry the provider's name.
    expect(find.text('Farm Fresh Enterprises'), findsNWidgets(2));
  });
}
