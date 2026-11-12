import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/providers/orders_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/constants/app_dimensions.dart';
import 'package:growbox_vendor/data/models/order.dart';
import 'package:growbox_vendor/features/orders/orders_screen.dart';
import 'package:growbox_vendor/shared/widgets/growbox_button.dart';

import 'load_roboto.dart';

/// Coverage for the bulk-order pass:
///  1. The selection bar is pinned above the dock on phones — visible while
///     the list scrolls, covering neither rows nor the nav — and both of its
///     buttons stay fully on screen at 320/360/390px and 1.5–2.0× text, in
///     both themes.
///  2. Bulk Reject confirms first (count in the title, irreversible warning,
///     optional reason) and applies the reason to every selected order.
///  3. Backing out of that dialog changes nothing.
const _widths = [320.0, 360.0, 390.0];
const _scales = [1.5, 2.0];
const _screenHeight = 800.0;

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

Future<void> _pumpOrders(
  WidgetTester tester, {
  required double width,
  required double textScale,
  required int themeModeIndex,
}) async {
  await tester.runAsync(loadRoboto);
  SharedPreferences.setMockInitialValues({'theme_mode': themeModeIndex});
  tester.view.physicalSize = Size(width, _screenHeight);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(MultiProvider(
    providers: growboxProviders(),
    child: const GrowboxApp(),
  ));
  await tester.pump(const Duration(seconds: 5)); // splash
  await _settle(tester);

  appRouter.go('/orders');
  await _settle(tester);
}

/// Ticks both pending orders (index 0 is the select-all control). The pinned
/// phone bar uses the compact count wording; the desktop bar spells it out.
Future<void> _selectTwoPending(WidgetTester tester,
    {bool compact = false}) async {
  final boxes = find.byType(Checkbox);
  expect(boxes, findsNWidgets(3),
      reason: 'select-all plus one tick per pending order');
  for (final index in [1, 2]) {
    await tester.ensureVisible(boxes.at(index));
    await tester.pumpAndSettle();
    await tester.tap(boxes.at(index));
    await tester.pumpAndSettle();
  }
  expect(
      find.text(compact
          ? '2 orders selected'
          : '2 pending orders selected'),
      findsOneWidget);
}

OrdersProvider _provider(WidgetTester tester) =>
    tester.element(find.byType(OrdersScreen)).read<OrdersProvider>();

void _expectFullyOnScreen(
    WidgetTester tester, Finder finder, String label, double width) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0),
      reason: '$label hangs off the left edge');
  expect(rect.right, lessThanOrEqualTo(width),
      reason: '$label hangs off the right edge');
  expect(rect.top, greaterThanOrEqualTo(0),
      reason: '$label starts above the viewport');
  expect(rect.bottom, lessThanOrEqualTo(_screenHeight),
      reason: '$label runs past the bottom of the screen');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. Pinned bulk bar on phones ─────────────────────────────────────
  for (final width in _widths) {
    for (final scale in _scales) {
      for (final (themeLabel, themeIndex) in [('light', 1), ('dark', 2)]) {
        testWidgets(
            'bulk bar ${width.toInt()}px @ ${scale}x, $themeLabel: pinned, '
            'on-screen, no overflow', (tester) async {
          await _pumpOrders(tester,
              width: width, textScale: scale, themeModeIndex: themeIndex);
          await _selectTwoPending(tester, compact: true);

          final accept = find.widgetWithText(GrowboxButton, 'Accept selected (2)');
          final reject = find.widgetWithText(GrowboxButton, 'Reject selected (2)');
          expect(accept, findsOneWidget);
          expect(reject, findsOneWidget);
          expect(tester.takeException(), isNull,
              reason: 'bulk bar overflowed at ${width}px @ ${scale}x, $themeLabel');

          _expectFullyOnScreen(tester, accept, 'Accept selected', width);
          _expectFullyOnScreen(tester, reject, 'Reject selected', width);

          // Sits above the floating dock, never on top of it.
          final dockTop = _screenHeight - AppDimensions.bottomNavHeight;
          expect(tester.getRect(reject).bottom, lessThanOrEqualTo(dockTop),
              reason: 'the bar must sit above the bottom nav');

          // The scroll viewport ends where the bar starts → rows are never
          // underneath it.
          final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
          final barTop = tester.getRect(accept).top;
          expect(viewport.bottom, lessThanOrEqualTo(barTop),
              reason: 'order rows must not sit under the pinned bar');

          // Pinned: scrolling the list leaves the bar exactly where it was.
          await tester.drag(
              find.byType(SingleChildScrollView).first, const Offset(0, -180));
          await tester.pumpAndSettle();
          expect(accept, findsOneWidget, reason: 'bar stays visible on scroll');
          expect(tester.getRect(accept).top, barTop,
              reason: 'the bar must not scroll with the list');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  // ── 2. Bulk Reject confirms, then applies the reason ─────────────────
  testWidgets('bulk Reject asks first and applies the reason to every order',
      (tester) async {
    await _pumpOrders(tester, width: 1440, textScale: 1.0, themeModeIndex: 1);
    await _selectTwoPending(tester);

    final provider = _provider(tester);
    final selectedIds = provider.orders
        .where((o) => o.status == OrderStatus.pending)
        .map((o) => o.id)
        .toList();
    expect(selectedIds, hasLength(2));

    await tester.tap(find.widgetWithText(GrowboxButton, 'Reject selected (2)'));
    await tester.pumpAndSettle();

    // Same confirmation as the single-row Reject, with the count in the title.
    expect(find.text('Reject 2 orders?'), findsOneWidget);
    expect(find.textContaining('This action cannot be undone'), findsOneWidget);
    expect(find.text('Reason (optional)'), findsOneWidget);
    expect(
        provider.orders.where((o) => o.status == OrderStatus.pending).length, 2,
        reason: 'opening the dialog must not cancel anything');

    await tester.enterText(find.byType(TextField), 'Out of stock today');
    await tester.tap(find.widgetWithText(TextButton, 'Reject all'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tester.pumpAndSettle();

    expect(find.text('2 orders rejected'), findsOneWidget);
    for (final id in selectedIds) {
      final order = provider.orders.firstWhere((o) => o.id == id);
      expect(order.status, OrderStatus.cancelled,
          reason: '$id should be cancelled');
      expect(order.notes, 'Out of stock today',
          reason: 'the dialog reason applies to every selected order');
    }
    expect(find.text('Pending (0)'), findsOneWidget);
  });

  // ── 3. Cancelling the dialog changes nothing ─────────────────────────
  testWidgets('cancelling the bulk Reject dialog changes nothing',
      (tester) async {
    await _pumpOrders(tester, width: 1440, textScale: 1.0, themeModeIndex: 1);
    await _selectTwoPending(tester);

    final provider = _provider(tester);

    await tester.tap(find.widgetWithText(GrowboxButton, 'Reject selected (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Reject 2 orders?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Keep Order'));
    await tester.pumpAndSettle();

    expect(find.text('Reject 2 orders?'), findsNothing);
    expect(
        provider.orders.where((o) => o.status == OrderStatus.pending).length, 2,
        reason: 'no order may change status when the dialog is dismissed');
    expect(find.text('Pending (2)'), findsOneWidget);
    expect(find.text('2 pending orders selected'), findsOneWidget,
        reason: 'the selection survives a cancelled confirmation');
    expect(find.textContaining('rejected'), findsNothing);
  });
}
