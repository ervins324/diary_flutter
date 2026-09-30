import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/settings_provider.dart';

/// Top header for switching weeks and selecting active day of the week.
class WeekSelector extends ConsumerWidget {
  const WeekSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isPerfMode = ref.watch(performanceModeProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final monday = getMonday(selectedDate);
    final weekType = calculateWeekType(selectedDate);
    final isNumerator = weekType == 'numerator';

    final days = List.generate(6, (i) => monday.add(Duration(days: i)));
    final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

    final weekTypePillContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isPerfMode
            ? (isDark ? const Color(0x381E293B) : const Color(0xB3FFFFFF))
            : null,
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
    );

    final wrappedWeekTypePill = isPerfMode
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: weekTypePillContent,
          )
        : LiquidGlassLens(
            style: LiquidTheme.pillStyle(isDark: isDark, radius: 16),
            child: weekTypePillContent,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Week bar (Previous / Title / Next)
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final prevWeek = selectedDate.subtract(
                    const Duration(days: 7),
                  );
                  ref.read(selectedDateProvider.notifier).state = prevWeek;
                  ref
                      .read(scheduleProvider.notifier)
                      .loadWeekSchedule(prevWeek);
                },
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: isDark ? Colors.white70 : Colors.black87,
              ),

              Expanded(child: Center(child: wrappedWeekTypePill)),

              IconButton(
                onPressed: () {
                  final nextWeek = selectedDate.add(const Duration(days: 7));
                  ref.read(selectedDateProvider.notifier).state = nextWeek;
                  ref
                      .read(scheduleProvider.notifier)
                      .loadWeekSchedule(nextWeek);
                },
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Day chips track with smooth sliding liquid glass capsule
          Builder(
            builder: (context) {
              final selectedDayIndex = days.indexWhere(
                (d) =>
                    d.year == selectedDate.year &&
                    d.month == selectedDate.month &&
                    d.day == selectedDate.day,
              );
              final validDayIndex = selectedDayIndex >= 0
                  ? selectedDayIndex
                  : 0;

              final daySelectorContent = Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isPerfMode
                      ? (isDark
                            ? const Color(0x381E293B)
                            : const Color(0xB3FFFFFF))
                      : (isDark
                            ? const Color(0x221E293B)
                            : const Color(0x80FFFFFF)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? LiquidTheme.darkBorder
                        : LiquidTheme.lightBorder,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / 6;

                    return Stack(
                      children: [
                        // Smooth sliding liquid glass indicator capsule
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          left: validDayIndex * itemWidth,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        LiquidTheme.accent.withValues(
                                          alpha: 0.5,
                                        ),
                                        Colors.purpleAccent.withValues(
                                          alpha: 0.35,
                                        ),
                                      ]
                                    : [
                                        LiquidTheme.accent.withValues(
                                          alpha: 0.35,
                                        ),
                                        Colors.purpleAccent.withValues(
                                          alpha: 0.22,
                                        ),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: isDark
                                    ? LiquidTheme.accentLight.withValues(
                                        alpha: 0.6,
                                      )
                                    : LiquidTheme.accent.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: LiquidTheme.accent.withValues(
                                    alpha: isDark ? 0.35 : 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Interactive 6 day chips
                        Row(
                          children: List.generate(6, (index) {
                            final d = days[index];
                            final isSelected = index == validDayIndex;
                            final isToday =
                                d.year == DateTime.now().year &&
                                d.month == DateTime.now().month &&
                                d.day == DateTime.now().day;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  ref
                                          .read(selectedDateProvider.notifier)
                                          .state =
                                      d;
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark
                                                        ? LiquidTheme
                                                              .darkTextSecondary
                                                        : LiquidTheme
                                                              .lightTextSecondary),
                                            ),
                                            child: Text(
                                              loc.translate(dayKeys[index]),
                                            ),
                                          ),
                                          if (isToday) ...[
                                            const SizedBox(width: 3),
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? Colors.white
                                                    : LiquidTheme.accentLight,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white70
                                                    : Colors.black87),
                                        ),
                                        child: Text('${d.day}'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              );

              return isPerfMode
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: daySelectorContent,
                    )
                  : LiquidGlassLens(
                      style: LiquidGlassStyle(
                        shape:
                            const LiquidGlassShape.continuousRoundedRectangle(
                              cornerRadius: 16.0,
                            ),
                        appearance: LiquidGlassAppearance(
                          color: isDark
                              ? const Color(0x1A1E293B)
                              : const Color(0x33CBD5E1),
                          blur: const LiquidGlassBlur(sigmaX: 4.0, sigmaY: 4.0),
                        ),
                        refraction: const LiquidGlassRefraction(
                          distortion: 0.04,
                        ),
                        liteGlass: LiquidGlassLitePickup.blend,
                      ),
                      child: daySelectorContent,
                    );
            },
          ),
        ],
      ),
    );
  }
}
