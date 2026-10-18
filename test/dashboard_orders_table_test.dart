import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/constants/app_colors.dart';
import 'package:growbox_vendor/core/constants/app_dimensions.dart';
import 'package:growbox_vendor/shared/widgets/growbox_table_action.dart';

import 'load_roboto.dart';

/// Regression coverage for the Recent Orders table pass (now fed by
/// OrdersProvider — the newest five seed orders, pending = #ORD-001 and
/// #ORD-007, so both pending rows carry an action):
/// 1. A separate, right-aligned Actions column exists; the Status cell
///    contains ONLY the status pill (the Accept button used to sit inside
///    it, styled like a second status).
/// 2. Accept is the shared GrowboxTableAction — solid AppColors.primary,
///    10×5 padding, radiusMd — the same component the Orders table uses.
/// 3. Only pending rows carry an action; rows without one leave the cell
///    empty, so every column keeps its x offset across all rows.
/// 4. At narrow widths the Time column is dropped BEFORE the action can
///    shrink: the button keeps its intrinsic width in the fixed slot.
/// 5. The same geometry and solid emerald action hold in dark mode.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDashboard(
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

    appRouter.go('/dashboard');
    await tester.pumpAndSettle();
  }

  testWidgets(
      'desktop light: Actions column, pill-only status cell, shared Accept',
      (tester) async {
    await pumpDashboard(
      tester,
      themeModeIndex: 1, // light
      size: const Size(1280, 900), // content ≈ 924 ≥ 800 → Time shown
    );

    // ── Header: all six columns render, including the new Actions slot ──
    for (final label in ['Order', 'Items', 'Amount', 'Status', 'Time', 'Actions']) {
      expect(find.text(label), findsOneWidget,
          reason: 'header cell "$label" should render above the table');
    }

    // ── The Accept button lives in the Actions column, NOT beside the pill ──
    // Two pending rows (#ORD-001, #ORD-007) → scope to the first row.
    final actionsHeader = tester.getRect(find.text('Actions'));
    final acceptRect = tester.getRect(find.text('Accept').first);
    final pillRect = tester.getRect(find.text('Pending').first);
    expect(pillRect.right < acceptRect.left, isTrue,
        reason: 'Status cell must hold only the pill — no button next to it');
    expect(pillRect.right < actionsHeader.left, isTrue,
        reason: 'pill sits strictly left of the Actions column');
    // Compare against the component's rect: the inner Text sits 10px in
    // (its own padding), so text-vs-header would measure the padding.
    final actionRect =
        tester.getRect(find.byType(GrowboxTableAction).first);
    expect((actionsHeader.right - actionRect.right).abs(), lessThan(4),
        reason: 'Actions heading is right-aligned over the button');

    // ── Actions appear on pending rows only ──
    final actions = tester.widgetList<GrowboxTableAction>(
        find.byType(GrowboxTableAction));
    expect(actions, hasLength(2),
        reason: 'the two pending newest orders (#ORD-001, #ORD-007) '
            'expose an action — and only they do');
    expect(actions.first.label, 'Accept');
    expect(actions.first.variant, GrowboxTableActionVariant.solid);

    // ── Same component as the Orders page: solid green, 10×5, radiusMd ──
    final container = tester.widget<Container>(find.descendant(
      of: find.byType(GrowboxTableAction).first,
      matching: find.byType(Container),
    ));
    expect(container.padding,
        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        reason: 'height/padding must match the Orders table button');
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primary,
        reason: 'solid emerald fill, not a pale status-twin');
    expect(decoration.borderRadius, BorderRadius.circular(AppDimensions.radiusMd));
    final label = tester.widget<Text>(find.descendant(
      of: find.byType(GrowboxTableAction).first,
      matching: find.text('Accept'),
    ));
    expect(label.style?.fontSize, 12);
    expect(label.style?.fontWeight, FontWeight.w600);
    expect(label.style?.color, Colors.white);

    // ── Empty action cells keep the columns aligned ──
    // The newest five include non-pending rows (#ORD-002 preparing,
    // #ORD-003 ready) whose Actions cell is empty.
    double leftOf(String text) => tester.getTopLeft(find.text(text)).dx;
    expect(leftOf('#ORD-001'), leftOf('#ORD-002'),
        reason: 'Order column aligns across rows with/without action');
    expect(leftOf('15 min ago'), leftOf('32 min ago'),
        reason: 'Time column aligns across rows with/without action');

    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow desktop: Time drops before the action shrinks',
      (tester) async {
    await pumpDashboard(
      tester,
      themeModeIndex: 1,
      size: const Size(1050, 900), // content ≈ 694 < 800 → Time dropped
    );

    expect(find.text('Time'), findsNothing,
        reason: 'Time is the first column to go when space is tight');
    expect(find.text('Actions'), findsOneWidget,
        reason: 'Actions survives at every table width');
    expect(find.text('Accept'), findsNWidgets(2),
        reason: 'both pending rows still offer the action at narrow widths');

    // Intrinsic size, expressed against the button's own text so the check
    // holds for any font metrics: full 10px padding on both sides means
    // the fixed cell never squeezed the button into a mini-pill.
    final actionSize = tester.getSize(find.byType(GrowboxTableAction).first);
    final textRect = tester.getRect(find.text('Accept').first);
    expect(actionSize.width, greaterThanOrEqualTo(textRect.width + 19),
        reason: 'the button keeps its intrinsic width — no squeeze into a pill');
    expect(actionSize.height, greaterThanOrEqualTo(textRect.height + 9),
        reason: 'same row height as at wide widths');

    expect(tester.takeException(), isNull,
        reason: 'the tighter table must not overflow');
  });

  testWidgets('dark: solid action and Actions column hold in dark mode',
      (tester) async {
    await pumpDashboard(
      tester,
      themeModeIndex: 2, // dark
      size: const Size(1280, 900),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark,
        reason: 'verification must run against the dark theme');

    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget,
        reason: 'wide content keeps Time in dark mode too');

    // The action stays the full-strength solid emerald on dark surfaces.
    final actions = tester.widgetList<GrowboxTableAction>(
        find.byType(GrowboxTableAction));
    expect(actions, hasLength(2));
    final container = tester.widget<Container>(find.descendant(
      of: find.byType(GrowboxTableAction).first,
      matching: find.byType(Container),
    ));
    expect((container.decoration! as BoxDecoration).color, AppColors.primary);

    // Status cell still holds the pill only.
    final pillRect = tester.getRect(find.text('Pending').first);
    final acceptRect = tester.getRect(find.text('Accept').first);
    expect(pillRect.right < acceptRect.left, isTrue);

    expect(tester.takeException(), isNull);
  });
}
