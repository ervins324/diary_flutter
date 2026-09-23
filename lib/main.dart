import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/hive_boxes.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/liquid_theme.dart';
import 'features/navigation/main_scaffold.dart';
import 'providers/settings_provider.dart';

import 'package:liquid_glass_easy/liquid_glass_easy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  LiquidGlassEngine.liteGlassOnSkia = true;
  LiquidGlassEngine.liteGlassOnImpeller = true;
  LiquidGlassEngine.litePickup = LiquidGlassLitePickup.blend;
  runApp(const ProviderScope(child: DiaryApp()));
}

class DiaryApp extends ConsumerWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'School Diary',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [
        Locale('uk'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: LiquidTheme.lightBg,
        colorScheme: const ColorScheme.light(
          primary: LiquidTheme.accent,
          surface: LiquidTheme.lightBg,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: LiquidTheme.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: LiquidTheme.accent,
          surface: LiquidTheme.darkBg,
        ),
      ),
      home: const MainScaffold(),
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
