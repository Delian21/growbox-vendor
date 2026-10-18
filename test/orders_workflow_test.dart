import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/providers/orders_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/data/models/order.dart';
import 'package:growbox_vendor/features/orders/order_details_screen.dart';
import 'package:growbox_vendor/shared/widgets/growbox_button.dart';

import 'load_roboto.dart';

/// Coverage for the orders workflow pass:
///  1. Reject flow — the reason typed in the dialog is stored on the order
///     and rendered on the order details STATUS TIMELINE.
///  2. Bulk accept — ticking pending rows + "Accept selected (n)" accepts
///     them in one action and updates the chip counts.
///  3. Persistence — status + reason are written to SharedPreferences and
///     restored into a fresh provider (page-reload survival).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpOrders(
    WidgetTester tester, {
    int themeModeIndex = 1,
    Size size = const Size(1440, 900),
  }) async {
    await tester.runAsync(loadRoboto);
    SharedPreferences.setMockInitialValues({'theme_mode': themeModeIndex});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go('/orders');
    await tester.pumpAndSettle();
  }

  // ── 1. Rejection reason lands on the details timeline ────────────────

  testWidgets('reject with a reason → details timeline shows it',
      (tester) async {
    await pumpOrders(tester);

    // Reject #ORD-001 — desktop rows render Reject as plain text
    // (GestureDetector), so tap the text itself.
    await tester.tap(find.text('Reject').first);
    await tester.pumpAndSettle();

    // The dialog collects an optional reason.
    expect(find.text('Reject Order'), findsWidgets);
    await tester.enterText(
        find.byType(TextField), 'Out of stock today');
    await tester.tap(find.widgetWithText(TextButton, 'Reject Order'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The row is now cancelled and links to the details page.
    expect(find.text('Cancelled'), findsWidgets);
    await tester.tap(find.text('#ORD-001'));
    await tester.pumpAndSettle();
    expect(find.text('Order #ORD-001'), findsOneWidget);

    // The timeline records the decision and the reason.
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Reason: Out of stock today'), findsOneWidget);
  });

  testWidgets('cancelled order without a reason shows Rejected, no reason line',
      (tester) async {
    await pumpOrders(tester);

    // #ORD-005 is seeded cancelled with no notes.
    await tester.tap(find.text('#ORD-005'));
    await tester.pumpAndSettle();

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.textContaining('Reason:'), findsNothing);
  });

  // ── 2. Bulk accept ───────────────────────────────────────────────────

  testWidgets('ticking pending rows and Accept selected accepts them',
      (tester) async {
    await pumpOrders(tester);

    // The seed data has exactly two pending orders → two checkboxes.
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(2));
    await tester.tap(checkboxes.at(0));
    await tester.pumpAndSettle();
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    expect(find.text('2 pending orders selected'), findsOneWidget);

    await tester.tap(find.widgetWithText(GrowboxButton, 'Accept selected (2)'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Snackbar + chip counts reflect the bulk accept; selection cleared.
    expect(find.text('2 orders accepted'), findsOneWidget);
    expect(find.text('Pending (0)'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('2 pending orders selected'), findsNothing);
  });

  testWidgets('Clear empties the selection without accepting', (tester) async {
    await pumpOrders(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1 pending order selected'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(find.text('1 pending order selected'), findsNothing);
    expect(find.text('Pending (2)'), findsOneWidget);
  });

  // ── 3. Persistence ───────────────────────────────────────────────────

  group('orders persist across reloads', () {
    test('updateOrderStatus writes status + reason to SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final provider = OrdersProvider();

      final ok = await provider.updateOrderStatus(
        '#ORD-005',
        OrderStatus.cancelled,
        notes: 'Duplicate order',
      );
      expect(ok, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString('orders_state')!);
      expect(saved['#ORD-005']['status'], 'cancelled');
      expect(saved['#ORD-005']['notes'], 'Duplicate order');
    });

    test('a fresh provider restores the saved decisions (page reload)',
        () async {
      SharedPreferences.setMockInitialValues({
        'orders_state': jsonEncode({
          '#ORD-004': {'status': 'cancelled', 'notes': 'Restored reason'},
          '#ORD-001': {'status': 'accepted'},
        }),
      });

      final provider = OrdersProvider();
      await pumpEventQueue();

      final restored004 = provider.getOrderById('#ORD-004')!;
      expect(restored004.status, OrderStatus.cancelled);
      expect(restored004.notes, 'Restored reason');

      final restored001 = provider.getOrderById('#ORD-001')!;
      expect(restored001.status, OrderStatus.accepted);
      expect(restored001.notes, isNull);

      // Unlisted orders keep their seed state.
      expect(provider.getOrderById('#ORD-002')!.status, OrderStatus.preparing);
    });

    test('a corrupt store falls back to seed orders', () async {
      SharedPreferences.setMockInitialValues({'orders_state': '{not json'});
      final provider = OrdersProvider();
      await pumpEventQueue();
      expect(provider.totalCount, 7);
      expect(provider.getOrderById('#ORD-004')!.status, OrderStatus.completed);
    });

    test('acceptOrders accepts only pending orders and persists the result',
        () async {
      SharedPreferences.setMockInitialValues({});
      final provider = OrdersProvider();
      await pumpEventQueue();

      // #ORD-004 is completed → skipped; #ORD-001 is pending → accepted.
      final accepted = await provider.acceptOrders(['#ORD-004', '#ORD-001']);
      expect(accepted, 1);
      expect(provider.getOrderById('#ORD-001')!.status, OrderStatus.accepted);
      expect(provider.getOrderById('#ORD-004')!.status, OrderStatus.completed);

      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString('orders_state')!);
      expect(saved['#ORD-001']['status'], 'accepted');
    });

    test('acceptOrders on an empty list is a no-op', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = OrdersProvider();
      await pumpEventQueue();
      expect(await provider.acceptOrders(const []), 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('orders_state'), isNull);
    });
  });

  group('deep links carry #-prefixed order ids', () {
    testWidgets('encoded URL /orders/%23ORD-002 opens that order',
        (tester) async {
      await pumpOrders(tester);

      // An unencoded '#' would make the router treat the rest as a URL
      // fragment and it would silently stay on the list; the encoded id
      // must decode back into the :id path parameter.
      appRouter.go('/orders/${Uri.encodeComponent('#ORD-002')}');
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      expect(find.text('Order #ORD-002'), findsOneWidget);
      expect(find.text('Order not found'), findsNothing);
    });

    testWidgets('mobile card tap opens details for a #-prefixed id',
        (tester) async {
      await pumpOrders(tester, size: const Size(390, 844));

      await tester.ensureVisible(find.text('#ORD-005'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#ORD-005'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      expect(find.text('Order #ORD-005'), findsOneWidget);
      expect(find.text('Order not found'), findsNothing);
    });
  });
}
