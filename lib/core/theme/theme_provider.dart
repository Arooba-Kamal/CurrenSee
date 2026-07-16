// lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  static const String _themeKey = 'themeMode';

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  // ✅ LOAD THEME FROM SHAREDPREFERENCES
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString(_themeKey) ?? 'dark';
      _themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  // ✅ TOGGLE THEME
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  // ✅ SET THEME MODE
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveTheme();
      notifyListeners();
    }
  }

  // ✅ SAVE THEME TO SHAREDPREFERENCES
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode == ThemeMode.light ? 'light' : 'dark');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // ✅ GET CURRENT THEME NAME
  String getThemeName() {
    return _themeMode == ThemeMode.light ? 'Light' : 'Dark';
  }

  // ✅ IS DARK MODE
  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
