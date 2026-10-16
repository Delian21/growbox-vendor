import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/providers/orders_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/constants/app_colors.dart';
import 'package:growbox_vendor/features/orders/orders_screen.dart';
import 'package:growbox_vendor/shared/widgets/growbox_button.dart';

import 'load_roboto.dart';

/// Regression coverage for the Orders table pass. The tests render with
/// flutter_test's wide fallback glyphs (real Roboto metrics do not load
/// for app text — see load_roboto.dart), so every width below is the
/// worst case: Flutter fails any test on a RenderFlex overflow, meaning
/// a pass here proves no overflow at production metrics either:
/// 1. Every row shares one column geometry — the Actions column is reserved
///    on all rows (empty when not pending), so Order/Items/Amount/Status/
///    Time line up between pending and non-pending rows.
/// 2. A header row (Order, Items, Amount, Status, Time, Actions) renders at
///    tablet/desktop widths in the dashboard's Recent Orders style.
/// 3. The list sorts pending first, then newest → oldest.
/// 4. Filter chips carry live per-status counts.
/// 5. Reject opens a confirmation dialog with an optional reason; confirming
///    rejects the order and stores the reason.
/// 6. Time text uses the secondary (higher-contrast) token.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpOrders(
    WidgetTester tester, {
    required int themeModeIndex,
    required Size size,
  }) async {
    // Real font metrics need real IO — only runs outside FakeAsync.
    await tester.runAsync(loadRoboto);

    SharedPreferences.setMockInitialValues({'theme_mode': themeModeIndex});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));

    // Splash (5s) → login, matching the other app tests.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go('/orders');
    await tester.pumpAndSettle();
  }

  testWidgets('desktop: header, aligned columns, sort, counts, reject flow',
      (tester) async {
    await pumpOrders(
      tester,
      themeModeIndex: 1, // light
      size: const Size(1440, 900),
    );

    // ── 2. Header row in the dashboard's Recent Orders style ──
    for (final label in ['Order', 'Items', 'Amount', 'Status', 'Time', 'Actions']) {
      expect(find.text(label), findsOneWidget,
          reason: 'header cell "$label" should render above the table');
    }

    // ── 3. Pending first, then newest → oldest ──
    // Mock data: pending = ORD-001 (2 min), ORD-007 (5 min); the rest at
    // 15 min, 32 min, 45 min, 1 h, 2 h.
    final expectedOrder = [
      '#ORD-001', '#ORD-007', // pending group, newest first
      '#ORD-002', '#ORD-003', '#ORD-006', '#ORD-004', '#ORD-005',
    ];
    final rows = find.textContaining('#ORD-');
    expect(rows, findsNWidgets(expectedOrder.length));
    final rowTops = rows.evaluate().map((e) {
      final w = e.widget as Text;
      return (tester.getTopLeft(find.byWidget(w)).dy, w.data);
    }).toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    expect(
      rowTops.map((r) => r.$2).toList(),
      expectedOrder,
      reason: 'pending orders must lead, then newest to oldest',
    );

    // ── 1. Shared column geometry ──
    // A pending row (ORD-001) and a non-pending row (ORD-002) must put the
    // Order id, the Status pill and the Time text at identical x offsets —
    // before this pass the missing actions column shifted flexible columns.
    double leftOf(String text) =>
        tester.getTopLeft(find.text(text)).dx;
    expect(leftOf('#ORD-001'), leftOf('#ORD-002'),
        reason: 'Order column must align across pending/non-pending rows');
    expect(leftOf('2 min ago'), leftOf('15 min ago'),
        reason: 'Time column must align across pending/non-pending rows');
    // Two pending rows → scope the badge finder to the first one.
    expect(tester.getTopLeft(find.text('Pending').first).dx,
        tester.getTopLeft(find.text('Preparing')).dx,
        reason: 'Status column must align across pending/non-pending rows');

    // The header's Actions cell is right-aligned in the same reserved
    // column as the buttons, so their right edges meet.
    final actionsRight =
        tester.getRect(find.text('Actions')).right;
    final rejectRight = tester.getRect(find.text('Reject').first).right;
    expect((actionsRight - rejectRight).abs(), lessThan(20),
        reason: 'Actions header should sit over the reserved button column');

    // ── 4. Filter chip counts follow the real data ──
    expect(find.text('All (7)'), findsOneWidget);
    expect(find.text('Pending (2)'), findsOneWidget);
    expect(find.text('Accepted (1)'), findsOneWidget);
    expect(find.text('Preparing (1)'), findsOneWidget);
    expect(find.text('Ready (1)'), findsOneWidget);
    expect(find.text('Completed (1)'), findsOneWidget);
    expect(find.text('Cancelled (1)'), findsOneWidget);

    // ── 6. Time uses the higher-contrast secondary token ──
    final timeText = tester.widget<Text>(find.text('2 min ago'));
    expect(timeText.style?.color, AppColors.textSecondary);

    // ── 5. Reject: outlined ghost button, dialog with optional reason ──
    // Desktop Reject is a transparent container with a 1px error border.
    final rejectFinder = find.text('Reject');
    expect(rejectFinder, findsNWidgets(2), reason: 'one per pending order');
    await tester.tap(rejectFinder.first);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget,
        reason: 'the dialog should offer an optional reason field');

    // Cancelling keeps the order pending.
    await tester.tap(find.widgetWithText(TextButton, 'Keep Order'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Pending (2)'), findsOneWidget);

    // Confirming with a reason rejects the order and stores the reason.
    await tester.tap(rejectFinder.first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Out of stock today');
    await tester.tap(find.widgetWithText(TextButton, 'Reject Order'));
    // Provider simulates a 500 ms network round-trip.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final provider =
        tester.element(find.byType(OrdersScreen)).read<OrdersProvider>();
    expect(provider.getOrderById('#ORD-001')!.status.name, 'cancelled');
    expect(provider.getOrderById('#ORD-001')!.notes, 'Out of stock today',
        reason: 'the optional reason should be persisted on the order');
    expect(find.text('Pending (1)'), findsOneWidget,
        reason: 'chip counts must follow the real data after the change');
    expect(find.text('Cancelled (2)'), findsOneWidget);
  });

  testWidgets('tablet: header row renders, no column overflow', (tester) async {
    await pumpOrders(
      tester,
      themeModeIndex: 1,
      size: const Size(1100, 800), // ≥ tablet breakpoint → table layout
    );

    for (final label in ['Order', 'Items', 'Amount', 'Status', 'Time', 'Actions']) {
      expect(find.text(label), findsOneWidget);
    }
    // Alignment holds at tablet widths too.
    expect(
      tester.getTopLeft(find.text('2 min ago')).dx,
      tester.getTopLeft(find.text('15 min ago')).dx,
    );
  });

  testWidgets('mobile: card layout, no header row, outlined Reject buttons',
      (tester) async {
    await pumpOrders(
      tester,
      themeModeIndex: 1,
      size: const Size(390, 844),
    );

    // The table header only exists with the table.
    expect(find.text('Actions'), findsNothing,
        reason: 'phones get card rows, not a table header');

    // Both pending Reject buttons use the ghost danger variant.
    final ghosts = tester
        .widgetList<GrowboxButton>(find.byType(GrowboxButton))
        .where((b) => b.variant == GrowboxButtonVariant.dangerOutline);
    expect(ghosts, hasLength(2),
        reason: 'mobile Reject should be outlined, not solid red');

    // Card rows keep the higher-contrast time token too.
    final timeText = tester.widget<Text>(find.text('2 min ago'));
    expect(timeText.style?.color, AppColors.textSecondary);
  });

  testWidgets('dark: header and table render cleanly', (tester) async {
    await pumpOrders(
      tester,
      themeModeIndex: 2, // dark
      size: const Size(1440, 900),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark,
        reason: 'verification must run against the dark theme');

    for (final label in ['Order', 'Items', 'Amount', 'Status', 'Time', 'Actions']) {
      expect(find.text(label), findsOneWidget);
    }
    // Dark mode uses the dark secondary token for Time.
    final timeText = tester.widget<Text>(find.text('2 min ago'));
    expect(timeText.style?.color, AppColors.darkTextSecondary);
    // Geometry holds in dark mode too.
    expect(
      tester.getTopLeft(find.text('2 min ago')).dx,
      tester.getTopLeft(find.text('15 min ago')).dx,
    );
  });
}
