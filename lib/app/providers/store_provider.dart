import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/store.dart';
import '../../data/mock/mock_store.dart';
import 'auth_provider.dart';

class StoreProvider extends ChangeNotifier {
  /// [auth] supplies the account's business name. Until the vendor has saved
  /// a store name of their own, that account name IS the store's name — the
  /// Store page used to open on the mock "Farm Fresh Ltd" while the sidebar
  /// and Settings showed the account name.
  StoreProvider({this.auth}) {
    auth?.addListener(_onAccountChanged);
    // No listeners exist yet, so the first build simply reads the result.
    _syncVendorName();
  }

  /// The account whose business name seeds the store name (see above).
  final AuthProvider? auth;

  Store _store = mockStore;
  bool _loaded = false;

  /// Prefs keys for the two store photos (base64 data URLs). On web these live
  /// in localStorage, which is why the picker compresses before saving.
  static const String _logoKey = 'store_logo_url';
  static const String _bannerKey = 'store_banner_url';

  /// TEST HOOK — debug builds only. Makes the next [updateStore] report a
  /// storage failure so the rollback/error path can be exercised.
  bool debugFailNextSave = false;

  /// TEST HOOK — debug builds only. Lets the logo write land and then fails
  /// before/at the banner write, so the "first write succeeded, second
  /// failed" rollback can be exercised.
  bool debugFailBannerWrite = false;

  /// True once the vendor has saved their own store name — loaded from prefs
  /// or typed in the Edit Store sheet. From then on the account name never
  /// overwrites it.
  bool _hasOwnName = false;

  Store get store => _store;
  bool get isOpen => _store.isOpen;

  /// Load the persisted store name and opening hours from SharedPreferences.
  Future<void> loadFromPrefs() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getStringList('store_operating_days');
    final open = prefs.getString('store_open_time');
    final close = prefs.getString('store_close_time');
    final savedName = prefs.getString('store_name');
    if (savedName != null && savedName.trim().isNotEmpty) {
      _hasOwnName = true;
    }
    // Photos saved by an older build may be larger than today's budget: they
    // load exactly as before and are re-compressed the next time the vendor
    // saves the sheet.
    final logo = prefs.getString(_logoKey);
    final banner = prefs.getString(_bannerKey);
    _store = _store.copyWith(
      name: _hasOwnName ? savedName : _store.name,
      operatingDays: days ?? _store.operatingDays,
      openTime: open ?? _store.openTime,
      closeTime: close ?? _store.closeTime,
      logoUrl: logo != null && logo.isNotEmpty ? logo : _store.logoUrl,
      bannerUrl: banner != null && banner.isNotEmpty ? banner : _store.bannerUrl,
    );
    _loaded = true;
    // A signed-in vendor whose store has no saved name yet adopts it now.
    _syncVendorName();
    notifyListeners();
  }

  void _onAccountChanged() {
    if (_syncVendorName()) notifyListeners();
  }

  /// Adopts the account's business name while the store has no name of its
  /// own. Returns true when the name actually changed.
  bool _syncVendorName() {
    if (_hasOwnName) return false;
    final name = auth?.vendorName?.trim();
    if (name == null || name.isEmpty || name == _store.name) return false;
    _store = _store.copyWith(name: name);
    return true;
  }

  @override
  void dispose() {
    auth?.removeListener(_onAccountChanged);
    super.dispose();
  }

  void toggleStoreStatus() {
    _store = _store.copyWith(isOpen: !_store.isOpen);
    notifyListeners();
  }

  /// Saves the store fields, including the two photos.
  ///
  /// Returns false when the storage write fails. The in-memory store is put
  /// back to exactly what it was first, so a failed save can never leave the
  /// new image showing as if it had been saved.
  Future<bool> updateStore({
    String? name,
    String? description,
    String? businessCategory,
    String? phone,
    String? email,
    String? location,
    String? logoUrl,
    String? bannerUrl,
  }) async {
    final previous = _store;
    final previousHasOwnName = _hasOwnName;
    // A name typed on the Store page is the store's OWN display name — but
    // only when it actually differs from the current one. The Edit Store
    // sheet always sends every field, so an unrelated save (say a new
    // description) must not quietly claim the name that the account is still
    // supplying. Once a real rename has been saved, setting the name back to
    // the account's value is still the vendor's own choice and stays pinned.
    final ownName = name?.trim();
    if (ownName != null &&
        ownName.isNotEmpty &&
        ownName != _store.name.trim()) {
      _hasOwnName = true;
      _persistName(ownName);
    }
    _store = _store.copyWith(
      name: name,
      description: description,
      businessCategory: businessCategory,
      phone: phone,
      email: email,
      location: location,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
    );
    notifyListeners();

    SharedPreferences? prefs;
    String? previousLogo;
    String? previousBanner;
    try {
      // TEST HOOK (debug only): simulate a storage failure.
      if (kDebugMode && debugFailNextSave) {
        debugFailNextSave = false;
        throw StateError('simulated store save failure');
      }
      prefs = await SharedPreferences.getInstance();
      // Snapshot what is stored right now: the two writes are not atomic, so
      // the logo can land while the banner write fails.
      previousLogo = prefs.getString(_logoKey);
      previousBanner = prefs.getString(_bannerKey);
      final logoSaved = await prefs.setString(_logoKey, _store.logoUrl);
      if (!logoSaved) throw StateError('the store logo was not persisted');
      // TEST HOOK (debug only): the logo write has landed, fail the banner.
      if (kDebugMode && debugFailBannerWrite) {
        debugFailBannerWrite = false;
        throw StateError('simulated banner write failure');
      }
      final bannerSaved = await prefs.setString(_bannerKey, _store.bannerUrl);
      // setString reports success; a false means the value was not stored.
      if (!bannerSaved) throw StateError('the store banner was not persisted');
    } catch (_) {
      // Put the STORED values back too, not just the in-memory store: a
      // half-written save would otherwise resurrect the new logo after a
      // reload. Best effort — the memory rollback below still applies.
      if (prefs != null) {
        await _restoreStoredValue(prefs, _logoKey, previousLogo);
        await _restoreStoredValue(prefs, _bannerKey, previousBanner);
      }
      // Roll the whole update back — name flag included — so nothing shows as
      // saved and the previous image stays in place.
      _store = previous;
      _hasOwnName = previousHasOwnName;
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Reinstates one stored photo value: the old string, or no key at all when
  /// there was nothing stored before. Never throws — a broken store must not
  /// turn the rollback itself into the failure.
  Future<void> _restoreStoredValue(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    try {
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    } catch (_) {
      // Ignored: the in-memory store is rolled back regardless.
    }
  }

  /// Update opening hours and persist to SharedPreferences.
  void updateOpeningHours({
    required List<String> operatingDays,
    required String openTime,
    required String closeTime,
  }) {
    _store = _store.copyWith(
      operatingDays: operatingDays,
      openTime: openTime,
      closeTime: closeTime,
    );
    _persistOpeningHours();
    notifyListeners();
  }

  Future<void> _persistOpeningHours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('store_operating_days', _store.operatingDays);
    await prefs.setString('store_open_time', _store.openTime);
    await prefs.setString('store_close_time', _store.closeTime);
  }

  /// Saves the vendor's own store name so a reload (or a later sign-in) keeps
  /// showing it instead of falling back to the account name.
  Future<void> _persistName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_name', name);
  }
}