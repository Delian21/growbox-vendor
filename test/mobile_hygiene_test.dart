import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/constants/app_dimensions.dart';
import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/shared/widgets/growbox_status_pill.dart';

import 'load_roboto.dart';

/// Phone-width coverage for the header / subtitle / FAB fixes: 390 and 320px,
/// both themes. Every shell page must render without an overflow, and the
/// specific mobile layouts must hold their shape (one title, stacked status
/// pill, two-line subtitle, FAB above the dock).
const _phoneWidths = [390.0, 320.0];
const _routes = <(String, String)>[
  ('dashboard', '/dashboard'),
  ('products', '/products'),
  ('orders', '/orders'),
  ('order_details', '/orders/%23ORD-001'),
  ('sales', '/sales'),
  ('notifications', '/notifications'),
];

Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 80),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 6),
    );
  } catch (_) {
    // A looping animation never settles; a still frame is enough here.
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _pump(WidgetTester tester, double width, int themeModeIndex) async {
  await tester.runAsync(loadRoboto);
  SharedPreferences.setMockInitialValues({'theme_mode': themeModeIndex});
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MultiProvider(
    providers: growboxProviders(),
    child: const GrowboxApp(),
  ));
  await tester.pump(const Duration(seconds: 1)); // splash
  await _settle(tester);
}

void main() {
  for (final width in _phoneWidths) {
    for (final (themeLabel, themeIndex) in [('light', 1), ('dark', 2)]) {
      testWidgets('$width px, $themeLabel: every shell page is overflow-free',
          (tester) async {
        await _pump(tester, width, themeIndex);
        for (final (name, route) in _routes) {
          appRouter.go(route);
          await _settle(tester);
          final e = tester.takeException();
          expect(e, isNull,
              reason: '$name overflowed at ${width}px in $themeLabel: $e');
        }
      });
    }
  }

  testWidgets('notifications: no repeated title, phone action is icon-only',
      (tester) async {
    await _pump(tester, 390, 1);
    appRouter.go('/notifications');
    await _settle(tester);

    // Exactly one "Notifications": the top bar's. The page used to repeat it.
    expect(find.text('Notifications'), findsOneWidget,
        reason: 'the page must not repeat the top bar title');
    expect(find.text('Mark all read'), findsNothing,
        reason: 'the labelled button is what wrapped the title');
    expect(find.byTooltip('Mark all read'), findsOneWidget,
        reason: 'phones keep the action as an icon');
  });

  testWidgets('order details: full id with the pill on its own line',
      (tester) async {
    await _pump(tester, 390, 1);
    appRouter.go('/orders/%23ORD-001');
    await _settle(tester);

    final title = find.text('Order #ORD-001');
    expect(title, findsOneWidget);
    final titleRect = tester.getRect(title);

    final pills = find.byType(GrowboxStatusPill);
    expect(pills, findsWidgets);
    final pillRects = [
      for (var i = 0; i < pills.evaluate().length; i++)
        tester.getRect(pills.at(i)),
    ];
    expect(
      pillRects.any((r) => r.top >= titleRect.bottom),
      isTrue,
      reason: 'a status pill must sit below the title, not beside it',
    );
    expect(
      pillRects.every((r) => r.left >= titleRect.left),
      isTrue,
      reason: 'no pill may be squeezed to the title left',
    );
  });

  testWidgets('dashboard subtitle is allowed two lines on a phone',
      (tester) async {
    await _pump(tester, 390, 1);
    appRouter.go('/dashboard');
    await _settle(tester);

    final subtitle = tester.widget<Text>(
      find.text("Here's what's happening with your store today"),
    );
    expect(subtitle.maxLines, 2,
        reason: 'a phone subtitle wraps instead of truncating mid-sentence');
  });

  testWidgets('products: FAB and last card clear the floating dock',
      (tester) async {
    await _pump(tester, 390, 1);
    appRouter.go('/products');
    await _settle(tester);

    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(
      fab.bottom,
      lessThanOrEqualTo(800 - AppDimensions.bottomNavHeight),
      reason: 'the FAB must end above the 64px dock',
    );

    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    expect(
      scroll.padding!.resolve(TextDirection.ltr).bottom,
      greaterThanOrEqualTo(72 + AppDimensions.bottomNavHeight),
      reason: 'the list needs bottom room for the FAB and the dock',
    );
  });
}
