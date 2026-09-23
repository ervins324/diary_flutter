import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../models/subject_model.dart';
import '../../providers/subjects_provider.dart';
import '../schedule/widgets/lesson_slot_card.dart';

/// Modal sheet for managing school subjects.
class SubjectsSheet extends ConsumerWidget {
  const SubjectsSheet({super.key});

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, [SubjectModel? existing]) {
    final loc = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final shortCtrl = TextEditingController(text: existing?.shortName ?? '');
    final cabCtrl = TextEditingController(text: existing?.defaultCabinet ?? '');
    String selectedColor = existing?.colorHex ?? '#6366F1';

    final colors = [
      '#6366F1', '#EC4899', '#8B5CF6', '#3B82F6',
      '#10B981', '#F59E0B', '#EF4444', '#14B8A6',
      '#F97316', '#64748B', '#84CC16', '#06B6D4',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                existing == null ? loc.translate('add_subject') : loc.translate('edit'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: loc.translate('subject_name'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: shortCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: loc.translate('short_name'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cabCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: loc.translate('default_cabinet'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Color picker row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((c) {
                        final isPicked = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: parseHexColor(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isPicked ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(loc.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final shortName = shortCtrl.text.trim().isNotEmpty
                        ? shortCtrl.text.trim()
                        : (name.length > 4 ? name.substring(0, 4) : name);

                    if (existing == null) {
                      ref.read(subjectsProvider.notifier).addSubject(
                            SubjectModel(
                              id: const Uuid().v4(),
                              name: name,
                              shortName: shortName,
                              colorHex: selectedColor,
                              defaultCabinet: cabCtrl.text.trim().isNotEmpty ? cabCtrl.text.trim() : null,
                            ),
                          );
                    } else {
                      ref.read(subjectsProvider.notifier).updateSubject(
                            existing.copyWith(
                              name: name,
                              shortName: shortName,
                              colorHex: selectedColor,
                              defaultCabinet: cabCtrl.text.trim().isNotEmpty ? cabCtrl.text.trim() : null,
                            ),
                          );
                    }
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: LiquidTheme.accent),
                  child: Text(loc.translate('save'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xEE0B1120) : const Color(0xEEF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('subjects'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () => _showAddSubjectDialog(context, ref),
                icon: const Icon(Icons.add_circle_outline_rounded, color: LiquidTheme.accentLight, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final s = subjects[index];
                final color = parseHexColor(s.colorHex);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x1F334155) : const Color(0x22CBD5E1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (s.defaultCabinet != null)
                              Text(
                                '${loc.translate('cab')} ${s.defaultCabinet}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddSubjectDialog(context, ref, s),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: Colors.white70,
                      ),
                      IconButton(
                        onPressed: () => ref.read(subjectsProvider.notifier).deleteSubject(s.id),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: LiquidTheme.danger,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
