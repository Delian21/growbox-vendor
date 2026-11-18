import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/providers/orders_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/data/models/order.dart';
import 'package:growbox_vendor/features/orders/orders_screen.dart';

import 'load_roboto.dart';

/// Coverage for the rejection-recovery pass:
///  1. The explicit transition table: only the listed moves succeed, and a
///     refused move changes nothing and reports why.
///  2. Reject → Undo returns the order to Pending and the counts follow.
///  3. Bulk reject → Undo restores every order.
///  4. Restore is available for 24h after an order was created, then final.
///  5. A forced failure on Undo shows the inline error + Retry, and the retry
///     restores the order.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Order orderWith(String id, OrderStatus status, {DateTime? createdAt}) => Order(
        id: id,
        customerName: 'Customer $id',
        customerPhone: '0700000000',
        items: [
          OrderItem(
            productId: 'p1',
            productName: 'Tomatoes',
            quantity: 1,
            price: 10,
          ),
        ],
        status: status,
        createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
      );

  // ── 1. The table ─────────────────────────────────────────────────────

  test('every allowed transition succeeds and every other one is refused',
      () async {
    for (final from in OrderStatus.values) {
      for (final to in OrderStatus.values) {
        SharedPreferences.setMockInitialValues({});
        final provider = OrdersProvider(
          initialOrders: [orderWith('#T', from)],
        );
        provider.debugChangeDelay = const Duration(milliseconds: 1);
        await pumpEventQueue();

        final allowed = OrdersProvider.canTransition(from, to);
        final ok = await provider.updateOrderStatus('#T', to);

        expect(ok, allowed,
            reason: '${from.name} → ${to.name} should be '
                '${allowed ? 'allowed' : 'refused'}');
        expect(provider.getOrderById('#T')!.status,
            allowed ? to : from,
            reason: '${from.name} → ${to.name} status');
        if (!allowed) {
          expect(provider.rowState('#T'), OrderRowState.failed);
          expect(provider.rowError('#T'),
              contains("can't move to"));
          // Nothing to retry — the move is simply not part of the workflow.
          expect(provider.canRetry('#T'), isFalse);
        }
      }
    }
  });

  test('the table covers every status and both terminals have no exits', () {
    for (final status in OrderStatus.values) {
      expect(OrdersProvider.transitions.containsKey(status), isTrue);
    }
    expect(OrdersProvider.transitions[OrderStatus.completed], isEmpty);
    expect(OrdersProvider.transitions[OrderStatus.cancelled], isEmpty);
  });

  // ── 2. Reject → Undo ─────────────────────────────────────────────────

  test('restore returns a rejected order to its previous status, reason gone',
      () async {
    SharedPreferences.setMockInitialValues({});
    final provider = OrdersProvider(
      initialOrders: [orderWith('#R1', OrderStatus.pending)],
    );
    provider.debugChangeDelay = const Duration(milliseconds: 1);
    await pumpEventQueue();

    expect(await provider.rejectOrders(['#R1'], notes: 'Wrong item'), 1);
    expect(provider.getOrderById('#R1')!.status, OrderStatus.cancelled);
    expect(provider.getOrderById('#R1')!.notes, 'Wrong item');
    expect(provider.pendingCount, 0);

    expect(await provider.restoreOrders(['#R1']), 1);
    expect(provider.getOrderById('#R1')!.status, OrderStatus.pending);
    expect(provider.getOrderById('#R1')!.notes, isNull);
    expect(provider.pendingCount, 1);
    expect(provider.countFor(OrderStatus.cancelled), 0);
  });

  test('bulk reject of 3 then Undo restores all 3', () async {
    SharedPreferences.setMockInitialValues({});
    final ids = ['#B1', '#B2', '#B3'];
    final provider = OrdersProvider(
      initialOrders: ids.map((id) => orderWith(id, OrderStatus.pending)).toList(),
    );
    provider.debugChangeDelay = const Duration(milliseconds: 1);
    await pumpEventQueue();

    expect(await provider.rejectOrders(ids), 3);
    for (final id in ids) {
      expect(provider.getOrderById(id)!.status, OrderStatus.cancelled);
    }

    expect(await provider.restoreOrders(ids), 3);
    for (final id in ids) {
      expect(provider.getOrderById(id)!.status, OrderStatus.pending);
      expect(provider.rowState(id), OrderRowState.idle);
    }
    expect(provider.countFor(OrderStatus.pending), 3);
  });

  test('a restore to a pre-cancel status is remembered (not always Pending)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final provider = OrdersProvider(
      initialOrders: [orderWith('#P1', OrderStatus.preparing)],
    );
    provider.debugChangeDelay = const Duration(milliseconds: 1);
    await pumpEventQueue();

    expect(await provider.rejectOrders(['#P1']), 1);
    expect(provider.restoreTargetFor('#P1'), OrderStatus.preparing);
    expect(await provider.restoreOrders(['#P1']), 1);
    expect(provider.getOrderById('#P1')!.status, OrderStatus.preparing);
  });

  // ── 3. Restore window ────────────────────────────────────────────────

  test('restore works inside 24h and is refused after', () async {
    SharedPreferences.setMockInitialValues({});
    final recent = orderWith('#N1', OrderStatus.cancelled,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)));
    final old = orderWith('#N2', OrderStatus.cancelled,
        createdAt: DateTime.now().subtract(const Duration(hours: 30)));
    final provider = OrdersProvider(initialOrders: [recent, old]);
    provider.debugChangeDelay = const Duration(milliseconds: 1);
    await pumpEventQueue();

    expect(provider.canRestore(recent), isTrue);
    expect(provider.canRestore(old), isFalse);

    // Only the recent one is restored; the old rejection stays final.
    expect(await provider.restoreOrders(['#N1', '#N2']), 1);
    expect(provider.getOrderById('#N1')!.status, OrderStatus.pending);
    expect(provider.getOrderById('#N2')!.status, OrderStatus.cancelled);
  });

  // ── 4. Undo can fail ─────────────────────────────────────────────────

  test('a failed restore marks the row failed, and Retry restores it',
      () async {
    SharedPreferences.setMockInitialValues({});
    final provider = OrdersProvider(
      initialOrders: [orderWith('#F1', OrderStatus.pending)],
    );
    provider.debugChangeDelay = const Duration(milliseconds: 1);
    await pumpEventQueue();

    await provider.rejectOrders(['#F1']);
    expect(provider.getOrderById('#F1')!.status, OrderStatus.cancelled);

    provider.debugFailNext = true;
    expect(await provider.restoreOrders(['#F1']), 0);
    // Rolled back: still cancelled, but marked with an inline reason.
    expect(provider.getOrderById('#F1')!.status, OrderStatus.cancelled);
    expect(provider.rowState('#F1'), OrderRowState.failed);
    expect(provider.isRestoringRow('#F1'), isTrue);
    expect(provider.canRetry('#F1'), isTrue);

    expect(await provider.retryOrderChange('#F1'), isTrue);
    expect(provider.getOrderById('#F1')!.status, OrderStatus.pending);
    expect(provider.rowState('#F1'), OrderRowState.idle);
  });

  // ── 5. Widget: Undo bar, counts, badge source, failed undo ───────────

  Future<OrdersProvider> pumpOrders(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
    int themeModeIndex = 1,
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
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    appRouter.go('/orders');
    await tester.pumpAndSettle();

    final provider = Provider.of<OrdersProvider>(
      tester.element(find.byType(OrdersScreen)),
      listen: false,
    );
    provider.debugChangeDelay = const Duration(milliseconds: 20);
    return provider;
  }

  testWidgets('reject → Undo returns the order to Pending and counts follow',
      (tester) async {
    final provider = await pumpOrders(tester);
    expect(provider.pendingCount, 2); // #ORD-001, #ORD-007

    await tester.tap(find.text('Reject').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Reject Order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(provider.getOrderById('#ORD-001')!.status, OrderStatus.cancelled);
    expect(provider.pendingCount, 1);
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // A failed undo surfaces inline instead of doing nothing.
    provider.debugFailNext = true;
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(provider.getOrderById('#ORD-001')!.status, OrderStatus.cancelled);
    expect(find.text('Retry'), findsOneWidget);

    // Retry restores it: Pending again, chip and badge source follow.
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(provider.getOrderById('#ORD-001')!.status, OrderStatus.pending);
    expect(provider.pendingCount, 2); // feeds the sidebar Orders badge
    expect(find.text('Pending (2)'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  for (final width in [320.0, 390.0]) {
    for (final themeIndex in [0, 1]) {
      testWidgets(
          'Cancelled tab offers Restore inside 24h '
          '(${width.toInt()}px theme $themeIndex)', (tester) async {
        final provider = await pumpOrders(
          tester,
          size: Size(width, 800),
          themeModeIndex: themeIndex,
        );

        // Filter through the provider: the chip strip scrolls horizontally and
        // the Cancelled chip can sit off-screen at 320px.
        provider.setFilter(OrderStatus.cancelled);
        await tester.pumpAndSettle();

        // The seeded #ORD-005 was cancelled two hours ago.
        expect(provider.canRestore(provider.getOrderById('#ORD-005')!), isTrue);
        expect(find.text('Restore'), findsOneWidget);

        await tester.tap(find.text('Restore'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(provider.getOrderById('#ORD-005')!.status, OrderStatus.pending);
        expect(find.text('Restore'), findsNothing);
      });
    }
  }
}
