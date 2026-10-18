import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/providers/orders_provider.dart';
import 'package:growbox_vendor/app/providers/sales_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/constants/app_colors.dart';
import 'package:growbox_vendor/data/models/order.dart';
import 'package:growbox_vendor/features/orders/order_details_screen.dart';
import 'package:growbox_vendor/features/sales/sales_screen.dart';

import 'load_roboto.dart';

/// Regression coverage for the Sales consistency pass. All numbers derive
/// from OrdersProvider (the single source of truth), so this suite proves:
/// 1. Revenue counts only completed orders — a cancelled order (ORD-005)
///    can never contribute, and the completed/total card matches the
///    Orders page (1 of 7).
/// 2. The weekly chart reconciles with the Total Sales card.
/// 3. 'All' hides the comparison and the sparkline; the other filters are
///    labelled 'vs yesterday' / 'vs last week' / 'vs last month', with a
///    neutral (grey, flat) badge at exactly 0%.
/// 4. The axis uses round ticks starting at ₦0 with no overlap.
/// 5. Transactions carry the product's real unit (kg, bunch, …) and the
///    Order ID links through to the order details page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSales(
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

    appRouter.go('/sales');
    await tester.pumpAndSettle();
  }

  testWidgets(
      'desktop light: All hides comparison, completed-only revenue, units, ticks, links',
      (tester) async {
    await pumpSales(
      tester,
      themeModeIndex: 1, // light
      size: const Size(1440, 900),
    );

    final sales = tester.element(find.byType(SalesScreen)).read<SalesProvider>();

    // ── 1. Revenue counts only completed, non-cancelled orders ──
    // Live orders: only ORD-004 is completed (₦18,000). ORD-005's items
    // are cancelled and ORD-003 is only 'ready' — neither may count.
    expect(sales.summary.totalSales, 18000.0,
        reason: 'revenue = completed orders only (no ORD-005, no ORD-003)');
    expect(sales.summary.completedOrders, 1);
    expect(sales.summary.totalOrders, 7,
        reason: 'the card denominator must match the Orders page');
    expect(find.text('1/7'), findsOneWidget,
        reason: 'completed-orders card mirrors the Orders page');
    expect(find.text('₦18,000'), findsNWidgets(2),
        reason: 'Total Sales card + the one completed transaction row');

    final cancelled = sales.transactions
        .where((t) => t.orderId == '#ORD-005')
        .toList();
    expect(cancelled, hasLength(2));
    expect(cancelled.every((t) => t.status == 'cancelled'), isTrue,
        reason: "a cancelled order's records must never read 'completed'");

    // ── 2. Chart reconciles with the Total Sales card ──
    expect(sales.chartData, hasLength(7));
    final chartSum =
        sales.chartData.fold<double>(0, (sum, d) => sum + d.amount);
    expect(chartSum, sales.summary.totalSales,
        reason: 'weekly buckets are cut from the same completed records');

    // ── 3. 'All' shows neither comparison nor sparkline ──
    expect(sales.revenueDelta('all'), isNull);
    expect(find.textContaining('vs '), findsNothing);
    expect(find.byType(LineChart), findsNothing,
        reason: 'no sparkline on the All filter');

    // ── 4. Round axis ticks from ₦0, evenly spaced, no overlap ──
    // max = 18,000 → step 5,000 → ticks 0…20k, all unique.
    for (final label in ['₦0', '₦5k', '₦10k', '₦15k', '₦20k']) {
      expect(find.text(label), findsOneWidget,
          reason: 'axis must show round ticks including zero');
    }

    // ── 5. Real units instead of '/ unit' ──
    expect(find.text('₦2,500 / kg'), findsOneWidget,
        reason: "Fresh Tomatoes unit price carries the catalog unit");
    expect(find.text('5 kg'), findsOneWidget,
        reason: 'Qty column shows quantity + unit');
    expect(find.text('₦500 / bunch'), findsOneWidget,
        reason: 'Fresh Basil is sold per bunch');
    expect(find.text('2 bunch'), findsOneWidget);
    expect(find.text('₦1,500 / bundle'), findsOneWidget,
        reason: 'Organic Lettuce resolves to the catalog Fresh Lettuce unit');
    expect(find.textContaining('/ unit'), findsNothing);
    expect(find.text('Qty: 5 kg'), findsNothing,
        reason: 'that is the mobile card form, not the desktop table');

    // ── 6. The Order ID is a link to the order details ──
    final orderLink = tester.widget<Text>(find.text('#ORD-004'));
    expect(orderLink.style?.color, AppColors.primary,
        reason: 'links use the primary token — raised contrast');
    // The transactions table sits below the fold — scroll it up first.
    await tester.ensureVisible(find.text('#ORD-004'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#ORD-004'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailsScreen), findsOneWidget,
        reason: 'tapping the Order ID opens that order');
  });

  testWidgets('desktop light: filter chips label their comparison', 
      (tester) async {
    await pumpSales(
      tester,
      themeModeIndex: 1,
      size: const Size(1440, 900),
    );

    // Today → vs yesterday (ORD-004's ₦18,000 vs an empty yesterday).
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('+100.0% vs yesterday'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget,
        reason: 'filtered periods get the sparkline back');

    // This Week → vs last week.
    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();
    expect(find.text('+100.0% vs last week'), findsOneWidget);

    // This Month → vs last month.
    await tester.tap(find.text('This Month'));
    await tester.pumpAndSettle();
    expect(find.text('+100.0% vs last month'), findsOneWidget);
  });

  test('provider: deltas are computed against the previous window', () {
    final now = DateTime.now();
    Order seed(String id, OrderStatus status, DateTime createdAt,
            List<OrderItem> items) =>
        Order(
          id: id,
          customerName: 'Test Customer',
          customerPhone: '+234 000 000 0000',
          items: items,
          status: status,
          createdAt: createdAt,
        );

    // ₦10,000 completed yesterday, ₦15,000 completed today → +50%.
    final orders = OrdersProvider(initialOrders: [
      seed('#ORD-901', OrderStatus.completed,
          now.subtract(const Duration(days: 1)), [
        OrderItem(
            productId: 'p1', productName: 'Fresh Tomatoes', quantity: 4, price: 2500),
      ]),
      seed('#ORD-902', OrderStatus.completed,
          now.subtract(const Duration(minutes: 30)), [
        OrderItem(
            productId: 'p1', productName: 'Fresh Tomatoes', quantity: 6, price: 2500),
      ]),
    ]);
    final sales = SalesProvider(orders);

    expect(sales.revenueDelta('today'), 50.0);
    expect(sales.revenueDelta('week'), 100.0,
        reason: 'previous 7 days are empty → new activity caps at +100');
    expect(sales.revenueDelta('all'), isNull);

    // No activity in either window → exactly 0.0, the neutral case.
    // (30 days old: outside both the current AND the previous week/month
    // comparison windows.)
    final quiet = SalesProvider(OrdersProvider(initialOrders: [
      seed('#ORD-903', OrderStatus.completed,
          now.subtract(const Duration(days: 30)), [
        OrderItem(
            productId: 'p1', productName: 'Fresh Tomatoes', quantity: 1, price: 2500),
      ]),
    ]));
    expect(quiet.revenueDelta('today'), 0.0);
    expect(quiet.revenueDelta('week'), 0.0);
  });

  testWidgets('empty orders: neutral 0.0% badge and empty state render',
      (tester) async {
    await tester.runAsync(loadRoboto);
    final orders = OrdersProvider(initialOrders: const []);
    final sales = SalesProvider(orders);

    await tester.pumpWidget(MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: orders),
          ChangeNotifierProvider.value(value: sales),
        ],
        child: const Scaffold(body: SalesScreen()),
      ),
    ));

    sales.setPeriod('today');
    await tester.pumpAndSettle();

    expect(find.text('0.0% vs yesterday'), findsOneWidget,
        reason: 'no change renders the neutral badge');
    final badge = tester
        .widget<Text>(find.text('0.0% vs yesterday'))
        .style
        ?.color;
    expect(badge, AppColors.textSecondary,
        reason: 'neutral badge uses the secondary token, not green/red');
    expect(find.byIcon(Icons.trending_flat), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('mobile light: unit cards, order link, no overflow', (tester) async {
    await pumpSales(
      tester,
      themeModeIndex: 1,
      size: const Size(390, 844),
    );

    // Card rows show quantity + unit and link the Order ID.
    expect(find.text('Qty: 5 kg'), findsOneWidget);
    expect(find.text('Qty: 2 bunch'), findsOneWidget);
    expect(find.textContaining('/ unit'), findsNothing);

    final link = tester.widget<Text>(find.text('#ORD-004'));
    expect(link.style?.color, AppColors.primary);

    // Cards below the fold — scroll up before tapping.
    await tester.ensureVisible(find.text('#ORD-004'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#ORD-004'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailsScreen), findsOneWidget);
  });

  testWidgets('desktop dark: dark tokens, zero-labelled axis', (tester) async {
    await pumpSales(
      tester,
      themeModeIndex: 2, // dark
      size: const Size(1440, 900),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    // Same round ticks render in dark mode.
    for (final label in ['₦0', '₦5k', '₦10k', '₦15k', '₦20k']) {
      expect(find.text(label), findsOneWidget);
    }

    final link = tester.widget<Text>(find.text('#ORD-004'));
    expect(link.style?.color, AppColors.darkPrimary,
        reason: 'dark mode links use the dark primary token');
  });
}
