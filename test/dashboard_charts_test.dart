import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/providers/orders_provider.dart';
import 'package:growbox_vendor/app/providers/products_provider.dart';
import 'package:growbox_vendor/app/providers/sales_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/utils/formatters.dart';
import 'package:growbox_vendor/data/models/order.dart';
import 'package:growbox_vendor/features/dashboard/dashboard_screen.dart';
import 'package:growbox_vendor/shared/widgets/growbox_card.dart';

import 'load_roboto.dart';

/// Light-mode coverage for the dashboard reconciliation pass: every sales
/// widget (stats, Sales Overview chart, category ring, Recent Orders) now
/// derives from OrdersProvider — the same orders the Sales and Orders
/// pages render — so this suite proves:
/// 1. The ring, center KPI and legend match the completed-order reality
///    (only ORD-004 is completed → one Tuber & Roots slice at 100%).
/// 2. The chart's ticks come from the derived daily series (real dates,
///    ₦-axis sized by actual revenue).
/// 3. Inline Accept writes through the shared provider, so the Orders
///    page's chip counts move with it — the pages can't disagree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The daily-series labels the chart itself computes: last [index] days
  /// before today, formatted 'd MMM'. Kept in lockstep with the widget by
  /// using the same DateTime arithmetic and month table.
  String dayLabel(int daysAgo) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return '${d.day} ${months[d.month - 1]}';
  }

  testWidgets('dashboard: category donut + rating gauge in light mode',
      (tester) async {
    // Real font metrics need real IO — only runs outside FakeAsync.
    await tester.runAsync(loadRoboto);

    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));

    // Splash (5s) → login, matching the boot test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go('/dashboard');
    await tester.pumpAndSettle();

    // ── 1. Derived ring: only completed orders count, so the seed data
    // yields exactly one slice — Tuber & Roots (Sweet Potatoes) at 100%.
    expect(find.text('Sales by Category'), findsOneWidget);
    expect(find.text('Total Sales'), findsOneWidget,
        reason: 'center KPI caption should render under the total');
    expect(find.text('Tuber & Roots'), findsOneWidget,
        reason: 'idle ring shows no info chip — only the legend names it');
    expect(find.textContaining('(100%)'), findsNothing,
        reason: 'percent chip must stay hidden until a segment is selected');

    // Narrow (phone) screens keep the legend BELOW the ring — beside-ring
    // layout is reserved for wide cards.
    final phoneRing =
        tester.getRect(find.byKey(const Key('sales-category-ring')));
    expect(tester.getTopLeft(find.text('Tuber & Roots')).dy,
        greaterThan(phoneRing.bottom),
        reason: 'phone layout stacks the legend under the ring');

    // Tap behaviour: selecting a segment dims the rest and pops the
    // name/value/percent chip; tapping it again returns to idle.
    // (Hit testing only works for what's on screen — scroll it up first.)
    await tester.ensureVisible(find.byKey(const Key('sales-category-ring')));
    await tester.pumpAndSettle();
    final ringRect =
        tester.getRect(find.byKey(const Key('sales-category-ring')));
    // 45° up-right of 12 o'clock sits inside the single 346° segment.
    final insideSegment = ringRect.center + const Offset(64, -64);
    await tester.tapAt(insideSegment);
    await tester.pump();
    expect(find.textContaining('(100%)'), findsOneWidget,
        reason: 'tapping a segment should reveal its value chip');
    expect(find.text('Tuber & Roots'), findsNWidgets(2),
        reason: 'chip shows the name next to the legend row');
    await tester.tapAt(insideSegment);
    await tester.pump();
    expect(find.textContaining('(100%)'), findsNothing,
        reason: 'tapping the same segment again should return to idle');

    // Tapping the center hole clears the selection too.
    await tester.tapAt(insideSegment);
    await tester.pump();
    await tester.tapAt(ringRect.center);
    await tester.pump();
    expect(find.textContaining('(100%)'), findsNothing);

    // Legend rows mirror the ring: tapping a row selects that category
    // (chip shows), tapping it again returns to idle.
    await tester.tap(find.text('100%'));
    await tester.pump();
    expect(find.textContaining('(100%)'), findsOneWidget,
        reason: 'tapping a legend row should reveal its value chip');
    await tester.tap(find.text('100%'));
    await tester.pump();
    expect(find.textContaining('(100%)'), findsNothing,
        reason: 'tapping the same legend row again should return to idle');

    // Rating arc gauge — value is a Text.rich ("4.8/5") in the bowl.
    expect(find.text('Rating'), findsOneWidget);
    expect(find.textContaining('4.8', findRichText: true), findsOneWidget,
        reason: 'gauge should show 4.8 of 5');

    // ── Sales Overview declutter, narrow screen — DERIVED axis ──
    // Seed reality: revenue = ₦18,000 (one completed order, today) →
    // axis tops at ₦30k with ₦10k steps instead of fl_chart's uneven
    // auto intervals.
    expect(find.text('₦10k'), findsOneWidget);
    expect(find.text('₦20k'), findsOneWidget);
    expect(find.text('₦30k'), findsOneWidget);
    // The duplicate right axis (raw copies of the same sales scale) is gone.
    expect(find.text('100000'), findsNothing);
    // 30 points → 3 date ticks (indices 0/10/20), spaced by real dates.
    expect(find.text(dayLabel(29)), findsOneWidget,
        reason: 'narrow screens should show 3 spaced date ticks');
    expect(find.text(dayLabel(19)), findsOneWidget);
    expect(find.text(dayLabel(9)), findsOneWidget);
    expect(find.text(dayLabel(23)), findsNothing,
        reason: 'the 5-tick layout belongs to wide screens only');

    // Narrow phone re-layout: any header/card overflow fails the test.
    tester.view.physicalSize = const Size(360, 844);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Rating'), findsOneWidget);

    // Desktop: the two-column bento row keeps the full 5-tick treatment.
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.text(dayLabel(23)), findsOneWidget,
        reason: 'wide screens keep 5 date ticks');
    expect(find.text(dayLabel(19)), findsNothing);

    // At 1280 the category card is still too narrow for a beside-ring
    // legend (that needs the wide breakpoint) — legend stacks below.
    final desktopRing =
        tester.getRect(find.byKey(const Key('sales-category-ring')));
    // .first = the legend row (the summary line below may name the top
    // category too, and comes later in the tree).
    expect(tester.getTopLeft(find.text('Tuber & Roots').first).dy,
        greaterThan(desktopRing.bottom),
        reason: 'legend stacks under the ring below the wide threshold');

    // Orders has its own count axis on the right: 7 orders land in one
    // day → axis tops at 10, sharing the gridlines with the ₦ ticks.
    expect(find.text('10'), findsOneWidget,
        reason: 'Orders secondary axis tops out at 10 for this data');
    expect(find.text('3'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard: category legend moves beside the ring on wide screens',
      (tester) async {
    await tester.runAsync(loadRoboto);

    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    tester.view.physicalSize = const Size(1536, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go('/dashboard');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sales-category-ring')));
    await tester.pumpAndSettle();

    final ringRect =
        tester.getRect(find.byKey(const Key('sales-category-ring')));
    final legendTop =
        tester.getTopLeft(find.text('Tuber & Roots').first); // legend row, not the summary line
    expect(legendTop.dx, greaterThan(ringRect.right),
        reason: 'wide screens put the legend beside the ring');
    // A single 100% category is above the merge cutoff — no Others bucket.
    expect(find.text('Others'), findsNothing);

    // ── Dead-space fix: the stretched card must spend its room on content ──
    final categoryCard = find
        .ancestor(
            of: find.text('Sales by Category'),
            matching: find.byType(GrowboxCard))
        .first;
    final cardRect = tester.getRect(categoryCard);
    // The donut grows into the inner width the legend column doesn't need.
    expect(ringRect.width, greaterThan(220),
        reason: 'wide mode sizes the donut from the leftover inner width');
    expect(ringRect.width, closeTo(ringRect.height, 0.001),
        reason: 'the donut box stays square');
    // The bottom band is a real summary line, not air.
    final summaryLine = find.text('Top category');
    expect(summaryLine, findsOneWidget,
        reason: 'the stretched card shows a top-category summary line');
    final lineRect = tester.getRect(summaryLine);
    expect(cardRect.bottom - lineRect.bottom, lessThan(40),
        reason: 'only card padding below the summary — no dead band');
    // Donut+legend sit centered in the leftover height (spaceBetween).
    final titleRect = tester.getRect(find.text('Sales by Category'));
    final freeMid = (titleRect.bottom + lineRect.top) / 2;
    expect((ringRect.center.dy - freeMid).abs(), lessThan(32),
        reason: 'donut is vertically centered between title and summary');
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard stats and sales totals derive from the orders',
      (tester) async {
    await tester.runAsync(loadRoboto);

    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go('/dashboard');
    await tester.pumpAndSettle();

    final sales =
        tester.element(find.byType(DashboardScreen)).read<SalesProvider>();
    final orders =
        tester.element(find.byType(DashboardScreen)).read<OrdersProvider>();

    // ── Stats mirror the providers exactly ──
    final revenue = formatCurrency(sales.allTimeSummary.totalSales);
    expect(revenue, formatCurrency(18000.0),
        reason: 'seed sanity: only ORD-004 (₦18,000) is completed');

    // Total Revenue, scoped by its unique title — the ring center KPI and
    // the top-category line show the same number and must not count here.
    final revenueCard = find.ancestor(
        of: find.text('Total Revenue'), matching: find.byType(GrowboxCard));
    expect(revenueCard, findsOneWidget);
    expect(find.descendant(of: revenueCard, matching: find.text(revenue)),
        findsOneWidget,
        reason: 'Total Revenue = completed-order revenue, same as Sales');

    // Orders stat — 'Orders' is also a nav label and a chart legend key;
    // the stats grid renders first, so its card is the first ancestor.
    final ordersStatCard = find
        .ancestor(of: find.text('Orders'), matching: find.byType(GrowboxCard))
        .first;
    expect(
        find.descendant(
            of: ordersStatCard, matching: find.text('${orders.totalCount}')),
        findsOneWidget,
        reason: 'Orders stat = the same count the Orders page lists');

    // Products stat = live catalog size ('12' is unique on this page).
    final products = tester
        .element(find.byType(DashboardScreen))
        .read<ProductsProvider>();
    expect(find.text('${products.products.length}'), findsOneWidget,
        reason: 'Products stat = live catalog size');

    // Ring center KPI shows the same completed total.
    final ringKpi = find.ancestor(
        of: find.text('Total Sales'), matching: find.byType(Column));
    expect(find.descendant(of: ringKpi.first, matching: find.text(revenue)),
        findsOneWidget,
        reason: 'ring center KPI = the same completed total');

    // ── Recent Orders: the 5 newest live orders, real ids ──
    final newest = [...orders.allOrders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final o in newest.take(5)) {
      expect(find.text(o.id), findsOneWidget,
          reason: 'Recent Orders lists the newest provider orders');
    }
    expect(find.text(newest.elementAt(5).id), findsNothing,
      reason: 'only the 5 newest orders fit the card');
    // Real relative times, not baked strings.
    expect(find.text(timeAgo(newest.first.createdAt)), findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard: store pill toggles and inline Accept writes through the provider',
      (tester) async {
    await tester.runAsync(loadRoboto);

    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go('/dashboard');
    await tester.pumpAndSettle();

    // ── Store pill: explicit label, wired to StoreProvider, flips both ways ──
    expect(find.text('Store: Online'), findsOneWidget);
    await tester.tap(find.text('Store: Online'));
    await tester.pumpAndSettle();
    expect(find.text('Store: Offline'), findsOneWidget,
        reason: 'tapping the pill must close the store');
    await tester.tap(find.text('Store: Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Store: Online'), findsOneWidget,
        reason: 'tapping again must reopen it');

    // ── Inline Accept: pending rows (#ORD-001, #ORD-007) expose it ──
    expect(find.text('Accept'), findsNWidgets(2),
        reason: 'the two pending seed orders get an inline Accept');
    expect(find.text('Pending'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Accept').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept').first);
    // The provider simulates write latency (500ms) before notifying.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Accept'), findsNWidgets(1),
        reason: 'accepting consumes that row\'s button only');
    // ORD-006 is seed-accepted and still in the newest five, so the card
    // now carries two Accepted pills.
    expect(find.text('Accepted'), findsNWidgets(2),
        reason: 'the accepted row plus the seed-accepted ORD-006');
    expect(find.text('Pending'), findsOneWidget,
        reason: 'the other pending order remains');

    // ── Cross-page agreement: the Orders page chip reflects the write ──
    final dashboardOrders =
        tester.element(find.byType(DashboardScreen)).read<OrdersProvider>();
    expect(dashboardOrders.countFor(OrderStatus.accepted), 2,
        reason: 'ORD-006 (seed) + the one just accepted on the dashboard');
    appRouter.go('/orders');
    await tester.pumpAndSettle();
    expect(find.text('Accepted (2)'), findsOneWidget,
        reason: 'accepting on the dashboard moves the Orders chip too');
    expect(find.text('Pending (1)'), findsOneWidget,
        reason: 'only #ORD-007 is still pending');

    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard: chip overlapping a pill must not flicker it away',
      (tester) async {
    await tester.runAsync(loadRoboto);

    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go('/dashboard');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('sales-category-ring')));
    await tester.pumpAndSettle();
    final ringRect =
        tester.getRect(find.byKey(const Key('sales-category-ring')));
    // ~340° at r≈100 lands on the single derived segment — the spot that
    // sits directly UNDER the info chip the moment it is selected.
    final segmentPill = ringRect.center + const Offset(-34, -94);

    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer(location: Offset.zero);
    addTearDown(hover.removePointer);
    await hover.moveTo(segmentPill);
    await tester.pump();
    expect(find.textContaining('(100%)'), findsOneWidget,
        reason: 'hovering the segment should reveal its value chip');

    // Move again while the pointer stays on the segment: since Flutter
    // 3.35 RenderParagraph.hitTestSelf is true, so the chip's Texts used
    // to absorb the hover, evicting the ring's MouseRegion from the hit
    // path (exit → chip hidden → hover re-enter → chip shown = flicker
    // loop). IgnorePointer keeps the ring hovered; the chip must survive.
    await hover.moveTo(segmentPill + const Offset(1, 0));
    await tester.pump();
    expect(find.textContaining('(100%)'), findsOneWidget,
        reason: 'chip must not flicker off while the pointer stays put');

    expect(tester.takeException(), isNull);
  });
}
