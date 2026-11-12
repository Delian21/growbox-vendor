import 'package:flutter/material.dart';
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
    _store = _store.copyWith(
      name: _hasOwnName ? savedName : _store.name,
      operatingDays: days ?? _store.operatingDays,
      openTime: open ?? _store.openTime,
      closeTime: close ?? _store.closeTime,
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

  void updateStore({
    String? name,
    String? description,
    String? businessCategory,
    String? phone,
    String? email,
    String? location,
    String? logoUrl,
    String? bannerUrl,
  }) {
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