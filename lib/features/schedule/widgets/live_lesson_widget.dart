import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/schedule_model.dart';
import '../../../providers/schedule_provider.dart';

/// Live lesson status widget displaying current ongoing lesson or break countdown.
class LiveLessonWidget extends ConsumerStatefulWidget {
  const LiveLessonWidget({super.key});

  @override
  ConsumerState<LiveLessonWidget> createState() => _LiveLessonWidgetState();
}

class _LiveLessonWidgetState extends ConsumerState<LiveLessonWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update live countdown every 15 seconds
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final currentMinutes = now.hour * 60 + now.minute;

    return scheduleAsync.when(
      data: (days) {
        final todaySchedule = days.firstWhere(
          (d) => d.date == todayStr,
          orElse: () => DaySchedule(
            date: todayStr,
            dayName: '',
            weekType: 'numerator',
            lessons: [],
          ),
        );

        final lessons = todaySchedule.lessons
            .where((l) => !l.isCancelled)
            .toList()
          ..sort((a, b) => a.lessonOrder.compareTo(b.lessonOrder));

        if (lessons.isEmpty) {
          return const SizedBox.shrink();
        }

        LessonSlot? ongoingLesson;
        LessonSlot? nextLesson;
        int remainingMinutes = 0;
        double progress = 0.0;
        bool isBreak = false;

        for (int i = 0; i < lessons.length; i++) {
          final l = lessons[i];
          final startMin = _parseTimeToMinutes(l.startTime);
          final endMin = _parseTimeToMinutes(l.endTime);

          if (currentMinutes >= startMin && currentMinutes < endMin) {
            ongoingLesson = l;
            remainingMinutes = endMin - currentMinutes;
            final duration = endMin - startMin;
            if (duration > 0) {
              progress = ((currentMinutes - startMin) / duration).clamp(0.0, 1.0);
            }
            if (i + 1 < lessons.length) {
              nextLesson = lessons[i + 1];
            }
            break;
          } else if (currentMinutes < startMin) {
            if (nextLesson == null) {
              nextLesson = l;
              isBreak = (i > 0 && currentMinutes >= _parseTimeToMinutes(lessons[i - 1].endTime));
              remainingMinutes = startMin - currentMinutes;
            }
          }
        }

        // Outside school hours
        if (ongoingLesson == null && nextLesson == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: LiquidGlassLens(
            style: LiquidTheme.cardStyle(isDark: isDark, radius: 22),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ongoingLesson != null
                              ? LiquidTheme.success.withValues(alpha: 0.2)
                              : LiquidTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ongoingLesson != null
                                    ? LiquidTheme.success
                                    : LiquidTheme.accentLight,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ongoingLesson != null
                                  ? loc.translate('ongoing')
                                  : (isBreak
                                      ? loc.translate('break_now')
                                      : loc.translate('upcoming')),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ongoingLesson != null
                                    ? LiquidTheme.success
                                    : LiquidTheme.accentLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$remainingMinutes ${loc.translate('minutes')}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? LiquidTheme.darkTextSecondary
                              : LiquidTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Ongoing lesson info
                  if (ongoingLesson != null) ...[
                    Row(
                      children: [
                        Text(
                          ongoingLesson.subject.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (ongoingLesson.cabinet != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x33475569) : const Color(0x33CBD5E1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${loc.translate('cab')} ${ongoingLesson.cabinet}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: isDark ? const Color(0x33334155) : const Color(0x33E2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(LiquidTheme.accent),
                      ),
                    ),
                  ],

                  // Next lesson hint
                  if (nextLesson != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${loc.translate('upcoming')}: ${nextLesson.subject.name} (${nextLesson.startTime})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? LiquidTheme.darkTextMuted
                            : LiquidTheme.lightTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
