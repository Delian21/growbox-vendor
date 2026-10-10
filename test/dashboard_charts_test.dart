import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/router.dart';

import 'load_roboto.dart';

/// Light-mode smoke test for the dashboard chart pass: the restyled
/// Sales by Category donut and the rating arc gauge must render without a
/// single RenderFlex overflow at phone widths (Flutter fails the test on
/// any overflow) and carry the right content.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    // Sales by Category ring: center KPI in the hole, idle = no labels.
    expect(find.text('Sales by Category'), findsOneWidget);
    expect(find.text('Total Sales'), findsOneWidget,
        reason: 'center KPI caption should render under the total');
    expect(find.text('Vegetables'), findsOneWidget,
        reason: 'idle ring shows no info chip — only the legend names it');
    expect(find.textContaining('(30%)'), findsNothing,
        reason: 'percent chip must stay hidden until a segment is selected');

    // Tap behaviour: selecting a segment dims the rest and pops the
    // name/value/percent chip; tapping it again returns to idle.
    // (Hit testing only works for what's on screen — scroll it up first.)
    await tester.ensureVisible(find.byKey(const Key('sales-category-ring')));
    await tester.pumpAndSettle();
    final ringRect =
        tester.getRect(find.byKey(const Key('sales-category-ring')));
    // 45° up-right of 12 o'clock sits inside the first segment (30%).
    final insideSegment = ringRect.center + const Offset(64, -64);
    await tester.tapAt(insideSegment);
    await tester.pump();
    expect(find.textContaining('(30%)'), findsOneWidget,
        reason: 'tapping a segment should reveal its value chip');
    expect(find.text('Vegetables'), findsNWidgets(2),
        reason: 'chip shows the name next to the legend row');
    await tester.tapAt(insideSegment);
    await tester.pump();
    expect(find.textContaining('(30%)'), findsNothing,
        reason: 'tapping the same segment again should return to idle');

    // Tapping the center hole clears the selection too.
    await tester.tapAt(insideSegment);
    await tester.pump();
    await tester.tapAt(ringRect.center);
    await tester.pump();
    expect(find.textContaining('(30%)'), findsNothing);

    // Legend rows mirror the ring: tapping a row selects that category
    // (chip shows), tapping it again returns to idle.
    await tester.tap(find.text('20%'));
    await tester.pump();
    expect(find.textContaining('(20%)'), findsOneWidget,
        reason: 'tapping a legend row should reveal its value chip');
    await tester.tap(find.text('20%'));
    await tester.pump();
    expect(find.textContaining('(20%)'), findsNothing,
        reason: 'tapping the same legend row again should return to idle');

    // Rating arc gauge — value is a Text.rich ("4.8/5") in the bowl.
    expect(find.text('Rating'), findsOneWidget);
    expect(find.textContaining('4.8', findRichText: true), findsOneWidget,
        reason: 'gauge should show 4.8 of 5');

    // ── Sales Overview declutter (Option A), narrow screen ──
    // Clean 40k Y ticks instead of fl_chart's uneven auto values.
    expect(find.text('₦40k'), findsOneWidget);
    expect(find.text('₦80k'), findsOneWidget);
    expect(find.text('₦120k'), findsOneWidget);
    // The duplicate right axis (raw copies of the same sales scale) is gone.
    expect(find.text('100000'), findsNothing);
    // 31 points → 3 date ticks (indices 0/11/22), well spaced.
    expect(find.text('May 12'), findsOneWidget,
        reason: 'narrow screens should show 3 spaced date ticks');
    expect(find.text('May 23'), findsOneWidget);
    expect(find.text('May 8'), findsNothing,
        reason: 'the 5-tick layout belongs to wide screens only');

    // Narrow phone re-layout: any header/card overflow fails the test.
    tester.view.physicalSize = const Size(360, 844);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Rating'), findsOneWidget);

    // Desktop: the two-column bento row keeps the full 5-tick treatment.
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.text('May 8'), findsOneWidget,
        reason: 'wide screens keep 5 date ticks');
    expect(find.text('May 12'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
