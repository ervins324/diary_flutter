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

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ShowClassroomsNotifier extends StateNotifier<bool> {
  ShowClassroomsNotifier() : super(HiveBoxes.getShowClassrooms());

  void toggle(bool val) {
    HiveBoxes.setShowClassrooms(val);
    state = val;
  }
}

final showClassroomsProvider =
    StateNotifierProvider<ShowClassroomsNotifier, bool>((ref) {
      return ShowClassroomsNotifier();
    });

class SkipWeekendsNotifier extends StateNotifier<bool> {
  SkipWeekendsNotifier() : super(HiveBoxes.getSkipWeekends());

  void toggle(bool val) {
    HiveBoxes.setSkipWeekends(val);
    state = val;
  }
}

final skipWeekendsProvider = StateNotifierProvider<SkipWeekendsNotifier, bool>((
  ref,
) {
  return SkipWeekendsNotifier();
});

class PerformanceModeNotifier extends StateNotifier<bool> {
  PerformanceModeNotifier() : super(HiveBoxes.getPerformanceMode());

  void toggle(bool val) {
    HiveBoxes.setPerformanceMode(val);
    state = val;
  }
}

final performanceModeProvider =
    StateNotifierProvider<PerformanceModeNotifier, bool>((ref) {
      return PerformanceModeNotifier();
    });
