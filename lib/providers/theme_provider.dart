import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeKey = "theme_mode";
  int _cardStyleIndex = 0;
  static const String _cardStyleKey = "card_style";

  ThemeMode get themeMode => _themeMode;
  int get cardStyleIndex => _cardStyleIndex;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeStr = prefs.getString(_themeKey);
    _cardStyleIndex = prefs.getInt(_cardStyleKey) ?? 0;

    if (themeStr != null) {
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await prefs.setString(_themeKey, val);
  }

  Future<void> setCardStyle(int index) async {
    _cardStyleIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cardStyleKey, index);
  }
}
