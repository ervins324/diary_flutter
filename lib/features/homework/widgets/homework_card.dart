import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/homework_model.dart';
import '../../../providers/homework_provider.dart';
import '../../schedule/widgets/lesson_slot_card.dart';

/// Card displaying homework item with timer, completion checkbox, and attachment previews.
class HomeworkCard extends ConsumerStatefulWidget {
  final HomeworkItem item;

  const HomeworkCard({super.key, required this.item});

  @override
  ConsumerState<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends ConsumerState<HomeworkCard> {
  Timer? _studyTimer;
  bool _isTimerActive = false;
  int _sessionSeconds = 0;

  @override
  void dispose() {
    _studyTimer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isTimerActive) {
      _studyTimer?.cancel();
      _isTimerActive = false;
      if (_sessionSeconds > 0) {
        ref.read(homeworkListProvider.notifier).updateTimeSpent(widget.item, _sessionSeconds);
        _sessionSeconds = 0;
      }
      setState(() {});
    } else {
      _isTimerActive = true;
      _studyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _sessionSeconds++;
        });
      });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = widget.item.subject != null
        ? parseHexColor(widget.item.subject!.colorHex)
        : LiquidTheme.accent;

    final totalSeconds = widget.item.timeSpentSeconds + _sessionSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: LiquidGlassLens(
        style: LiquidTheme.cardStyle(isDark: isDark, radius: 20),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.item.isCompleted
                  ? LiquidTheme.success.withValues(alpha: 0.3)
                  : (isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Subject name, Due date, and Sync status
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
                    widget.item.subject?.name ?? 'Homework',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),

                  // Due date chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x33475569) : const Color(0x33CBD5E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.item.dueDate,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),

                  if (widget.item.isPendingSync) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.cloud_upload_outlined, size: 16, color: LiquidTheme.warning),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Homework text & checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: widget.item.isCompleted,
                      activeColor: LiquidTheme.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: (_) {
                        ref.read(homeworkListProvider.notifier).toggleComplete(widget.item);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        widget.item.text,
                        style: TextStyle(
                          fontSize: 15,
                          decoration: widget.item.isCompleted ? TextDecoration.lineThrough : null,
                          color: widget.item.isCompleted
                              ? (isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Attachment previews
              if (widget.item.attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.item.attachments.map((att) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x2694A3B8) : const Color(0x2664748B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            att.type == 'image' ? Icons.image_rounded : Icons.description_rounded,
                            size: 14,
                            color: LiquidTheme.accentLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            att.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Footer: Timer controls & Delete action
              Row(
                children: [
                  // Study timer button
                  GestureDetector(
                    onTap: _toggleTimer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isTimerActive
                            ? LiquidTheme.warning.withValues(alpha: 0.2)
                            : (isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isTimerActive ? LiquidTheme.warning : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isTimerActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                            size: 16,
                            color: _isTimerActive ? LiquidTheme.warning : LiquidTheme.accentLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$minutes ${loc.translate('minutes')} ${seconds > 0 ? '$seconds ${loc.translate('seconds')}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isTimerActive
                                  ? LiquidTheme.warning
                                  : (isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Delete homework button
                  IconButton(
                    onPressed: () {
                      ref.read(homeworkListProvider.notifier).deleteHomework(widget.item.id);
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
