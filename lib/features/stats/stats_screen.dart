import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../providers/stats_provider.dart';
import '../schedule/widgets/lesson_slot_card.dart';

/// Weekly statistics dashboard.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);
    final statsDate = ref.watch(statsDateProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Date navigator
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(statsDateProvider.notifier).state =
                        statsDate.subtract(const Duration(days: 7));
                  },
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                ),
                Text(
                  '${loc.translate('week')}: ${DateFormat('dd MMM').format(statsDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(statsDateProvider.notifier).state =
                        statsDate.add(const Duration(days: 7));
                  },
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                ),
              ],
            ),
          ),
        ),

        // Statistics Cards
        statsAsync.when(
          data: (data) {
            final totalLessons = (data['total_lessons'] as num?)?.toInt() ?? 0;
            final completedHw = (data['completed_homeworks'] as num?)?.toInt() ?? 0;
            final totalHw = (data['total_homeworks'] as num?)?.toInt() ?? 0;
            final timeSpent = (data['total_time_spent_seconds'] as num?)?.toInt() ?? 0;
            final hwRate = totalHw > 0 ? (completedHw / totalHw * 100).round() : 100;
            final studyMinutes = timeSpent ~/ 60;

            final rawBreakdown = data['subjects_breakdown'];
            final breakdown = (rawBreakdown is List) ? rawBreakdown : [];

            return SliverList(
              delegate: SliverChildListDelegate([
                // Overview metrics row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Homework rate metric
                      Expanded(
                        child: _buildMetricCard(
                          isDark: isDark,
                          title: loc.translate('homework_rate'),
                          value: '$hwRate%',
                          subtitle: '$completedHw / $totalHw',
                          icon: Icons.checklist_rounded,
                          color: LiquidTheme.success,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Study time metric
                      Expanded(
                        child: _buildMetricCard(
                          isDark: isDark,
                          title: loc.translate('study_time'),
                          value: '$studyMinutes ${loc.translate('minutes')}',
                          subtitle: '$totalLessons ${loc.translate('lesson')}',
                          icon: Icons.timer_rounded,
                          color: LiquidTheme.accentLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Subjects breakdown card
                if (breakdown.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LiquidGlassLens(
                      style: LiquidTheme.cardStyle(isDark: isDark, radius: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('subjects'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...breakdown.map((item) {
                              final name = item['name'] ?? item['subject_name'] ?? '';
                              final count = (item['count'] as num?)?.toInt() ?? 1;
                              final hexColor = item['color_hex'] ?? '#6366F1';
                              final color = parseHexColor(hexColor);
                              final maxCount = totalLessons > 0 ? totalLessons : 1;
                              final ratio = (count / maxCount).clamp(0.0, 1.0);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '$count ${loc.translate('lesson')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 6,
                                        backgroundColor: isDark
                                            ? const Color(0x26334155)
                                            : const Color(0x26E2E8F0),
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 80),
              ]),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: LiquidTheme.accent),
            ),
          ),
          error: (err, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Error loading stats: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required bool isDark,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return LiquidGlassLens(
      style: LiquidTheme.cardStyle(isDark: isDark, radius: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
