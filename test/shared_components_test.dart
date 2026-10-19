import 'dart:math';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/constants/app_colors.dart';
import 'package:growbox_vendor/core/constants/app_dimensions.dart';
import 'package:growbox_vendor/features/dashboard/dashboard_screen.dart';
import 'package:growbox_vendor/features/orders/orders_screen.dart';
import 'package:growbox_vendor/features/products/products_screen.dart';
import 'package:growbox_vendor/features/sales/sales_screen.dart';
import 'package:growbox_vendor/shared/widgets/growbox_filter_chip.dart';
import 'package:growbox_vendor/shared/widgets/growbox_page_header.dart';
import 'package:growbox_vendor/shared/widgets/growbox_status_pill.dart';
import 'package:growbox_vendor/shared/widgets/growbox_table.dart';
import 'package:growbox_vendor/shared/widgets/growbox_table_action.dart';

import 'load_roboto.dart';

/// Coverage for the shared-component pass:
///  * GrowboxFilterChip — one border/fill/label treatment, optional count.
///  * GrowboxStatusPill — light look unchanged, dark low-opacity tint with
///    contrast-raised text (WCAG-checked), leading dot, unknown-key no-op.
///  * GrowboxPageHeader — subtitle-only by default (no top-bar duplication).
///  * GrowboxTable — shared paddings, dividers and the text-contrast ladder.
///  * Pages render the shared pieces and no longer repeat their title.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── helpers ──────────────────────────────────────────────────────────

  Widget themed(Widget child, Brightness brightness) => MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(body: child),
      );

  /// WCAG relative luminance / contrast ratio for the pill contrast test.
  /// [v] is a 0–1 channel value (Color.r/g/b are already normalized).
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();

  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  double contrast(Color a, Color b) {
    final l1 = luminance(a);
    final l2 = luminance(b);
    return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
  }

  /// The pill's tinted fill composited over the dark card surface — the
  /// pixels a user actually sees behind the dark-theme text.
  Color overDarkSurface(Color tint) => Color.fromARGB(
        255,
        (tint.r * 255 * tint.a + AppColors.darkSurface.r * 255 * (1 - tint.a))
            .round(),
        (tint.g * 255 * tint.a + AppColors.darkSurface.g * 255 * (1 - tint.a))
            .round(),
        (tint.b * 255 * tint.a + AppColors.darkSurface.b * 255 * (1 - tint.a))
            .round(),
      );

  /// The pill's outer (fill) container — first Container in the pill subtree
  /// (the leading dot is the second one).
  Container pillBox(WidgetTester tester) =>
      tester.widgetList<Container>(
        find.descendant(
          of: find.byType(GrowboxStatusPill),
          matching: find.byType(Container),
        ),
      ).first;

  Color pillFill(WidgetTester tester) =>
      (pillBox(tester).decoration! as BoxDecoration).color!;

  /// Unwraps GrowboxTable.row()'s shell (Container, or InkWell when tappable).
  Container rowShell(Widget row) =>
      row is Container ? row : (row as InkWell).child as Container;

  Future<void> pumpRoute(
    WidgetTester tester, {
    required int themeModeIndex,
    required String route,
  }) async {
    await tester.runAsync(loadRoboto);
    SharedPreferences.setMockInitialValues({'theme_mode': themeModeIndex});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    appRouter.go(route);
    await tester.pumpAndSettle();
  }

  // ── GrowboxFilterChip ────────────────────────────────────────────────

  group('GrowboxFilterChip', () {
    testWidgets('light unselected chips carry a visible border', (tester) async {
      await tester.pumpWidget(themed(
        const GrowboxFilterChip(
          label: 'Vegetables',
          selected: false,
          onSelected: _noop,
        ),
        Brightness.light,
      ));
      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.side?.color, AppColors.border);
      expect(chip.side?.width, 1);
      expect(chip.backgroundColor, AppColors.surfaceVariant);
      expect(chip.labelStyle?.fontSize, 13);
      expect(chip.labelStyle?.fontWeight, FontWeight.w500);
      expect(chip.labelStyle?.color, AppColors.textSecondary);
    });

    testWidgets('dark unselected chips use the dark border token',
        (tester) async {
      await tester.pumpWidget(themed(
        const GrowboxFilterChip(
          label: 'Vegetables',
          selected: false,
          onSelected: _noop,
        ),
        Brightness.dark,
      ));
      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.side?.color, AppColors.darkBorder);
      expect(chip.backgroundColor, AppColors.darkSurfaceVariant);
      expect(chip.labelStyle?.color, AppColors.darkTextSecondary);
    });

    testWidgets('selected style is identical in both themes', (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(themed(
          const GrowboxFilterChip(
            label: 'All',
            selected: true,
            onSelected: _noop,
          ),
          brightness,
        ));
        final chip = tester.widget<FilterChip>(find.byType(FilterChip));
        expect(chip.selectedColor, AppColors.primary,
            reason: 'selected fill must not drift per theme/page');
        expect(chip.checkmarkColor, Colors.white);
        expect(chip.side?.color, Colors.transparent);
        expect(chip.labelStyle?.color, Colors.white);
      }
    });

    testWidgets('optional count renders as "Label (n)"', (tester) async {
      await tester.pumpWidget(themed(
        const GrowboxFilterChip(
          label: 'Pending',
          count: 3,
          selected: false,
          onSelected: _noop,
        ),
        Brightness.light,
      ));
      expect(find.text('Pending (3)'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);
    });
  });

  // ── GrowboxStatusPill ────────────────────────────────────────────────

  group('GrowboxStatusPill', () {
    testWidgets('light keeps the current look: pastel fill + status text',
        (tester) async {
      await tester.pumpWidget(
          themed(const GrowboxStatusPill(status: 'pending'), Brightness.light));
      expect(pillFill(tester), AppColors.pendingLight);
      final label = tester.widget<Text>(find.text('Pending'));
      expect(label.style?.color, AppColors.pending);
      expect(label.style?.fontSize, 11);
      expect(label.style?.fontWeight, FontWeight.w700);
      // Same hug-the-text padding as GrowboxBadge(isSmall: true).
      expect(pillBox(tester).padding,
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2));
      // Leading dot in the text colour (second container in the pill).
      final dot = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(GrowboxStatusPill),
          matching: find.byType(Container),
        ),
      ).last;
      expect((dot.decoration! as BoxDecoration).color, AppColors.pending);
      expect(dot.constraints?.maxWidth, 6);
    });

    testWidgets('light ready pill unchanged', (tester) async {
      await tester.pumpWidget(
          themed(const GrowboxStatusPill(status: 'ready'), Brightness.light));
      expect(pillFill(tester), AppColors.readyLight);
      expect(
        tester.widget<Text>(find.text('Ready')).style?.color,
        AppColors.ready,
      );
    });

    testWidgets('dark pill: low-opacity status tint, full-strength text',
        (tester) async {
      await tester.pumpWidget(
          themed(const GrowboxStatusPill(status: 'completed'), Brightness.dark));
      final fill = pillFill(tester);
      // Low-opacity tint of the status colour…
      expect(fill.a, moreOrLessEquals(0.16, epsilon: 0.01));
      expect(fill.r, moreOrLessEquals(AppColors.completed.r, epsilon: 0.01));
      // …with the contrast-raised full-strength text.
      final label = tester.widget<Text>(find.text('Completed'));
      expect(label.style?.color, AppColors.completedOnDark);
      expect(label.style?.color?.a, 1.0);
    });

    testWidgets(
        'dark text clears WCAG AA (4.5:1) for every status, over its tint',
        (tester) async {
      const texts = {
        'pending': AppColors.pendingOnDark,
        'accepted': AppColors.acceptedOnDark,
        'preparing': AppColors.preparingOnDark,
        'ready': AppColors.readyOnDark,
        'completed': AppColors.completedOnDark,
        'cancelled': AppColors.cancelledOnDark,
      };
      const bases = {
        'pending': AppColors.pending,
        'accepted': AppColors.accepted,
        'preparing': AppColors.preparing,
        'ready': AppColors.ready,
        'completed': AppColors.completed,
        'cancelled': AppColors.cancelled,
      };
      for (final key in texts.keys) {
        final bg = overDarkSurface(bases[key]!.withValues(alpha: 0.16));
        final ratio = contrast(texts[key]!, bg);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '$key dark text contrast was ${ratio.toStringAsFixed(2)}');
      }
      // Accepted / Preparing / Ready must stay clearly distinguishable —
      // distinct text hues AND distinct tinted fills.
      expect({texts['accepted'], texts['preparing'], texts['ready']}.length, 3);
      expect({
        overDarkSurface(bases['accepted']!.withValues(alpha: 0.16)),
        overDarkSurface(bases['preparing']!.withValues(alpha: 0.16)),
        overDarkSurface(bases['ready']!.withValues(alpha: 0.16)),
      }.length, 3);
    });

    testWidgets('every status label renders with its token', (tester) async {
      const labels = {
        'pending': 'Pending',
        'accepted': 'Accepted',
        'preparing': 'Preparing',
        'ready': 'Ready',
        'completed': 'Completed',
        'cancelled': 'Cancelled',
      };
      for (final entry in labels.entries) {
        await tester.pumpWidget(
            themed(GrowboxStatusPill(status: entry.key), Brightness.light));
        expect(find.text(entry.value), findsOneWidget,
            reason: 'status ${entry.key} must map to ${entry.value}');
      }
    });

    testWidgets('unknown status renders nothing', (tester) async {
      await tester.pumpWidget(themed(
          const GrowboxStatusPill(status: 'refunded'), Brightness.light));
      expect(find.byType(GrowboxStatusPill), findsOneWidget);
      expect(find.text('Refunded'), findsNothing);
      expect(find.byType(Text), findsNothing);
    });
  });

  // ── GrowboxPageHeader ────────────────────────────────────────────────

  group('GrowboxPageHeader', () {
    testWidgets('subtitle only: no second (repeated) title line', (tester) async {
      await tester.pumpWidget(themed(
        const GrowboxPageHeader(subtitle: '7 total orders'),
        Brightness.light,
      ));
      expect(find.text('7 total orders'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget,
          reason: 'subtitle-only headers must not render a title line');
      final subtitle = tester.widget<Text>(find.text('7 total orders'));
      expect(subtitle.style?.fontSize, 14);
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    testWidgets('optional title renders the established 24/w700 pattern',
        (tester) async {
      await tester.pumpWidget(themed(
        const GrowboxPageHeader(title: 'Order #1', subtitle: 'Details'),
        Brightness.light,
      ));
      final title = tester.widget<Text>(find.text('Order #1'));
      expect(title.style?.fontSize, 24);
      expect(title.style?.fontWeight, FontWeight.w700);
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('trailing slot renders on the right', (tester) async {
      await tester.pumpWidget(themed(
        const GrowboxPageHeader(
          subtitle: 'x',
          trailing: Text('ACTION'),
        ),
        Brightness.light,
      ));
      expect(find.text('ACTION'), findsOneWidget);
    });
  });

  // ── GrowboxTable ─────────────────────────────────────────────────────

  group('GrowboxTable', () {
    test('header cell uses the shared heading style', () {
      final cell = GrowboxTable.headerCell('Order', false) as Text;
      expect(cell.style?.fontSize, 12);
      expect(cell.style?.fontWeight, FontWeight.w600);
      expect(cell.style?.letterSpacing, 0.5);
      expect(cell.style?.color, AppColors.textTertiary);

      final darkCell = GrowboxTable.headerCell('Order', true) as Text;
      expect(darkCell.style?.color, AppColors.darkTextTertiary);
    });

    test('header row padding and divider are shared', () {
      final header = GrowboxTable.headerRow(children: const []) as Padding;
      expect(header.padding,
          const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md));
      expect(header.child, isA<Row>());

      final lightDivider = GrowboxTable.headerDivider(false) as Divider;
      expect(lightDivider.height, 1);
      expect(lightDivider.color, AppColors.border);
      final darkDivider = GrowboxTable.headerDivider(true) as Divider;
      expect(darkDivider.color, AppColors.darkBorder);
    });

    test('row shell: shared paddings and 0.5px divider', () {
      final desktop = rowShell(GrowboxTable.row(
        isDark: false,
        child: const Text('desktop'),
      ));
      expect(desktop.padding,
          const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md));
      final mobile = rowShell(GrowboxTable.row(
        isDark: false,
        mobile: true,
        child: const Text('mobile'),
      ));
      expect(mobile.padding, const EdgeInsets.all(AppDimensions.lg));

      final border = (desktop.decoration! as BoxDecoration).border! as Border;
      expect(border.bottom.width, 0.5);
      expect(border.bottom.color, AppColors.border);
      final darkBorder = (rowShell(GrowboxTable.row(
        isDark: true,
        child: const Text('d'),
      )).decoration! as BoxDecoration).border! as Border;
      expect(darkBorder.bottom.color, AppColors.darkBorder);
    });

    test('row onTap wraps the shell in an InkWell', () {
      final shell = GrowboxTable.row(
        isDark: false,
        onTap: () {},
        child: const Text('row'),
      );
      expect(shell, isA<InkWell>());
      expect((shell as InkWell).child, isA<Container>());
    });

    test('cell contrast ladder is stable', () {
      for (final isDark in [false, true]) {
        final strong = GrowboxTable.strongStyle(isDark);
        expect(strong.fontSize, 14);
        expect(strong.fontWeight, FontWeight.w600);
        expect(strong.color,
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

        final secondary = GrowboxTable.secondaryStyle(isDark);
        expect(secondary.fontSize, 13);
        expect(secondary.color,
            isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

        final meta = GrowboxTable.metaStyle(isDark);
        expect(meta.fontSize, 12);
        expect(meta.color,
            isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

        final muted = GrowboxTable.mutedStyle(isDark);
        expect(muted.fontSize, 11);
        expect(muted.color,
            isDark ? AppColors.darkTextTertiary : AppColors.textTertiary);
      }
    });
  });

  // ── GrowboxTableAction ───────────────────────────────────────────────

  group('GrowboxTableAction', () {
    /// The button's Container — the only one in its subtree.
    BoxDecoration actionDecoration(WidgetTester tester) =>
        (tester.widget<Container>(find.descendant(
              of: find.byType(GrowboxTableAction),
              matching: find.byType(Container),
            ))
            .decoration! as BoxDecoration);

    /// Where the pointer waits between hovers: well away from the button,
    /// which sits at the scaffold's top-left corner — Offset.zero is ON it.
    const awayFromButton = Offset(700, 500);

    /// Parks one mouse pointer for the whole test.
    ///
    /// A test may hold only one live mouse device: adding a second pointer
    /// while the first is still down trips MouseTracker's Added/Removed
    /// pairing assertion, so hover tests move this single pointer on and off
    /// instead of creating a fresh gesture per round.
    Future<TestGesture> addParkedMouse(WidgetTester tester) async {
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: awayFromButton);
      addTearDown(pointer.removePointer);
      return pointer;
    }

    /// Moves the parked pointer onto the button and lets the hover rebuild run.
    Future<void> hoverOn(WidgetTester tester, TestGesture pointer) async {
      await pointer.moveTo(tester.getCenter(find.byType(GrowboxTableAction)));
      await tester.pump();
    }

    testWidgets('solid: resting emerald in both themes, hover moves the fill',
        (tester) async {
      final pointer = await addParkedMouse(tester);
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(themed(
          const GrowboxTableAction(label: 'Accept', onTap: _tap),
          brightness,
        ));
        // Settle MaterialApp's theme animation — otherwise the second
        // round would still render the previous brightness for a frame.
        await tester.pumpAndSettle();
        expect(actionDecoration(tester).color, AppColors.primary,
            reason: 'resting fill stays the shared emerald in $brightness');

        await hoverOn(tester, pointer);
        expect(actionDecoration(tester).color, isNot(AppColors.primary),
            reason: 'hover must visibly move the fill in $brightness');

        final region = tester.widget<MouseRegion>(find.descendant(
          of: find.byType(GrowboxTableAction),
          matching: find.byType(MouseRegion),
        ));
        expect(region.cursor, SystemMouseCursors.click,
            reason: 'the button advertises clickability with its cursor');

        // Park the pointer away so the next round starts at rest.
        await pointer.moveTo(awayFromButton);
        await tester.pump();
      }
    });

    testWidgets('outline: ghost at rest, a tint (never solid red) on hover',
        (tester) async {
      final pointer = await addParkedMouse(tester);
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(themed(
          const GrowboxTableAction(
            label: 'Reject',
            variant: GrowboxTableActionVariant.outline,
            onTap: _tap,
          ),
          brightness,
        ));
        await tester.pumpAndSettle();
        final resting = actionDecoration(tester);
        expect(resting.color, Colors.transparent);
        expect(resting.border?.top.color, AppColors.error);

        await hoverOn(tester, pointer);
        expect(
          actionDecoration(tester).color,
          brightness == Brightness.light
              ? AppColors.errorLight
              : AppColors.error.withValues(alpha: 0.16),
          reason: 'hover fills with a tint — a saturated red fill would '
              'outweigh the Accept beside it',
        );

        await pointer.moveTo(awayFromButton);
        await tester.pump();
      }
    });

    testWidgets('neutral: quiet theme border at rest, primary on hover',
        (tester) async {
      final pointer = await addParkedMouse(tester);
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(themed(
          const GrowboxTableAction(
            label: 'View',
            variant: GrowboxTableActionVariant.neutral,
            onTap: _tap,
          ),
          brightness,
        ));
        await tester.pumpAndSettle();
        final primary = brightness == Brightness.light
            ? AppColors.primary
            : AppColors.darkPrimary;

        final resting = actionDecoration(tester);
        expect(resting.color, Colors.transparent);
        expect(
          resting.border?.top.color,
          brightness == Brightness.light
              ? AppColors.secondaryBorder
              : AppColors.darkBorder,
        );
        expect(
          tester.widget<Text>(find.text('View')).style?.color,
          brightness == Brightness.light
              ? AppColors.textSecondary
              : AppColors.darkTextSecondary,
        );

        await hoverOn(tester, pointer);
        final hovered = actionDecoration(tester);
        expect(
          hovered.color,
          brightness == Brightness.light
              ? AppColors.primarySurface
              : AppColors.darkPrimarySurface,
        );
        expect(hovered.border?.top.color, primary);
        expect(tester.widget<Text>(find.text('View')).style?.color, primary);

        await pointer.moveTo(awayFromButton);
        await tester.pump();
      }
    });

    testWidgets('pointer leaving restores the resting fill', (tester) async {
      await tester.pumpWidget(themed(
        const GrowboxTableAction(label: 'Accept', onTap: _tap),
        Brightness.light,
      ));
      await tester.pumpAndSettle();

      final pointer = await addParkedMouse(tester);
      await hoverOn(tester, pointer);
      expect(actionDecoration(tester).color, isNot(AppColors.primary));

      // Scoped to the button — MaterialApp's tree carries MouseRegions too.
      final region = tester.widget<MouseRegion>(find.descendant(
        of: find.byType(GrowboxTableAction),
        matching: find.byType(MouseRegion),
      ));
      expect(region.cursor, SystemMouseCursors.click);

      await pointer.moveTo(awayFromButton);
      await tester.pump();
      expect(actionDecoration(tester).color, AppColors.primary,
          reason: 'exit must clear the hover state');
    });
  });

  // ── pages render the shared pieces ───────────────────────────────────

  group('pages use the shared components', () {
    testWidgets('Orders (light): shared header/chips/pills, no repeated title',
        (tester) async {
      await pumpRoute(tester, themeModeIndex: 1, route: '/orders');
      expect(find.byType(GrowboxPageHeader), findsOneWidget);
      expect(find.textContaining('total orders'), findsOneWidget);
      // The top bar shows "Orders"; the page must not repeat it.
      expect(
        find.descendant(
          of: find.byType(OrdersScreen),
          matching: find.text('Orders'),
        ),
        findsNothing,
      );
      expect(find.byType(GrowboxFilterChip), findsWidgets);
      expect(find.byType(GrowboxStatusPill), findsWidgets);
    });

    testWidgets('Orders (dark): pills use the dark tint treatment',
        (tester) async {
      await pumpRoute(tester, themeModeIndex: 2, route: '/orders');
      final fill = pillFill(tester);
      expect(fill.a, lessThan(0.5),
          reason: 'dark pills must not use the bright pastel fills');
    });

    testWidgets('Sales (light): shared chips, header and pills', (tester) async {
      await pumpRoute(tester, themeModeIndex: 1, route: '/sales');
      expect(find.byType(GrowboxPageHeader), findsOneWidget);
      expect(find.byType(GrowboxFilterChip), findsNWidgets(4));
      expect(find.byType(GrowboxStatusPill), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(SalesScreen),
          matching: find.text('Sales'),
        ),
        findsNothing,
      );
    });

    testWidgets('Products (light): shared chips and subtitle header',
        (tester) async {
      await pumpRoute(tester, themeModeIndex: 1, route: '/products');
      expect(find.byType(GrowboxPageHeader), findsOneWidget);
      expect(find.byType(GrowboxFilterChip), findsWidgets);
      expect(find.textContaining('products listed'), findsOneWidget);
      // No in-page "Products"/"My Products" heading — the top bar owns it.
      expect(
        find.descendant(
          of: find.byType(ProductsScreen),
          matching: find.text('Products'),
        ),
        findsNothing,
      );
      expect(find.text('My Products'), findsNothing);
    });

    testWidgets('Dashboard (light): shared header with trailing store badge',
        (tester) async {
      await pumpRoute(tester, themeModeIndex: 1, route: '/dashboard');
      expect(find.byType(GrowboxPageHeader), findsOneWidget);
      expect(
        find.text("Here's what's happening with your store today"),
        findsOneWidget,
      );
      expect(find.textContaining('Store:'), findsOneWidget);
      expect(find.byType(GrowboxStatusPill), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(DashboardScreen),
          matching: find.text('Dashboard'),
        ),
        findsNothing,
      );
    });
  });
}

/// Const-friendly no-op callback for chip widgets in tests.
void _noop(bool _) {}

/// Const-friendly no-op callback for tap widgets in tests.
void _tap() {}
