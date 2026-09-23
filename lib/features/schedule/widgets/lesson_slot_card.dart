import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/schedule_model.dart';

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

/// Liquid glass card representing a single lesson slot in the daily schedule.
class LessonSlotCard extends StatelessWidget {
  final LessonSlot lesson;
  final VoidCallback onTap;

  const LessonSlotCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = parseHexColor(lesson.subject.colorHex);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: LiquidGlassLens(
          style: LiquidTheme.cardStyle(isDark: isDark, radius: 20),
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: lesson.isCancelled
                    ? LiquidTheme.danger.withValues(alpha: 0.3)
                    : (isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder),
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
                      // Time and order header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x33475569) : const Color(0x33CBD5E1),
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

                          // Status badges
                          if (lesson.isCancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: LiquidTheme.danger.withValues(alpha: 0.2),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: LiquidTheme.accent.withValues(alpha: 0.2),
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
                      const SizedBox(height: 6),

                      // Subject name
                      Text(
                        lesson.subject.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: lesson.isCancelled ? TextDecoration.lineThrough : null,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Teacher & Cabinet
                      Row(
                        children: [
                          if (lesson.cabinet != null && lesson.cabinet!.isNotEmpty) ...[
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

                          // Event type chip
                          if (lesson.eventType != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x33F59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                loc.translate(lesson.eventType!),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: LiquidTheme.warning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Homework preview indicator
                      if (lesson.homework.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
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
          ),
        ),
      ),
    );
  }
}
