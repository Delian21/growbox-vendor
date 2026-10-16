import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/constants/app_colors.dart';
import 'package:growbox_vendor/core/constants/app_dimensions.dart';
import 'package:growbox_vendor/shared/widgets/growbox_card.dart';

import 'load_roboto.dart';

/// Regression coverage for the mobile polish pass, asserted in LIGHT mode
/// with production Roboto metrics (Ahem would fake text wraps):
/// 1. The store pill is NOT in the header — it lives on the dashboard only.
/// 2. List-view cards carry the shared bottom inset (lg + 4) of grid cards.
/// 3. The grid uses the rebalanced aspect ratio and no card or header
///    overflows at 360, 390 or 412 logical px (Flutter fails the test on any
///    RenderFlex overflow, so a pass here means zero overflows).
/// 4. Add Product lives in the header beside the view toggle on
///    tablet/desktop and stays a FAB on phones only, with scroll clearance.
/// 5. Chips wrap on wide screens / scroll with a right-edge fade on phones.
/// 6. Header and chips-line product counts read the same catalog number.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('light mode: header badge, list padding, rebalanced grid ratio',
      (tester) async {
    // Real font metrics need real IO — only runs outside FakeAsync.
    await tester.runAsync(loadRoboto);

    // ThemeMode.light is index 1 — force light regardless of host platform.
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

    appRouter.go('/products');
    await tester.pumpAndSettle();

    // ── Light mode is actually in effect ──
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light,
        reason: 'verification must run against the light theme');

    // ── 1. The store pill lives ONLY on the dashboard now ──
    expect(find.text('Store: Online'), findsNothing,
        reason: 'the duplicate header pill was removed');
    expect(find.text('Store: Offline'), findsNothing);

    final headerTitles = find
        .text('Products')
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)))
        .where((r) => r.top < AppDimensions.headerHeight + 8)
        .toList();
    expect(headerTitles, isNotEmpty,
        reason: 'header should show the Products page title');

    // The card wrapping a product name — excludes the search bar, which is
    // also a GrowboxCard.
    Finder cardFor(String product) => find
        .ancestor(of: find.text(product), matching: find.byType(GrowboxCard))
        .first;

    // ── 2. List view: cards get the shared bottom inset ──
    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pumpAndSettle();

    final listCard = tester.widget<GrowboxCard>(cardFor('Fresh Tomatoes'));
    expect(
      listCard.padding,
      const EdgeInsets.fromLTRB(AppDimensions.lg, AppDimensions.lg,
          AppDimensions.lg, AppDimensions.lg + 4),
      reason: 'list rows should match the grid card bottom inset (20px)',
    );

    // ── 3. Grid view: rebalanced ratio keeps info inside the card ──
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    final grid = tester.widget<GridView>(find.byType(GridView).first);
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.childAspectRatio, 0.52,
        reason: 'phone grid should use the rebalanced (taller) ratio');

    // The stock line — last content in the info block — must sit inside the
    // card, proving the extra padding didn't cause a vertical overflow.
    final cardRect = tester.getRect(cardFor('Fresh Tomatoes'));
    final stockTexts = find.byWidgetPredicate(
        (w) => w is Text && (w.data?.endsWith('in stock') ?? false));
    expect(stockTexts, findsWidgets);
    final stockRect = tester.getRect(stockTexts.first);
    expect(stockRect.bottom, lessThanOrEqualTo(cardRect.bottom + 0.5),
        reason: 'info content must not overflow the rebalanced card');

    // ── 4. Narrow and wide phones: no header or card overflow anywhere ──
    // (Any RenderFlex overflow fails the test on its own; this re-lays the
    // whole page out at each width so every breakpoint is exercised.)
    for (final width in [360.0, 412.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Store: Online'), findsNothing,
        reason: 'pill stays gone after a resize to ${width.toInt()}px');
    }

    // ── 5. Add Product: FAB + clearance on phones, header button above ──
    // (the resize loop left us at 412px — a phone.)
    expect(find.byType(FloatingActionButton), findsOneWidget,
        reason: 'phones keep the floating Add Product');
    expect(find.text('Add Product'), findsOneWidget,
        reason: 'on phones only the FAB offers it');
    final scroll = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .firstWhere((w) => w.padding != null);
    expect((scroll.padding as EdgeInsets).bottom,
        greaterThanOrEqualTo(AppDimensions.xl + 72),
        reason: 'the grid must scroll clear of the FAB');
    // The chip strip scrolls horizontally and fades at its right edge.
    expect(find.byType(ShaderMask), findsWidgets,
        reason: 'the scrolling chip strip fades its right edge');

    // Desktop: no FAB — the header carries the action beside the toggle.
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing,
        reason: 'desktop removes the floating button');
    expect(find.text('Add Product'), findsOneWidget,
        reason: 'the header carries it beside the view toggle');
    final addBtn = tester.getRect(find.text('Add Product'));
    final toggle = tester.getRect(find.byIcon(Icons.grid_view_rounded));
    expect(addBtn.right, lessThan(toggle.left),
        reason: 'Add Product sits just left of the grid/list toggle');

    // Wide chips wrap onto multiple lines — no scroll fade needed.
    expect(find.byType(ShaderMask), findsNothing,
        reason: 'wrapping chips need no edge fade');
    final chipTops = find
        .byType(FilterChip)
        .evaluate()
        .map((e) => tester.getTopLeft(find.byWidget(e.widget)).dy)
        .toSet();
    expect(chipTops.length, greaterThanOrEqualTo(2),
        reason: 'chips wrap onto multiple rows on wide screens');

    // Tablet: also header-button-only (no floating button).
    tester.view.physicalSize = const Size(768, 1024);
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing,
        reason: 'tablets remove the floating button too');
    expect(find.text('Add Product'), findsOneWidget);

    // ── 6. Both counters read the same catalog (mock data: 12 products) ──
    expect(find.text('12 products listed'), findsOneWidget,
        reason: 'header uses the catalog count, not a stale literal');
    expect(find.text('12 of 12 products'), findsOneWidget,
        reason: 'chips line uses the same source');

    expect(tester.takeException(), isNull);
  });

  testWidgets('product cards: low-stock tag, neutral price, stepper, borders',
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

    appRouter.go('/products');
    await tester.pumpAndSettle();

    // ── Heading redundancy removed: the top bar says "Products" once ──
    expect(find.text('My Products'), findsNothing,
        reason: 'the top bar already shows the page name');

    // ── One photo-slot ratio at every breakpoint ──
    final ratios = find
        .byType(AspectRatio)
        .evaluate()
        .map((e) => (e.widget as AspectRatio).aspectRatio)
        .toSet();
    expect(ratios, {5 / 4},
        reason: 'every grid photo slot shares the same aspect ratio');

    // ── Low stock: a real tag, not just red text (lettuce 8, basil 5) ──
    expect(find.text('Low stock'), findsNWidgets(2),
        reason: 'both low-stock products carry the tag');

    // ── Price is neutral ink; green stays status-only ──
    final greenPrices = find.byWidgetPredicate((w) =>
        w is Text &&
        w.textSpan != null &&
        w.textSpan!.toPlainText().startsWith('\u20A6') &&
        (w.textSpan!.style?.color == AppColors.primary ||
            w.textSpan!.style?.color == AppColors.darkPrimary));
    expect(greenPrices, findsNothing,
        reason: 'prices must not use the status green');

    // ── Category grey raised to secondary for contrast ──
    final cardCategories = find.byWidgetPredicate(
        (w) => w is Text && w.data == 'Vegetables' && w.style?.fontSize == 12);
    expect(cardCategories, findsWidgets);
    for (final t in cardCategories.evaluate()) {
      expect((t.widget as Text).style?.color, AppColors.textSecondary,
          reason: 'card category text must be secondary, not tertiary');
    }

    // ── Borders: card + search bar + unselected chips vs the page ──
    final tomatoCard = tester.widget<GrowboxCard>(find
        .ancestor(
            of: find.text('Fresh Tomatoes'), matching: find.byType(GrowboxCard))
        .first);
    expect(tomatoCard.borderColor, AppColors.border,
        reason: 'grid cards get the separation border');
    expect(tomatoCard.borderWidth, 1);
    final searchBar = tester.widget<GrowboxCard>(find
        .ancestor(
            of: find.byType(TextField), matching: find.byType(GrowboxCard))
        .first);
    expect(searchBar.borderColor, AppColors.border);
    final unselectedChip = tester.widget<FilterChip>(
        find.byWidgetPredicate((w) => w is FilterChip && !w.selected).first);
    expect(unselectedChip.side?.width, 1);
    expect(unselectedChip.side?.color, AppColors.border);

    // ── Notification badges: error red in light mode too (like dark) ──
    expect(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.warning),
        findsNothing,
        reason: 'light-mode badges no longer use amber');

    // ── Stock stepper: ±1 lands in the provider and the card label ──
    expect(find.byKey(const Key('stock-inc-p1')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('stock-inc-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stock-inc-p1')));
    await tester.pumpAndSettle();
    expect(find.text('121 in stock'), findsOneWidget,
        reason: 'incrementing updates the card label');
    await tester.tap(find.byKey(const Key('stock-dec-p1')));
    await tester.pumpAndSettle();
    expect(find.text('120 in stock'), findsOneWidget,
        reason: 'decrementing restores it for later tests');

    expect(tester.takeException(), isNull);
  });
}
