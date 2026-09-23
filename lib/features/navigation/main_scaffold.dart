import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/ambient_background.dart';
import '../../core/theme/liquid_theme.dart';
import '../../providers/api_client_provider.dart';
import '../alerts/widgets/air_raid_banner.dart';
import '../homework/homework_screen.dart';
import '../notes/notes_screen.dart';
import '../schedule/schedule_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

/// Main application layout featuring LiquidGlass refraction, ambient mesh background, and glass navigation bar.
class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(selectedTabIndexProvider);
    final connStatus = ref.watch(serverConnectionProvider);
    final syncState = ref.watch(syncQueueProvider).state;
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = const [
      ScheduleScreen(),
      HomeworkScreen(),
      NotesScreen(),
      StatsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: LiquidGlassView(
        backgroundWidget: AmbientBackground(
          isDark: isDark,
          child: const SizedBox.expand(),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
              children: [
                // Top floating app bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        loc.translate('app_title'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),

                      // Syncing indicator
                      if (syncState.isSyncing) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LiquidTheme.accentLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],

                      // Connection badge dot
                      Tooltip(
                        message: connStatus == ConnectionStatus.connected
                            ? 'Online'
                            : 'Offline (Local Cache)',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: connStatus == ConnectionStatus.connected
                                ? LiquidTheme.success.withValues(alpha: 0.15)
                                : LiquidTheme.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: connStatus == ConnectionStatus.connected
                                  ? LiquidTheme.success.withValues(alpha: 0.4)
                                  : LiquidTheme.danger.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: connStatus == ConnectionStatus.connected
                                      ? LiquidTheme.success
                                      : LiquidTheme.danger,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                connStatus == ConnectionStatus.connected ? 'ONLINE' : 'OFFLINE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: connStatus == ConnectionStatus.connected
                                      ? LiquidTheme.success
                                      : LiquidTheme.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Air Raid Alert Banner
                const AirRaidBanner(),

                // Active tab screen
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Liquid Glass Bottom Navigation Bar
        bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: LiquidGlassLens(
            style: LiquidTheme.navBarStyle(isDark: isDark),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    ref: ref,
                    index: 0,
                    icon: Icons.calendar_today_rounded,
                    label: loc.translate('nav_schedule'),
                    isSelected: currentIndex == 0,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    ref: ref,
                    index: 1,
                    icon: Icons.assignment_rounded,
                    label: loc.translate('nav_homework'),
                    isSelected: currentIndex == 1,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    ref: ref,
                    index: 2,
                    icon: Icons.edit_note_rounded,
                    label: loc.translate('nav_notes'),
                    isSelected: currentIndex == 2,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    ref: ref,
                    index: 3,
                    icon: Icons.bar_chart_rounded,
                    label: loc.translate('nav_stats'),
                    isSelected: currentIndex == 3,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    ref: ref,
                    index: 4,
                    icon: Icons.settings_rounded,
                    label: loc.translate('nav_settings'),
                    isSelected: currentIndex == 4,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedTabIndexProvider.notifier).state = index;
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0x336366F1) : const Color(0x336366F1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? LiquidTheme.accentLight
                  : (isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? LiquidTheme.accentLight
                    : (isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
