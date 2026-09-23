import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../models/schedule_model.dart';
import '../../providers/schedule_provider.dart';
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
                child: Text('Error loading schedule: $err'),
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
