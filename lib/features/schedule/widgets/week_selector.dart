import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../providers/schedule_provider.dart';

/// Top header for switching weeks and selecting active day of the week.
class WeekSelector extends ConsumerWidget {
  const WeekSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final monday = getMonday(selectedDate);
    final weekType = calculateWeekType(selectedDate);
    final isNumerator = weekType == 'numerator';

    final days = List.generate(6, (i) => monday.add(Duration(days: i)));
    final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Week bar (Previous / Title / Next)
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final prevWeek = selectedDate.subtract(const Duration(days: 7));
                  ref.read(selectedDateProvider.notifier).state = prevWeek;
                  ref.read(scheduleProvider.notifier).loadWeekSchedule(prevWeek);
                },
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: isDark ? Colors.white70 : Colors.black87,
              ),

              Expanded(
                child: Center(
                  child: LiquidGlassLens(
                    style: LiquidTheme.pillStyle(isDark: isDark, radius: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNumerator
                              ? LiquidTheme.accent.withValues(alpha: 0.5)
                              : Colors.purpleAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNumerator ? Icons.looks_one_rounded : Icons.looks_two_rounded,
                            size: 16,
                            color: isNumerator ? LiquidTheme.accentLight : Colors.purpleAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isNumerator
                                ? loc.translate('numerator_week')
                                : loc.translate('denominator_week'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  final nextWeek = selectedDate.add(const Duration(days: 7));
                  ref.read(selectedDateProvider.notifier).state = nextWeek;
                  ref.read(scheduleProvider.notifier).loadWeekSchedule(nextWeek);
                },
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Day chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final d = days[index];
              final isSelected = d.year == selectedDate.year &&
                  d.month == selectedDate.month &&
                  d.day == selectedDate.day;
              final isToday = d.year == DateTime.now().year &&
                  d.month == DateTime.now().month &&
                  d.day == DateTime.now().day;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = d;
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: LiquidGlassLens(
                      style: LiquidGlassStyle(
                        shape: const LiquidGlassShape.continuousRoundedRectangle(
                          cornerRadius: 14.0,
                        ),
                        appearance: LiquidGlassAppearance(
                          color: isSelected
                              ? (isDark ? const Color(0x666366F1) : const Color(0xCC6366F1))
                              : (isDark ? const Color(0x1A1E293B) : const Color(0x33CBD5E1)),
                          blur: const LiquidGlassBlur(sigmaX: 12.0, sigmaY: 12.0),
                        ),
                        refraction: const LiquidGlassRefraction(distortion: 0.04),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: isSelected
                                ? LiquidTheme.accentLight
                                : (isToday
                                    ? LiquidTheme.accent.withValues(alpha: 0.4)
                                    : Colors.transparent),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              loc.translate(dayKeys[index]),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? LiquidTheme.darkTextSecondary
                                        : LiquidTheme.lightTextSecondary),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
