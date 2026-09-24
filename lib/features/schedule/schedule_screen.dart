import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../models/schedule_model.dart';
import '../../providers/schedule_provider.dart';
import '../server_setup/server_setup_screen.dart';
import 'widgets/live_lesson_widget.dart';
import 'widgets/week_selector.dart';
import 'widgets/lesson_slot_card.dart';
import 'widgets/lesson_detail_sheet.dart';

/// Primary Schedule tab presenting daily lessons, live lesson timer, and week switcher.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final hasOfflineWarning = ref.watch(scheduleOfflineWarningProvider);
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(scheduleProvider.notifier).refresh(selectedDate);
      },
      color: LiquidTheme.accent,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Live lesson tracker
          const SliverToBoxAdapter(
            child: LiveLessonWidget(),
          ),

          // Week and day selector
          const SliverToBoxAdapter(
            child: WeekSelector(),
          ),

          // Server offline notice banner if unreachable
          if (hasOfflineWarning)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: LiquidGlassLens(
                  style: LiquidTheme.cardStyle(isDark: isDark, radius: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.translate('server_unreachable_desc'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ServerSetupScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            loc.translate('edit'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LiquidTheme.accentLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),

          // Lessons list
          scheduleAsync.when(
            data: (days) {
              final activeDay = days.firstWhere(
                (d) => d.date == selectedDateStr,
                orElse: () => DaySchedule(
                  date: selectedDateStr,
                  dayName: '',
                  weekType: 'numerator',
                  lessons: [],
                ),
              );

              if (activeDay.isHoliday) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration_rounded,
                          size: 56,
                          color: Colors.amberAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeDay.holidayName ?? 'Holiday',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (activeDay.lessons.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.translate('no_lessons_scheduled'),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final sortedLessons = [...activeDay.lessons]
                ..sort((a, b) => a.lessonOrder.compareTo(b.lessonOrder));

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lesson = sortedLessons[index];
                    return LessonSlotCard(
                      lesson: lesson,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => LessonDetailSheet(lesson: lesson),
                        );
                      },
                    );
                  },
                  childCount: sortedLessons.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: LiquidTheme.accent),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 56,
                        color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.translate('server_unreachable_title'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.translate('server_unreachable_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ServerSetupScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.dns_rounded, size: 16),
                            label: Text(loc.translate('server_connection')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LiquidTheme.accentLight,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(scheduleProvider.notifier).refresh(selectedDate);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(loc.translate('retry')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LiquidTheme.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Padding for bottom nav bar
          ),
        ],
      ),
    );
  }
}
