import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/hive_boxes.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(Locale(HiveBoxes.getLanguage()));

  void setLocale(String languageCode) {
    HiveBoxes.setLanguage(languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_parseMode(HiveBoxes.getThemeMode()));

  static ThemeMode _parseMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    String str = 'system';
    if (mode == ThemeMode.dark) str = 'dark';
    if (mode == ThemeMode.light) str = 'light';
    HiveBoxes.setThemeMode(str);
    state = mode;
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
