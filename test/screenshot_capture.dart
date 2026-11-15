import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/app/router.dart';

import 'load_roboto.dart';

/// Screenshot capture for design review — NOT part of the normal test suite
/// (the filename has no `_test` suffix, so `flutter test` skips it).
///
///   flutter test --update-goldens test/screenshot_capture.dart
///
/// Writes PNGs to `screenshots/` at the project root:
///   `desktop_<page>_<light|dark>_<expanded|collapsed>.png`
///   `mobile_<page>_<light|dark>.png`
///   `mobile_dashboard_<light|dark>_drawer_open.png`
///   `desktop_dashboard_light_<expanded|collapsed>_text2x.png`
///
/// Theme indices are ThemeMode.values indices: 1 = light, 2 = dark.
/// Icons and Roboto are loaded from the local Flutter SDK for real glyphs
/// and real text metrics.
const _pages = <(String, String)>[
  ('dashboard', '/dashboard'),
  ('orders', '/orders'),
  ('order_details', '/orders/%23ORD-002'),
  ('products', '/products'),
  ('sales', '/sales'),
  ('store', '/store'),
  ('notifications', '/notifications'),
  ('settings', '/settings'),
  ('help', '/help'),
];

const _desktop = Size(1440, 900);
const _phone = Size(390, 844);

Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 80),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 6),
    );
  } catch (_) {
    // A looping animation (progress shimmer, chart pulse) never settles;
    // one long frame is enough for a still capture.
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// flutter_test ships no MaterialIcons glyphs, so without this every icon in
/// a capture is an empty box. Load the SDK's icon font for truthful shots.
Future<void> _loadMaterialIcons() async {
  var dir = Directory(File(Platform.resolvedExecutable).parent.path);
  File? font;
  for (var hop = 0; hop < 24 && font == null; hop++) {
    for (final sub in [
      'cache/artifacts/material_fonts',
      'artifacts/material_fonts',
    ]) {
      final candidate = File('${dir.path}/$sub/MaterialIcons-Regular.otf');
      if (candidate.existsSync()) {
        font = candidate;
        break;
      }
    }
    dir = dir.parent;
  }
  if (font == null) return; // captures still work, icons stay boxes

  final bytes = await font.readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    )));
  await loader.load();
}

Future<void> _boot(
  WidgetTester tester,
  Size size,
  int themeModeIndex, {
  double textScale = 1.0,
}) async {
  await tester.runAsync(() async {
    await loadRoboto();
    await _loadMaterialIcons();
  });
  // Icons loaded after the theme's IconTheme is built still paint with the
  // new glyphs on the next frame, so no rebuild juggling is needed here.
  SharedPreferences.setMockInitialValues({'theme_mode': themeModeIndex});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(MultiProvider(
    providers: growboxProviders(),
    child: const GrowboxApp(),
  ));
  // Splash holds for 5s, then the router lands on /login.
  await tester.pump(const Duration(seconds: 5));
  await _settle(tester);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../screenshots/$name.png'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (label, index) in [('light', 1), ('dark', 2)]) {
    for (final collapsed in [false, true]) {
      final state = collapsed ? 'collapsed' : 'expanded';

      testWidgets('desktop $label $state', (tester) async {
        await _boot(tester, _desktop, index);

        if (collapsed) {
          await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
          await _settle(tester);
        }

        for (final (page, route) in _pages) {
          appRouter.go(route);
          await _settle(tester);
          await _shot(tester, 'desktop_${page}_${label}_$state');
        }
      });
    }

    testWidgets('mobile $label', (tester) async {
      await _boot(tester, _phone, index);

      for (final (page, route) in _pages) {
        appRouter.go(route);
        await _settle(tester);
        await _shot(tester, 'mobile_${page}_$label');
      }

      // Drawer open (the mobile rail), captured on the dashboard.
      appRouter.go('/dashboard');
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await _settle(tester);
      await _shot(tester, 'mobile_dashboard_${label}_drawer_open');
    });
  }

  // 320px: the narrowest phone width the mobile headers are designed for.
  for (final (label, index) in [('light', 1), ('dark', 2)]) {
    testWidgets('phone 320 $label', (tester) async {
      await _boot(tester, const Size(320, 800), index);
      for (final (page, route) in const [
        ('dashboard', '/dashboard'),
        ('notifications', '/notifications'),
        ('order_details', '/orders/%23ORD-001'),
        ('products', '/products'),
        ('sales', '/sales'),
      ]) {
        appRouter.go(route);
        await _settle(tester);
        tester.takeException();
        await _shot(tester, 'phone320_${page}_$label');
      }
    });
  }

  // Narrowest phone width at the platform's maximum text size, light mode:
  // the hardest layout case for the data-dense screens.
  testWidgets('phone 320 light text 2.0x', (tester) async {
    await _boot(tester, const Size(320, 800), 1, textScale: 2.0);
    for (final (page, route) in const [
      ('orders', '/orders'),
      ('dashboard', '/dashboard'),
      ('products', '/products'),
    ]) {
      appRouter.go(route);
      await _settle(tester);
      tester.takeException();
      await _shot(tester, 'phone320_${page}_light_text2x');
    }
  });

  // Accessibility: the rail at 2.0x, the platform maximum text size.
  testWidgets('desktop 2.0x text expanded', (tester) async {
    await _boot(tester, _desktop, 1, textScale: 2.0);
    appRouter.go('/dashboard');
    await _settle(tester);
    // The dashboard's own 2.0x overflows are a separate issue from the rail;
    // drain them so this capture still gets written.
    tester.takeException();
    await _shot(tester, 'desktop_dashboard_light_expanded_text2x');
  });

  testWidgets('desktop 2.0x text collapsed', (tester) async {
    await _boot(tester, _desktop, 1, textScale: 2.0);
    appRouter.go('/dashboard');
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
    await _settle(tester);
    tester.takeException(); // see the expanded capture above
    await _shot(tester, 'desktop_dashboard_light_collapsed_text2x');
  });
}
