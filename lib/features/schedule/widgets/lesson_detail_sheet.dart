import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/schedule_model.dart';
import '../../../models/subject_model.dart';
import '../../../providers/homework_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../common/widgets/attachment_chips_view.dart';
import '../../homework/widgets/homework_form_dialog.dart';
import '../../notes/widgets/note_form_dialog.dart';
import 'lesson_override_sheet.dart';
import 'lesson_slot_card.dart';

/// Modal bottom sheet displaying detailed homework, notes, and fast navigation for a clicked lesson.
class LessonDetailSheet extends ConsumerWidget {
  final LessonSlot lesson;

  const LessonDetailSheet({super.key, required this.lesson});

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

    // Dismiss current sheet
    Navigator.of(context).pop();

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

    final isSubstitution =
        lesson.isOverride &&
        lesson.originalSubject != null &&
        !lesson.isCancelled &&
        lesson.originalSubject!.name.trim().toLowerCase() !=
            lesson.subject.name.trim().toLowerCase();

    // Watch live homework and notes to stay responsive to edits
    final allHomework = ref.watch(homeworkListProvider);
    final allNotes = ref.watch(notesListProvider);

    final lessonHw = allHomework
        .where(
          (h) =>
              h.dueDate == lesson.date &&
              (h.subjectId == lesson.subject.id ||
                  h.lessonOrder == lesson.lessonOrder),
        )
        .toList();

    final lessonNotes = allNotes
        .where(
          (n) =>
              n.date == lesson.date &&
              n.subjectId == lesson.subject.id &&
              n.lessonOrder == lesson.lessonOrder,
        )
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xEE0B1120) : const Color(0xEEF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x4094A3B8)
                    : const Color(0x4064748B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: subjectColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lesson.subject.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: lesson.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x2694A3B8)
                      : const Color(0x2664748B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${lesson.startTime} - ${lesson.endTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (ref.watch(showClassroomsProvider) &&
              lesson.cabinet != null &&
              lesson.cabinet!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${loc.translate('cab')} ${lesson.cabinet}',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? LiquidTheme.darkTextSecondary
                    : LiquidTheme.lightTextSecondary,
              ),
            ),
          ],

          // Status, event, and substitution badges
          if (lesson.isCancelled ||
              lesson.eventType != null ||
              lesson.isConsultation ||
              isSubstitution) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (lesson.isCancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: LiquidTheme.danger.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: LiquidTheme.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      loc.translate('cancelled'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LiquidTheme.danger,
                      ),
                    ),
                  ),
                if (lesson.isConsultation)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: LiquidTheme.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: LiquidTheme.accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      loc.translate('consultation'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LiquidTheme.accentLight,
                      ),
                    ),
                  ),
                if (lesson.eventType != null) ...[
                  Builder(
                    builder: (context) {
                      final evColor = getEventColor(lesson.eventType);
                      final evIcon = getEventIcon(lesson.eventType);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: evColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: evColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(evIcon, style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              loc.translate(lesson.eventType!),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: evColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                if (isSubstitution)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: LiquidTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: LiquidTheme.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '${loc.translate('substitute_subject')}: ${lesson.originalSubject!.name}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LiquidTheme.warning,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Override note snippet if present
          if (lesson.overrideNote != null &&
              lesson.overrideNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x1F334155)
                    : const Color(0x1FE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: LiquidTheme.accentLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lesson.overrideNote!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Fast Navigation & Override Action Row ──────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x1F334155) : const Color(0x1FE2E8F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? LiquidTheme.darkBorder
                    : LiquidTheme.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _navigateToAdjacent(context, ref, isNext: false),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.navigate_before_rounded, size: 18),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              loc.translate('previous_lesson'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: isDark
                      ? const Color(0x33475569)
                      : const Color(0x33CBD5E1),
                ),
                IconButton(
                  tooltip: loc.translate('change_lesson'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => LessonOverrideSheet(lesson: lesson),
                    );
                  },
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 20,
                    color: LiquidTheme.accentLight,
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: isDark
                      ? const Color(0x33475569)
                      : const Color(0x33CBD5E1),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _navigateToAdjacent(context, ref, isNext: true),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              loc.translate('next_lesson'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.navigate_next_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Homework Section ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('homework'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => HomeworkFormDialog(
                      preselectedDate: lesson.date,
                      preselectedSubject: lesson.subject,
                      lessonOrder: lesson.lessonOrder,
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(loc.translate('add_homework')),
                style: TextButton.styleFrom(
                  foregroundColor: LiquidTheme.accentLight,
                ),
              ),
            ],
          ),

          if (lessonHw.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                loc.translate('no_homework'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? LiquidTheme.darkTextMuted
                      : LiquidTheme.lightTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...lessonHw.map((hw) {
              return Container(
                key: ValueKey('hw_${hw.id}'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? const Color(0x1F334155)
                      : const Color(0x22E2E8F0),
                  border: Border.all(
                    color: isDark
                        ? LiquidTheme.darkBorder
                        : LiquidTheme.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: hw.isCompleted,
                          activeColor: LiquidTheme.success,
                          onChanged: (_) {
                            ref
                                .read(homeworkListProvider.notifier)
                                .toggleComplete(hw);
                          },
                        ),
                        Expanded(
                          child: Text(
                            hw.text,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: hw.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (hw.isPendingSync)
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 16,
                            color: LiquidTheme.warning,
                          ),
                      ],
                    ),
                    if (hw.images.isNotEmpty || hw.attachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                        child: AttachmentChipsView(
                          images: hw.images,
                          attachments: hw.attachments,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),

          // ── Notes Section ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('lesson_notes'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => NoteFormDialog(
                      preselectedDate: lesson.date,
                      preselectedSubject: lesson.subject,
                      lessonOrder: lesson.lessonOrder,
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(loc.translate('add_note')),
                style: TextButton.styleFrom(
                  foregroundColor: LiquidTheme.accentLight,
                ),
              ),
            ],
          ),

          if (lessonNotes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                loc.translate('no_notes'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? LiquidTheme.darkTextMuted
                      : LiquidTheme.lightTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...lessonNotes.map((n) {
              return Container(
                key: ValueKey('note_${n.id}'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? const Color(0x1F334155)
                      : const Color(0x22E2E8F0),
                  border: Border.all(
                    color: isDark
                        ? LiquidTheme.darkBorder
                        : LiquidTheme.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    if (n.images.isNotEmpty || n.attachments.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      AttachmentChipsView(
                        images: n.images,
                        attachments: n.attachments,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
