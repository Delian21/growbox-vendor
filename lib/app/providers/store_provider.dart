import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/store.dart';
import '../../data/mock/mock_store.dart';

class StoreProvider extends ChangeNotifier {
  Store _store = mockStore;
  bool _loaded = false;

  Store get store => _store;
  bool get isOpen => _store.isOpen;

  /// Load persisted opening hours from SharedPreferences.
  Future<void> loadFromPrefs() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getStringList('store_operating_days');
    final open = prefs.getString('store_open_time');
    final close = prefs.getString('store_close_time');
    _store = _store.copyWith(
      operatingDays: days ?? _store.operatingDays,
      openTime: open ?? _store.openTime,
      closeTime: close ?? _store.closeTime,
    );
    _loaded = true;
    notifyListeners();
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
}