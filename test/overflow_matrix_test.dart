import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/shared/layouts/main_layout.dart';
import 'package:growbox_vendor/shared/widgets/growbox_button.dart';

import 'load_roboto.dart';

/// Systematic overflow coverage.
///
/// Every shell page (and the two detail pages) is rendered at each text scale
/// (1.0, 1.5, 2.0), each width (320, 360, 390, 1440) and both themes, and
/// `takeException()` must stay null after every load. Sheet/dialog coverage
/// follows for the surfaces that overflow first: the Edit Store sheet, the
/// single and bulk Reject dialogs and the bulk-selection bar.
///
/// The app starts straight on the route under test — no 5-second splash — so a
/// full matrix run stays practical.
const List<(String, String)> _routes = [
  ('dashboard', '/dashboard'),
  ('products', '/products'),
  ('product details', '/products/p1'),
  ('orders', '/orders'),
  ('order details', '/orders/%23ORD-001'),
  ('sales', '/sales'),
  ('store', '/store'),
  ('notifications', '/notifications'),
  ('settings', '/settings'),
  ('help', '/help'),
];

const List<double> _widths = [320, 360, 390, 1440];
const List<double> _scales = [1.0, 1.5, 2.0];

Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 80),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 8),
    );
  } catch (_) {
    // A looping animation never settles; a still frame is enough here.
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Boots the app once and jumps straight to [route] (skipping the splash).
Future<void> _pumpAt(
  WidgetTester tester, {
  required String route,
  required Size size,
  required double textScale,
  required int themeModeIndex,
}) async {
  await tester.runAsync(loadRoboto);
  SharedPreferences.setMockInitialValues({'theme_mode': themeModeIndex});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(MultiProvider(
    providers: growboxProviders(),
    child: const GrowboxApp(),
  ));
  // One frame to build the shell, then straight to the route: the splash timer
  // is never waited on, so each combination costs a few hundred milliseconds.
  await tester.pump();
  appRouter.go(route);
  await _settle(tester);
  expect(find.byType(MainLayout), findsOneWidget,
      reason: 'the shell should be mounted for $route');
}

String _label(Size size, double scale, String theme) =>
    '${size.width.toInt()}px @${scale}x $theme';

void main() {
  for (final width in _widths) {
    for (final scale in _scales) {
      for (final (themeIndex, theme) in [(0, 'light'), (1, 'dark')]) {
        testWidgets(
            '${width.toInt()}px @${scale}x $theme: every page is overflow-free',
            (tester) async {
          final size = Size(width, width == 1440 ? 900 : 800);
          await _pumpAt(
            tester,
            route: '/dashboard',
            size: size,
            textScale: scale,
            themeModeIndex: themeIndex,
          );

          final failures = <String>[];
          for (final (name, route) in _routes) {
            appRouter.go(route);
            await _settle(tester);
            final error = tester.takeException();
            if (error != null) {
              failures.add('$name ($route): $error');
            }
          }
          // Flush the splash timer the fast start skipped, so the test binding
          // does not report a pending timer at teardown.
          await tester.pump(const Duration(seconds: 5));
          expect(failures, isEmpty,
              reason: '${_label(size, scale, theme)}\n${failures.join('\n')}');
        });
      }
    }
  }

  // ── Sheets, dialogs and the selection bar ──
  for (final width in const [320.0, 390.0]) {
    for (final scale in const [1.5, 2.0]) {
      for (final (themeIndex, theme) in [(0, 'light'), (1, 'dark')]) {
        testWidgets(
            '${width.toInt()}px @${scale}x $theme: sheets and dialogs fit',
            (tester) async {
          final size = Size(width, 800);

          // Edit Store sheet.
          await _pumpAt(
            tester,
            route: '/store',
            size: size,
            textScale: scale,
            themeModeIndex: themeIndex,
          );
          await tester.tap(find.text('Edit Store').first);
          await _settle(tester);
          final failures = <String>[];
          final sheetError = tester.takeException();
          if (sheetError != null) failures.add('Edit Store sheet: $sheetError');
          await tester.tap(find.byIcon(Icons.close).first);
          await _settle(tester);

          // Single Reject dialog, then the bulk bar + bulk Reject dialog.
          appRouter.go('/orders');
          await _settle(tester);
          await tester.tap(find.text('Reject').first);
          await _settle(tester);
          final singleError = tester.takeException();
          if (singleError != null) {
            failures.add('single Reject dialog: $singleError');
          }
          // Back out without rejecting.
          await tester.tap(find.text('Keep Order').first);
          await _settle(tester);

          await tester.tap(find.byType(Checkbox).first);
          await _settle(tester);
          final barError = tester.takeException();
          if (barError != null) failures.add('bulk selection bar: $barError');

          // The pinned phone bar sits under the dock's floating edge at these
          // sizes, so invoke the button directly: the point is to lay the
          // dialog out, not to re-test the tap target.
          final rejectButton = tester.widget<GrowboxButton>(
            find.widgetWithText(GrowboxButton, 'Reject selected (2)'),
          );
          rejectButton.onPressed!();
          await _settle(tester);
          final bulkError = tester.takeException();
          if (bulkError != null) {
            failures.add('bulk Reject dialog: $bulkError');
          }

          await tester.pump(const Duration(seconds: 5));
          expect(failures, isEmpty,
              reason: '${_label(size, scale, theme)}\n${failures.join('\n')}');
        });
      }
    }
  }
}
