import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/providers/orders_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/data/models/order.dart';
import 'package:growbox_vendor/features/orders/orders_screen.dart';
import 'package:growbox_vendor/shared/widgets/growbox_button.dart';
import 'package:growbox_vendor/shared/widgets/growbox_table_action.dart';
import 'package:growbox_vendor/shared/widgets/shimmer_loader.dart';

import 'load_roboto.dart';

/// Coverage for the per-row order status pass:
///  1. A change is per-row: pending shows only on that row, the list never
///     falls back to the skeleton, and every other row stays interactive.
///  2. Optimistic update + rollback: a failed change restores the old status,
///     shows an inline error with Retry, and Retry succeeds.
///  3. Batched accept/reject costs ONE simulated delay for the whole set.
///  4. A partially failed batch keeps the orders that did change.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Order pendingOrder(String id) => Order(
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
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      );

  // ── 1. Provider: optimistic change, rollback, retry ─────────────────

  group('per-row order change state', () {
    test('a failed change rolls back, marks the row, and Retry succeeds',
        () async {
      SharedPreferences.setMockInitialValues({});
      final provider = OrdersProvider(initialOrders: [pendingOrder('#A1')]);
      provider.debugChangeDelay = const Duration(milliseconds: 20);
      await pumpEventQueue();

      provider.debugFailNext = true;
      final ok =
          await provider.updateOrderStatus('#A1', OrderStatus.accepted);

      expect(ok, isFalse);
      // Rolled back, not left showing the optimistic status.
      expect(provider.getOrderById('#A1')!.status, OrderStatus.pending);
      expect(provider.rowState('#A1'), OrderRowState.failed);
      expect(provider.rowError('#A1'), isNotNull);
      // The failed state remembers what was asked for.
      expect(provider.rowTarget('#A1'), OrderStatus.accepted);

      final retried = await provider.retryOrderChange('#A1');
      expect(retried, isTrue);
      expect(provider.getOrderById('#A1')!.status, OrderStatus.accepted);
      expect(provider.rowState('#A1'), OrderRowState.idle);
      expect(provider.rowError('#A1'), isNull);
    });

    test('rejecting 20 orders runs the delay and the save once', () async {
      SharedPreferences.setMockInitialValues({});
      final ids = List.generate(20, (i) => '#B$i');
      final provider =
          OrdersProvider(initialOrders: ids.map(pendingOrder).toList());
      provider.debugChangeDelay = const Duration(milliseconds: 10);
      await pumpEventQueue();

      // Count the work directly instead of timing the wall clock: a batch of
      // 20 must share ONE delay and ONE save.
      provider.debugDelayCount = 0;
      provider.debugSaveCount = 0;

      final rejected = await provider.rejectOrders(ids, notes: 'Sold out');

      expect(rejected, 20);
      expect(provider.debugDelayCount, 1,
          reason: 'the whole batch shares one simulated delay');
      expect(provider.debugSaveCount, 1,
          reason: 'the whole batch is persisted once');
      for (final id in ids) {
        expect(provider.getOrderById(id)!.status, OrderStatus.cancelled);
        expect(provider.getOrderById(id)!.notes, 'Sold out');
        expect(provider.rowState(id), OrderRowState.idle);
      }
    });

    test('one failure in a batch leaves the other orders changed', () async {
      SharedPreferences.setMockInitialValues({});
      final ids = List.generate(5, (i) => '#C$i');
      final provider =
          OrdersProvider(initialOrders: ids.map(pendingOrder).toList());
      provider.debugChangeDelay = const Duration(milliseconds: 20);
      await pumpEventQueue();

      provider.debugFailOrderIds.add('#C2');
      final rejected = await provider.rejectOrders(ids);

      expect(rejected, 4);
      for (final id in ids) {
        if (id == '#C2') {
          expect(provider.getOrderById(id)!.status, OrderStatus.pending);
          expect(provider.rowState(id), OrderRowState.failed);
        } else {
          expect(provider.getOrderById(id)!.status, OrderStatus.cancelled);
          expect(provider.rowState(id), OrderRowState.idle);
        }
      }

      // The failed row can be retried on its own.
      expect(await provider.retryOrderChange('#C2'), isTrue);
      expect(provider.getOrderById('#C2')!.status, OrderStatus.cancelled);
      expect(provider.rowState('#C2'), OrderRowState.idle);
    });
  });

  // ── 2. Widget: one row pending, list and other rows untouched ───────

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
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go('/orders');
    await tester.pumpAndSettle();

    final provider = Provider.of<OrdersProvider>(
      tester.element(find.byType(OrdersScreen)),
      listen: false,
    );
    // Long enough to inspect the pending frame before it settles.
    provider.debugChangeDelay = const Duration(seconds: 1);
    return provider;
  }

  testWidgets('accepting one order never shows the skeleton, others usable',
      (tester) async {
    final provider = await pumpOrders(tester);

    await tester.tap(find.text('Accept').first);
    await tester.pumpAndSettle();
    expect(find.text('Accept Order'), findsWidgets);
    await tester.tap(find.widgetWithText(TextButton, 'Accept'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // No whole-list skeleton during a status change.
    expect(find.byType(OrderCardSkeleton), findsNothing);
    // The pending row is still on screen, with a spinner in its action.
    expect(find.text('#ORD-001'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    final actions =
        tester.widgetList<GrowboxTableAction>(find.byType(GrowboxTableAction));
    expect(actions.where((a) => a.isLoading), hasLength(1));
    // The other pending row (#ORD-007) still has both of its actions live
    // (the seeded cancelled row's Restore is enabled too).
    expect(actions.where((a) => a.isEnabled).length, greaterThanOrEqualTo(2));

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(provider.rowState('#ORD-001'), OrderRowState.idle);
    expect(provider.getOrderById('#ORD-001')!.status, OrderStatus.accepted);
  });

  // ── 3. Widget: rollback + Retry, 320/390px, both themes ─────────────

  for (final width in [320.0, 390.0]) {
    for (final themeIndex in [0, 1]) {
      testWidgets(
          'failed accept rolls back, shows Retry, and Retry succeeds '
          '(${width.toInt()}px theme $themeIndex)', (tester) async {
        final provider = await pumpOrders(
          tester,
          size: Size(width, 800),
          themeModeIndex: themeIndex,
        );
        provider.debugChangeDelay = const Duration(milliseconds: 20);
        provider.debugFailNext = true;

        await tester.tap(find.widgetWithText(GrowboxButton, 'Accept').first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Accept'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Rolled back with a short inline error and a Retry.
        expect(provider.getOrderById('#ORD-001')!.status, OrderStatus.pending);
        expect(provider.rowState('#ORD-001'), OrderRowState.failed);
        expect(find.textContaining("Couldn't update this order"), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        // The row is not blanked: its actions are back and usable.
        expect(find.widgetWithText(GrowboxButton, 'Accept'), findsWidgets);

        await tester.tap(find.text('Retry'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(provider.getOrderById('#ORD-001')!.status, OrderStatus.accepted);
        expect(provider.rowState('#ORD-001'), OrderRowState.idle);
        expect(find.text('Retry'), findsNothing);
      });
    }
  }
}
