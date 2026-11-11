import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/shared/layouts/main_layout.dart';

/// Nav labels that appear ONLY in the sidebar at /dashboard — "Dashboard"
/// is skipped because the header title repeats it.
const navLabels = ['Products', 'Orders', 'Sales', 'Store', 'Settings'];

/// Pumps [MainLayout] at a desktop width on /dashboard, fully expanded.
Future<void> pumpMainLayout(WidgetTester tester) async {
  // ThemeProvider and StoreProvider read SharedPreferences at startup.
  SharedPreferences.setMockInitialValues({});

  // Desktop width: 1400 >= AppDimensions.tablet (1024), so the rail (not the
  // drawer / bottom nav) is built.
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainLayout(child: SizedBox.expand()),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(MultiProvider(
    providers: growboxProviders(),
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void expectNavLabels({required bool visible}) {
  for (final label in navLabels) {
    expect(
      find.text(label),
      visible ? findsOneWidget : findsNothing,
      reason: 'nav label "$label" should be '
          '${visible ? 'in the tree' : 'out of the tree'}',
    );
  }
}

void main() {
  testWidgets('the FIRST collapse drops nav labels before the width animates',
      (tester) async {
    await pumpMainLayout(tester);
    expectNavLabels(visible: true);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
    await tester.pump(); // new state applied; width animation starts

    // The labels are already gone in this very frame, so a shrinking row can
    // never squeeze them into one letter per line.
    expectNavLabels(visible: false);
    expect(find.text('MAIN'), findsNothing);

    // ...and stay gone part-way through the 250ms width animation.
    await tester.pump(const Duration(milliseconds: 100));
    expectNavLabels(visible: false);

    await tester.pumpAndSettle();
    expectNavLabels(visible: false);
  });

  testWidgets('expanding keeps labels out until the delay has elapsed',
      (tester) async {
    await pumpMainLayout(tester);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
    await tester.pumpAndSettle();
    expectNavLabels(visible: false);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_right));
    await tester.pump();
    expectNavLabels(visible: false);

    // Still inside the 200ms content delay: the width is growing, labels stay
    // out so they cannot wrap on the way out.
    await tester.pump(const Duration(milliseconds: 100));
    expectNavLabels(visible: false);

    // Past the delay the labels come back at full width.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expectNavLabels(visible: true);
  });

  testWidgets('every nav label is single-line so letters can never stack',
      (tester) async {
    await pumpMainLayout(tester);

    for (final label in navLabels) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, 1, reason: '"$label" must cap at one line');
      expect(text.softWrap, isFalse, reason: '"$label" must not wrap');
      expect(text.overflow, TextOverflow.clip,
          reason: '"$label" must clip instead of wrapping');
    }
  });

  testWidgets('three collapse/expand cycles stay correct on the first frame',
      (tester) async {
    await pumpMainLayout(tester);

    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
      await tester.pump();
      expectNavLabels(visible: false);
      await tester.pumpAndSettle();
      expectNavLabels(visible: false);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_right));
      await tester.pump();
      expectNavLabels(visible: false); // width is still growing
      await tester.pumpAndSettle();
      expectNavLabels(visible: true);
    }
  });
}
