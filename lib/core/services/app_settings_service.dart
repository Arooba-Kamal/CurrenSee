// lib/core/services/app_settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _languageCode = 'en';
  
  late SharedPreferences _prefs;

  AppSettingsService() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;

  // ✅ LOAD SETTINGS FROM SHAREDPREFERENCES
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    final theme = _prefs.getString('themeMode') ?? 'dark';
    _themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
    
    _languageCode = _prefs.getString('languageCode') ?? 'en';
    
    notifyListeners();
  }

  // ✅ SET THEME MODE
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _prefs.setString('themeMode', mode == ThemeMode.light ? 'light' : 'dark');
      notifyListeners();
    }
  }

  // ✅ SET LANGUAGE CODE
  void setLanguageCode(String code) {
    if (_languageCode != code) {
      _languageCode = code;
      _prefs.setString('languageCode', code);
      notifyListeners();
    }
  }

  // ✅ UPDATE LANGUAGE (Alias)
  void updateLanguageCode(String code) {
    setLanguageCode(code);
  }

  // ✅ TOGGLE THEME
  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  // ✅ GET CURRENT THEME NAME
  String getThemeName() {
    return _themeMode == ThemeMode.dark ? 'Dark' : 'Light';
  }

  // ✅ GET LANGUAGE NAME
  String getLanguageName() {
    switch (_languageCode) {
      case 'ur': return 'Urdu';
      case 'ar': return 'Arabic';
      case 'zh': return 'Chinese';
      case 'es': return 'Spanish';
      case 'fr': return 'French';
      default: return 'English';
    }
  }
}