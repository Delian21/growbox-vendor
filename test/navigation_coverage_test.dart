import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/main.dart';

import 'load_roboto.dart';

/// Flattens the router tree into full paths, including ShellRoute children and
/// nested detail routes (whose ':id' segments are kept in the path).
List<String> routePaths() {
  final paths = <String>[];

  void walk(List<RouteBase> routes, String parent) {
    for (final route in routes) {
      if (route is GoRoute) {
        final path =
            route.path.startsWith('/') ? route.path : '$parent/${route.path}';
        paths.add(path);
        walk(route.routes, path);
      } else if (route is ShellRoute) {
        walk(route.routes, parent);
      }
    }
  }

  walk(appRouter.configuration.routes, '');
  return paths;
}

/// Every route must be reachable from somewhere. Two complementary checks:
///  1. static — some widget outside router.dart navigates to each path;
///  2. behavioural — on a 390px phone, the shell pages are reached by tapping
///     the dock and the drawer, and the detail pages by tapping a row/card.
/// Together they catch a route that exists but has no entry point at all, and
/// a phone layout that hides one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every route path has a navigation entry point in the UI code', () {
    final libFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.dart') &&
            !f.path.replaceAll(r'\', '/').endsWith('app/router.dart'))
        .toList();
    expect(libFiles, isNotEmpty, reason: 'lib/ should contain Dart sources');

    final source = libFiles.map((f) => f.readAsStringSync()).join('\n');
    final missing = <String>[];

    for (final path in routePaths()) {
      // '/' is the splash: the app's own entry point, not a UI target.
      if (path == '/') continue;
      // Detail routes are opened as '<base>/<id>', so look for the base.
      final needle = path.contains(':')
          ? "'${path.substring(0, path.indexOf(':'))}"
          : "'$path'";
      if (!source.contains(needle)) missing.add('$path (looked for $needle)');
    }

    expect(missing, isEmpty,
        reason: 'these routes have no entry point in lib/: $missing');
  });

  testWidgets('390px phone: shell and detail routes are reachable by tapping',
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
    await tester.pump(const Duration(seconds: 1)); // splash
    await tester.pumpAndSettle();

    String here() => appRouter.routerDelegate.currentConfiguration.uri.path;
    final visited = <String>{};

    Future<void> tapAndCollect(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
      visited.add(here());
      expect(tester.takeException(), isNull);
    }

    // Shell entry, then every dock destination by tapping its label.
    appRouter.go('/dashboard');
    await tester.pumpAndSettle();
    visited.add(here());

    await tapAndCollect(find.text('Orders').last);
    expect(here(), '/orders');

    await tapAndCollect(find.text('Products').last);
    expect(here(), '/products');

    await tapAndCollect(find.text('Sales').last);
    expect(here(), '/sales');

    await tapAndCollect(find.text('Dashboard').last);
    expect(here(), '/dashboard');

    // Drawer-only destinations. The phone drawer carries the MANAGE group.
    for (final (label, path) in const [
      ('Store', '/store'),
      ('Help & Support', '/help'),
      ('Settings', '/settings'),
    ]) {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tapAndCollect(find.text(label).last);
      expect(here(), path, reason: 'drawer should open $path');
    }

    // Notifications has no drawer row on phones: the header bell is its entry.
    await tapAndCollect(find.byIcon(Icons.notifications_outlined).first);
    expect(here(), '/notifications');

    // Detail pages entered from their list rows/cards (the dock already proved
    // the list routes themselves are reachable by tap).
    appRouter.go('/orders');
    await tester.pumpAndSettle();
    await tapAndCollect(find.text('#ORD-001').first);
    expect(here(), startsWith('/orders/'), reason: 'order row opens details');

    appRouter.go('/products');
    await tester.pumpAndSettle();
    await tapAndCollect(find.text('Fresh Tomatoes').first);
    expect(here(), startsWith('/products/'), reason: 'product card opens details');

    expect(
      visited,
      containsAll([
        '/dashboard',
        '/orders',
        '/products',
        '/sales',
        '/store',
        '/notifications',
        '/help',
        '/settings',
      ]),
      reason: 'every shell page needs a phone entry point',
    );
    expect(tester.takeException(), isNull);
  });
}
