import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  bool get isSystem => _themeMode == ThemeMode.system;

  String get themeLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  ThemeProvider() {
    _loadThemeMode();
  }

  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_themeKey);
      if (savedIndex != null && savedIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedIndex];
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, keep default (system)
      debugPrint('Failed to load theme mode: $e');
    }
  }

  /// Save theme mode to SharedPreferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }

  /// Cycles through: System → Light → Dark → System
  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    _saveThemeMode();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }
}