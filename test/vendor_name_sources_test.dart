import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/app/providers/auth_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/core/utils/formatters.dart';
import 'package:growbox_vendor/main.dart';

import 'load_roboto.dart';

/// The business name has one source: AuthProvider. Settings used to hardcode
/// "Green Harvest Farms" while the sidebar read the provider, so the two
/// screens disagreed; this pins them together. Also pins dd/mm/yyyy dates.
void main() {
  test('dates render as zero-padded dd/mm/yyyy', () {
    expect(formatDateDdMmYyyy(DateTime(2026, 3, 4)), '04/03/2026');
    expect(formatDateDdMmYyyy(DateTime(2026, 11, 11)), '11/11/2026');
    expect(formatDateDdMmYyyy(DateTime(2026, 12, 31)), '31/12/2026');
  });

  testWidgets('settings shows the signed-in vendor name, not the old literal',
      (tester) async {
    await tester.runAsync(loadRoboto);
    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 5)); // splash
    await tester.pumpAndSettle();

    final auth = Provider.of<AuthProvider>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    final pending = auth.login('vendor@example.com', 'secret123');
    await tester.pump(const Duration(seconds: 1));
    await pending;
    await tester.pumpAndSettle();

    appRouter.go('/settings');
    await tester.pumpAndSettle();

    // Profile card + payout holder both read the account name.
    expect(find.text('Farm Fresh Enterprises'), findsWidgets,
        reason: 'settings must read AuthProvider.vendorName');
    expect(find.text('Green Harvest Farms'), findsNothing,
        reason: 'the hardcoded business name must be gone');
    expect(tester.takeException(), isNull);
  });
}
