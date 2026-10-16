import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/constants/app_dimensions.dart';
import 'package:growbox_vendor/shared/widgets/growbox_card.dart';

import 'load_roboto.dart';

/// Regression coverage for the mobile polish pass, asserted in LIGHT mode
/// with production Roboto metrics (Ahem would fake text wraps):
/// 1. The Online badge sits in the header row beside the page title.
/// 2. List-view cards carry the shared bottom inset (lg + 4) of grid cards.
/// 3. The grid uses the rebalanced aspect ratio and no card or header
///    overflows at 360, 390 or 412 logical px (Flutter fails the test on any
///    RenderFlex overflow, so a pass here means zero overflows).
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

    // ── 1. Online badge lives in the header, beside the title ──
    expect(find.text('Store: Online'), findsOneWidget,
        reason: 'the store pill moved to the header; one instance expected');

    final badgeRect = tester.getRect(find.text('Store: Online'));
    final headerTitles = find
        .text('Products')
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)))
        .where((r) => r.top < AppDimensions.headerHeight + 8)
        .toList();
    expect(headerTitles, isNotEmpty,
        reason: 'header should show the Products page title');
    final titleRect = headerTitles.first;

    expect((badgeRect.top - titleRect.top).abs(), lessThan(24),
        reason: 'badge must sit on the same row as the title');
    expect(badgeRect.left, greaterThan(titleRect.left),
        reason: 'badge must be to the right of the title');

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
      await tester.pumpAndSettle();      expect(find.text('Store: Online'), findsOneWidget,
        reason: 'badge must survive a resize to ${width.toInt()}px');
    }

    expect(tester.takeException(), isNull);
  });
}
