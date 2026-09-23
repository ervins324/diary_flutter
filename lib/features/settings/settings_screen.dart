import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../core/database/hive_boxes.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/settings_provider.dart';
import '../bells/bells_sheet.dart';
import '../server_setup/server_setup_screen.dart';
import '../subjects/subjects_sheet.dart';

/// Settings screen for server connection, sync queue, language, theme, and subjects.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<String> ukrainianRegions = [
    'м. Київ',
    'Київська область',
    'Вінницька область',
    'Волинська область',
    'Дніпропетровська область',
    'Донецька область',
    'Житомирська область',
    'Закарпатська область',
    'Запорізька область',
    'Івано-Франківська область',
    'Кіровоградська область',
    'Луганська область',
    'Львівська область',
    'Миколаївська область',
    'Одеська область',
    'Полтавська область',
    'Рівненська область',
    'Сумська область',
    'Тернопільська область',
    'Харківська область',
    'Херсонська область',
    'Хмельницька область',
    'Черкаська область',
    'Чернівецька область',
    'Чернігівська область',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverUrl = ref.watch(serverUrlProvider);
    final connStatus = ref.watch(serverConnectionProvider);
    final syncState = ref.watch(syncQueueProvider).state;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final alertState = ref.watch(airRaidAlertProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Server Connection Card ────────────────────────────
          LiquidGlassLens(
            style: LiquidTheme.cardStyle(isDark: isDark, radius: 22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: LiquidTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dns_rounded, size: 20, color: LiquidTheme.accentLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('server_connection'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              serverUrl,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status indicator dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: connStatus == ConnectionStatus.connected
                              ? LiquidTheme.success
                              : (connStatus == ConnectionStatus.checking
                                  ? LiquidTheme.warning
                                  : LiquidTheme.danger),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ServerSetupScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            side: BorderSide(
                              color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(loc.translate('edit')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(serverConnectionProvider.notifier).checkConnection();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LiquidTheme.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(loc.translate('test_connection')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Sync Queue Diagnostics Card ───────────────────────
          LiquidGlassLens(
            style: LiquidTheme.cardStyle(isDark: isDark, radius: 22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: LiquidTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sync_rounded, size: 20, color: LiquidTheme.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('sync_status'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              syncState.isSyncing
                                  ? loc.translate('syncing')
                                  : '${loc.translate('pending_sync')}: ${syncState.pendingCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (syncState.isSyncing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: LiquidTheme.accentLight),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            ref.read(syncQueueProvider).processQueue();
                          },
                          child: Text(
                            loc.translate('sync_now'),
                            style: const TextStyle(color: LiquidTheme.accentLight),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── App Settings (Language, Theme, Alert Region) ───────
          LiquidGlassLens(
            style: LiquidTheme.cardStyle(isDark: isDark, radius: 22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.translate('language'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'uk', label: Text('Укр')),
                          ButtonSegment(value: 'en', label: Text('Eng')),
                        ],
                        selected: {locale.languageCode},
                        onSelectionChanged: (set) {
                          ref.read(localeProvider.notifier).setLocale(set.first);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Theme Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.translate('theme'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode_rounded, size: 16),
                            label: Text(loc.translate('theme_dark')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.light_mode_rounded, size: 16),
                            label: Text(loc.translate('theme_light')),
                          ),
                        ],
                        selected: {themeMode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark},
                        onSelectionChanged: (set) {
                          ref.read(themeModeProvider.notifier).setThemeMode(set.first);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Alert Region Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('select_region'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: alertState.activeRegion,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: ukrainianRegions.map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(r, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(airRaidAlertProvider.notifier).updateRegion(val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Academic Configuration Buttons ────────────────────
          LiquidGlassLens(
            style: LiquidTheme.cardStyle(isDark: isDark, radius: 22),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.book_rounded, color: LiquidTheme.accentLight),
                    title: Text(
                      loc.translate('subjects'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SubjectsSheet(),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent),
                    title: Text(
                      loc.translate('bells'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const BellsSheet(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Clear cache
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await HiveBoxes.clearAllCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Local cache cleared')),
                  );
                }
              },
              icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: LiquidTheme.danger),
              label: const Text('Clear Local Cache', style: TextStyle(color: LiquidTheme.danger)),
            ),
          ),
        ],
      ),
    );
  }
}
