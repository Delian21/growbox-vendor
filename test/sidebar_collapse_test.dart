import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/core/constants/app_dimensions.dart';
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
      // Ellipsis (not wrap, not a hard clip): at 2.0x text the label is
      // narrower than the rail, and "Notificatio" cut mid-glyph reads broken.
      expect(text.overflow, TextOverflow.ellipsis,
          reason: '"$label" must ellipsize instead of wrapping');
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

  // The timing constants are read from the widget, not duplicated here, so a
  // future change to the animation immediately shows up in this assertion.
  test('the label delay stays below the width animation', () {
    expect(
      MainLayout.sidebarContentDelay,
      lessThan(MainLayout.sidebarAnimationDuration),
      reason: 'labels must be revealed before the rail stops moving, never '
          'while it is still too narrow',
    );
  });

  testWidgets('collapsed rail centres a smaller logo mark without overflow',
      (tester) async {
    await pumpMainLayout(tester);

    // Expanded: the full 52px badge sits inside the rail's lg padding.
    final expanded = tester.getRect(find.byKey(const Key('sidebar-logo-mark')));
    expect(expanded.width, 52, reason: 'expanded keeps the full-size mark');
    expect(expanded.left, AppDimensions.lg,
        reason: 'expanded mark should start at the rail padding, not centred');
    expect(find.text('GROWBOX'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
    // Every frame of the shrink must stay clean, so the 52 → 40 badge and the
    // padding collapse cannot overflow the narrowing rail.
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 60));
      final e = tester.takeException();
      expect(e, isNull, reason: 'logo overflowed on collapse frame $frame: $e');
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'collapsed rail must not overflow');

    final mark = find.byKey(const Key('sidebar-logo-mark'));
    final rect = tester.getRect(mark);
    expect(
      rect.center.dx,
      closeTo(AppDimensions.sidebarCollapsedWidth / 2, 0.5),
      reason: 'logo mark must be horizontally centred in the 72px rail',
    );
    expect(
      rect.width,
      lessThanOrEqualTo(AppDimensions.sidebarCollapsedWidth - 16),
      reason: 'the mark must keep at least 8px of margin on each side',
    );
    expect(find.text('GROWBOX'), findsNothing,
        reason: 'collapsed rail shows the mark only, with no wordmark');
  });

  // Emulated accessibility text sizes — the cases where the wordmark, the nav
  // rows and the account strip get more text than the rail has room for.
  // 2.0 is the platform maximum on Android/iOS and the one that used to break.
  for (final scale in [1.5, 2.0]) {
    testWidgets('textScaler $scale: collapsing and expanding never overflow',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpMainLayout(tester);
      final atRest = tester.takeException();
      expect(atRest, isNull,
          reason: 'no overflow at rest, ${scale}x text: $atRest');

      for (var cycle = 0; cycle < 2; cycle++) {
        await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
        for (var frame = 0; frame < 5; frame++) {
          await tester.pump(const Duration(milliseconds: 60));
          final e = tester.takeException();
          expect(e, isNull,
              reason: 'collapse frame $frame overflowed at ${scale}x: $e');
        }
        await tester.pumpAndSettle();
        final collapsed = tester.takeException();
        expect(collapsed, isNull,
            reason: 'collapse settled state overflowed at ${scale}x: $collapsed');

        await tester.tap(find.byIcon(Icons.keyboard_arrow_right));
        for (var frame = 0; frame < 5; frame++) {
          await tester.pump(const Duration(milliseconds: 60));
          final e = tester.takeException();
          expect(e, isNull,
              reason: 'expand frame $frame overflowed at ${scale}x: $e');
        }
        await tester.pumpAndSettle();
        final expanded = tester.takeException();
        expect(expanded, isNull,
            reason: 'expand settled state overflowed at ${scale}x: $expanded');
      }
    });
  }
}
