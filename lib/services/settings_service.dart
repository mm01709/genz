import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  // تحميل الإعدادات عند بدء التطبيق
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // تحميل الثيم
    String? theme = prefs.getString('theme_mode');
    if (theme == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else if (theme == 'light') {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.system;
    }

    // تحميل اللغة
    String? lang = prefs.getString('language_code');
    if (lang != null) {
      locale.value = Locale(lang);
    }
  }

  // تغيير وحفظ الثيم
  static Future<void> updateThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeString = 'system';
    if (mode == ThemeMode.dark) themeString = 'dark';
    if (mode == ThemeMode.light) themeString = 'light';
    await prefs.setString('theme_mode', themeString);
  }

  // تغيير وحفظ اللغة
  static Future<void> updateLocale(Locale newLocale) async {
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }
}