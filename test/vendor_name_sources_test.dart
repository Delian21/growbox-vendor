import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/app/providers/auth_provider.dart';
import 'package:growbox_vendor/app/providers/store_provider.dart';
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
    await tester.pump(const Duration(seconds: 1)); // splash
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

  // ── Store name: seeded from the account, then owned by the vendor ─────

  test('store name starts from the account, then an edit becomes its own',
      () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthProvider();
    final store = StoreProvider(auth: auth);

    // Nobody signed in yet → the seeded store keeps its mock name.
    expect(store.store.name, 'Farm Fresh Ltd');

    await auth.login('vendor@example.com', 'secret123');
    expect(store.store.name, 'Farm Fresh Enterprises',
        reason: 'the account name is the store name until it is edited');

    store.updateStore(name: 'Kaduna Greens');
    expect(store.store.name, 'Kaduna Greens');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Signing in again must not undo the vendor's own store name.
    await auth.login('vendor@example.com', 'secret123');
    expect(store.store.name, 'Kaduna Greens');

    // The edit was persisted, so a fresh provider loads it on start-up.
    final reloaded = StoreProvider(auth: auth);
    await reloaded.loadFromPrefs();
    expect(reloaded.store.name, 'Kaduna Greens',
        reason: 'an edited store name survives a reload');
  });

  testWidgets('first run: sidebar, Settings and Store agree on the account name',
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
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final auth = Provider.of<AuthProvider>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    final pending = auth.login('vendor@example.com', 'secret123');
    await tester.pump(const Duration(seconds: 1));
    await pending;
    await tester.pumpAndSettle();

    appRouter.go('/store');
    await tester.pumpAndSettle();
    expect(find.text('Farm Fresh Enterprises'), findsWidgets,
        reason: 'the Store page starts from the account name');
    expect(find.text('Farm Fresh Ltd'), findsNothing,
        reason: 'the mock name is never shown as the business name');

    appRouter.go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Farm Fresh Enterprises'), findsWidgets,
        reason: 'Settings reads the same account name');

    appRouter.go('/dashboard');
    await tester.pumpAndSettle();
    expect(find.text('Farm Fresh Enterprises'), findsWidgets,
        reason: 'the sidebar account strip agrees with both');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing the Store name saves it as the store display name',
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
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final auth = Provider.of<AuthProvider>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    final pending = auth.login('vendor@example.com', 'secret123');
    await tester.pump(const Duration(seconds: 1));
    await pending;
    await tester.pumpAndSettle();

    appRouter.go('/store');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Store'));
    await tester.pumpAndSettle();
    // First field in the sheet is 'Store Name'.
    await tester.enterText(find.byType(TextFormField).first, 'Kaduna Greens');
    // The sheet scrolls; save lives at its bottom.
    await tester.dragUntilVisible(find.text('Save Changes'),
        find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // The storefront shows the vendor's own name…
    expect(find.text('Kaduna Greens'), findsOneWidget);
    expect(find.text('Farm Fresh Ltd'), findsNothing);
    // …while the account identity in the sidebar is untouched.
    expect(find.text('Farm Fresh Enterprises'), findsOneWidget,
        reason: 'the sidebar keeps showing the account name');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('store_name'), 'Kaduna Greens',
        reason: 'the edited name is saved for the next start-up');
    expect(tester.takeException(), isNull);
  });

  // ── Name ownership: only a real rename claims the name ────────────────

  test('saving unrelated fields keeps the account name in charge', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = _RenamingAuth();
    final store = StoreProvider(auth: auth);

    await auth.login('vendor@example.com', 'secret123');
    expect(store.store.name, 'Farm Fresh Enterprises');

    // The Edit Store sheet always submits the name field; here it is unchanged
    // and only the description was edited.
    store.updateStore(
      name: 'Farm Fresh Enterprises',
      description: 'Now with cold storage',
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('store_name'), isNull,
        reason: 'an unchanged name is not a rename and must not be saved');
    expect(store.store.description, 'Now with cold storage');

    // The account name still drives the store name.
    auth.nextLoginName = 'Green Valley Co';
    await auth.login('other@example.com', 'secret123');
    expect(store.store.name, 'Green Valley Co');
  });

  test('renaming back to the account name keeps the store name pinned',
      () async {
    SharedPreferences.setMockInitialValues({});
    final auth = _RenamingAuth();
    final store = StoreProvider(auth: auth);
    await auth.login('vendor@example.com', 'secret123');

    store.updateStore(name: 'Kaduna Greens');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Deliberately typing the account's own name is still a store rename.
    store.updateStore(name: 'Farm Fresh Enterprises');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('store_name'), 'Farm Fresh Enterprises');

    // …so a later account with a different name does not overwrite it.
    auth.nextLoginName = 'Another Farm Ltd';
    await auth.login('third@example.com', 'secret123');
    expect(store.store.name, 'Farm Fresh Enterprises',
        reason: 'a saved store name stays the vendor\'s own');
  });

  testWidgets('an unrelated sheet save keeps the store name following the '
      'account', (tester) async {
    await tester.runAsync(loadRoboto);
    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = _RenamingAuth();
    final baseProviders = growboxProviders()
        .where((p) => p is! ChangeNotifierProvider<AuthProvider>)
        .toList();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ...baseProviders,
      ],
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final login = auth.login('vendor@example.com', 'secret123');
    await tester.pump();
    await login;
    await tester.pumpAndSettle();

    appRouter.go('/store');
    await tester.pumpAndSettle();
    expect(find.text('Farm Fresh Enterprises'), findsWidgets);

    await tester.tap(find.text('Edit Store'));
    await tester.pumpAndSettle();
    expect(find.text('Store display name'), findsOneWidget,
        reason: 'the field is the shopfront label, not the account name');

    // Edit only the description; the sheet still sends the unchanged name.
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Now with cold storage');
    await tester.dragUntilVisible(find.text('Save Changes'),
        find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('store_name'), isNull,
        reason: 'an unrelated save must not claim the name');

    // A different account signing in still drives the store name.
    auth.nextLoginName = 'Green Valley Co';
    final relogin = auth.login('other@example.com', 'secret123');
    await tester.pump();
    await relogin;
    await tester.pumpAndSettle();

    expect(find.text('Green Valley Co'), findsWidgets,
        reason: 'the Store page follows the new account name');
    expect(find.text('Farm Fresh Enterprises'), findsNothing);
    final store = Provider.of<StoreProvider>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    expect(store.store.name, 'Green Valley Co');
    expect(tester.takeException(), isNull);
  });
}

/// AuthProvider whose business name a test can set per login — the real one
/// always signs in with the same fixture name.
class _RenamingAuth extends AuthProvider {
  String? _name;

  /// The business name the next [login] signs in with.
  String nextLoginName = 'Farm Fresh Enterprises';

  @override
  String? get vendorName => _name;

  @override
  Future<bool> login(String email, String password) async {
    _name = nextLoginName;
    notifyListeners();
    return true;
  }
}
