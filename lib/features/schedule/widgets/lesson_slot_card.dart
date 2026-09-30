import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/schedule_model.dart';
import '../../../models/subject_model.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/settings_provider.dart';
import 'lesson_detail_sheet.dart';
import 'lesson_override_sheet.dart';

Color parseHexColor(String hexColor) {
  try {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return LiquidTheme.accent;
  }
}

Color getEventColor(String? eventType) {
  switch (eventType) {
    case 'control_work':
      return const Color(0xFFF43F5E);
    case 'test':
      return const Color(0xFFF59E0B);
    case 'essay':
      return const Color(0xFFA855F7);
    case 'project':
      return const Color(0xFF0EA5E9);
    case 'consultation':
      return const Color(0xFF6366F1);
    default:
      return LiquidTheme.warning;
  }
}

String getEventIcon(String? eventType) {
  switch (eventType) {
    case 'control_work':
      return '🔥';
    case 'test':
      return '📝';
    case 'essay':
      return '✍️';
    case 'project':
      return '🚀';
    case 'consultation':
      return '💬';
    default:
      return '🎓';
  }
}

/// Liquid glass card representing a single lesson slot in the daily schedule.
class LessonSlotCard extends ConsumerWidget {
  final LessonSlot lesson;
  final VoidCallback onTap;

  const LessonSlotCard({super.key, required this.lesson, required this.onTap});

  Future<void> _navigateToAdjacent(
    BuildContext context,
    WidgetRef ref, {
    required bool isNext,
  }) async {
    final loc = AppLocalizations.of(context);
    final subjId = lesson.subject.id.isNotEmpty
        ? lesson.subject.id
        : (lesson.originalSubject?.id ?? '');
    if (subjId.isEmpty) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(loc.translate('finding_lesson')),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    final result = isNext
        ? await ref
              .read(scheduleProvider.notifier)
              .findNextLesson(
                subjId,
                currentDate: lesson.date,
                currentLessonOrder: lesson.lessonOrder,
              )
        : await ref
              .read(scheduleProvider.notifier)
              .findPreviousLesson(
                subjId,
                currentDate: lesson.date,
                currentLessonOrder: lesson.lessonOrder,
              );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.translate(isNext ? 'no_next_lesson' : 'no_prev_lesson'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final targetDate = DateTime.tryParse(result.date);
    if (targetDate != null) {
      ref.read(selectedDateProvider.notifier).state = targetDate;
      await ref.read(scheduleProvider.notifier).loadWeekSchedule(targetDate);
    }

    final scheduleState = ref.read(scheduleProvider).valueOrNull;
    LessonSlot? targetSlot;
    if (scheduleState != null) {
      for (final day in scheduleState) {
        if (day.date == result.date) {
          for (final l in day.lessons) {
            if (l.lessonOrder == result.lessonOrder) {
              targetSlot = l;
              break;
            }
          }
        }
      }
    }

    targetSlot ??= LessonSlot(
      date: result.date,
      lessonOrder: result.lessonOrder,
      subject: SubjectModel(
        id: result.subjectId,
        name: result.subjectName,
        shortName: result.subjectName.isNotEmpty
            ? result.subjectName.substring(0, 1)
            : '',
        colorHex: '#3B82F6',
      ),
      startTime: result.startTime,
      endTime: result.endTime,
      cabinet: result.cabinet,
    );

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => LessonDetailSheet(lesson: targetSlot!),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = parseHexColor(lesson.subject.colorHex);
    final showClassrooms = ref.watch(showClassroomsProvider);
    final isPerformanceMode = ref.watch(performanceModeProvider);

    final isSubstitution =
        lesson.isOverride &&
        lesson.originalSubject != null &&
        !lesson.isCancelled &&
        lesson.originalSubject!.name.trim().toLowerCase() !=
            lesson.subject.name.trim().toLowerCase();

    final cardContent = Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isPerformanceMode
            ? (isDark ? const Color(0x381E293B) : const Color(0xB3FFFFFF))
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lesson.isCancelled
              ? LiquidTheme.danger.withValues(alpha: 0.35)
              : (lesson.isOverride
                    ? LiquidTheme.warning.withValues(alpha: 0.35)
                    : (isDark
                          ? LiquidTheme.darkBorder
                          : LiquidTheme.lightBorder)),
          width: (lesson.isCancelled || lesson.isOverride) ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject color indicator strip
          Container(
            width: 5,
            height: 64,
            decoration: BoxDecoration(
              color: subjectColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),

          // Main lesson information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and order header with fast actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x33475569)
                            : const Color(0x33CBD5E1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${lesson.lessonOrder}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${lesson.startTime} - ${lesson.endTime}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? LiquidTheme.darkTextSecondary
                            : LiquidTheme.lightTextSecondary,
                      ),
                    ),
                    const Spacer(),

                    // Fast Action Buttons: Previous, Change/Override, Next
                    Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            icon: Icon(
                              Icons.navigate_before_rounded,
                              size: 20,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            tooltip: loc.translate('previous_lesson'),
                            onPressed: () => _navigateToAdjacent(
                              context,
                              ref,
                              isNext: false,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                              size: 19,
                              color: LiquidTheme.accentLight,
                            ),
                            tooltip: loc.translate('change_lesson'),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    LessonOverrideSheet(lesson: lesson),
                              );
                            },
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            icon: Icon(
                              Icons.navigate_next_rounded,
                              size: 20,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            tooltip: loc.translate('next_lesson'),
                            onPressed: () =>
                                _navigateToAdjacent(context, ref, isNext: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Subject name and status badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        lesson.subject.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: lesson.isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (lesson.isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LiquidTheme.danger.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          loc.translate('cancelled'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: LiquidTheme.danger,
                          ),
                        ),
                      )
                    else if (lesson.isConsultation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LiquidTheme.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          loc.translate('consultation'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: LiquidTheme.accentLight,
                          ),
                        ),
                      ),
                  ],
                ),

                // Substitution subtitle indicator if changed
                if (isSubstitution) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 13,
                        color: LiquidTheme.warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${loc.translate('substitute_subject')}: ${lesson.originalSubject!.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LiquidTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 4),

                // Teacher, Cabinet, and Event badges
                Row(
                  children: [
                    if (showClassrooms &&
                        lesson.cabinet != null &&
                        lesson.cabinet!.isNotEmpty) ...[
                      Icon(
                        Icons.room_rounded,
                        size: 13,
                        color: isDark
                            ? LiquidTheme.darkTextMuted
                            : LiquidTheme.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${loc.translate('cab')} ${lesson.cabinet}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? LiquidTheme.darkTextSecondary
                              : LiquidTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Rich Event type chip
                    if (lesson.eventType != null) ...[
                      Builder(
                        builder: (context) {
                          final evColor = getEventColor(lesson.eventType);
                          final evIcon = getEventIcon(lesson.eventType);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: evColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: evColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  evIcon,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  loc.translate(lesson.eventType!),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: evColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),

                // Override note snippet if present
                if (lesson.overrideNote != null &&
                    lesson.overrideNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: isDark
                            ? LiquidTheme.darkTextMuted
                            : LiquidTheme.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lesson.overrideNote!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? LiquidTheme.darkTextMuted
                                : LiquidTheme.lightTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Homework preview indicator
                if (lesson.homework.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_rounded,
                        size: 14,
                        color: LiquidTheme.accentLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lesson.homework.first.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? LiquidTheme.darkTextSecondary
                                : LiquidTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                      if (lesson.homework.length > 1)
                        Text(
                          '+${lesson.homework.length - 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: LiquidTheme.accentLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final wrappedCard = isPerformanceMode
        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: cardContent)
        : LiquidGlassLens(
            style: LiquidTheme.cardStyle(isDark: isDark, radius: 20),
            child: cardContent,
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: GestureDetector(onTap: onTap, child: wrappedCard),
    );
  }
}
