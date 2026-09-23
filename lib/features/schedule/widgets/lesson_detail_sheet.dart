import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/schedule_model.dart';
import '../../homework/widgets/homework_form_dialog.dart';
import '../../notes/widgets/note_form_dialog.dart';
import '../../../providers/homework_provider.dart';
import '../../../providers/notes_provider.dart';
import 'lesson_slot_card.dart';

/// Modal bottom sheet displaying detailed homework and notes for a clicked lesson.
class LessonDetailSheet extends ConsumerWidget {
  final LessonSlot lesson;

  const LessonDetailSheet({super.key, required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = parseHexColor(lesson.subject.colorHex);

    // Watch live homework and notes to stay responsive to edits
    final allHomework = ref.watch(homeworkListProvider);
    final allNotes = ref.watch(notesListProvider);

    final lessonHw = allHomework.where((h) =>
        h.dueDate == lesson.date &&
        (h.subjectId == lesson.subject.id || h.lessonOrder == lesson.lessonOrder)).toList();

    final lessonNotes = allNotes.where((n) =>
        n.date == lesson.date &&
        n.subjectId == lesson.subject.id &&
        n.lessonOrder == lesson.lessonOrder).toList();

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
                color: isDark ? const Color(0x4094A3B8) : const Color(0x4064748B),
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
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x2694A3B8) : const Color(0x2664748B),
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
          if (lesson.cabinet != null) ...[
            const SizedBox(height: 4),
            Text(
              '${loc.translate('cab')} ${lesson.cabinet}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),

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
                  color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...lessonHw.map((hw) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                  border: Border.all(
                    color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: hw.isCompleted,
                      activeColor: LiquidTheme.success,
                      onChanged: (_) {
                        ref.read(homeworkListProvider.notifier).toggleComplete(hw);
                      },
                    ),
                    Expanded(
                      child: Text(
                        hw.text,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: hw.isCompleted ? TextDecoration.lineThrough : null,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (hw.isPendingSync)
                      const Icon(Icons.cloud_upload_outlined, size: 16, color: LiquidTheme.warning),
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
                  color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...lessonNotes.map((n) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                  border: Border.all(
                    color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                  ),
                ),
                child: Text(
                  n.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
