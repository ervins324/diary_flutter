import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/lesson_note_model.dart';
import '../../../providers/notes_provider.dart';
import '../../common/widgets/attachment_chips_view.dart';
import '../../schedule/widgets/lesson_slot_card.dart';

/// Liquid glass card for displaying a lesson note.
class NoteCard extends ConsumerWidget {
  final LessonNoteModel note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = note.subject != null
        ? parseHexColor(note.subject!.colorHex)
        : LiquidTheme.accent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: LiquidGlassLens(
        style: LiquidTheme.cardStyle(isDark: isDark, radius: 20),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Subject, Date, Lesson order, Pending sync
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.subject?.name ?? 'Lesson Note',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x33475569) : const Color(0x33CBD5E1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${note.lessonOrder}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),

                  Text(
                    note.date,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                    ),
                  ),

                  if (note.isPendingSync) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.cloud_upload_outlined, size: 16, color: LiquidTheme.warning),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Note text
              Text(
                note.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),

              // Attachment previews & images with zoom
              AttachmentChipsView(
                images: note.images,
                attachments: note.attachments,
                isDark: isDark,
              ),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(notesListProvider.notifier).deleteNote(note.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: LiquidTheme.danger.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
