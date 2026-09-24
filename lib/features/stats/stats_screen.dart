import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/stats_provider.dart';
import '../schedule/widgets/lesson_slot_card.dart';

/// Full feature parity weekly statistics dashboard matching StatsPage.tsx.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);
    final statsDate = ref.watch(statsDateProvider);
    final scheduleMode = ref.watch(statsScheduleModeProvider);
    final metricMode = ref.watch(statsMetricModeProvider);
    final viewMode = ref.watch(statsViewModeProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final monday = getMonday(statsDate);
    final sunday = monday.add(const Duration(days: 6));
    final dateRangeStr =
        '${DateFormat('d MMM', loc.locale.languageCode).format(monday)} – ${DateFormat('d MMM yyyy', loc.locale.languageCode).format(sunday)}';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weeklyStatsProvider);
      },
      color: LiquidTheme.accent,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── 1. Week Navigator ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(statsDateProvider.notifier).state =
                          statsDate.subtract(const Duration(days: 7));
                    },
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  Column(
                    children: [
                      Text(
                        loc.translate('weekly_overview'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateRangeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(statsDateProvider.notifier).state =
                          statsDate.add(const Duration(days: 7));
                    },
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ],
              ),
            ),
          ),

          // ── 2. Top Controls: Schedule Mode (Actual / Num / Denom) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: LiquidGlassLens(
                style: LiquidTheme.pillStyle(isDark: isDark, radius: 14),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPillButton(
                        label: loc.translate('stats_mode_actual'),
                        isSelected: scheduleMode == 'actual',
                        onTap: () =>
                            ref.read(statsScheduleModeProvider.notifier).state = 'actual',
                      ),
                      _buildPillButton(
                        label: loc.translate('stats_mode_numerator'),
                        isSelected: scheduleMode == 'numerator',
                        onTap: () =>
                            ref.read(statsScheduleModeProvider.notifier).state = 'numerator',
                      ),
                      _buildPillButton(
                        label: loc.translate('stats_mode_denominator'),
                        isSelected: scheduleMode == 'denominator',
                        onTap: () =>
                            ref.read(statsScheduleModeProvider.notifier).state = 'denominator',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Controls Row 2: Metric (Time / Lessons) & View (Subjects / Days)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  // Metric Switcher: Time vs Lessons
                  Expanded(
                    child: LiquidGlassLens(
                      style: LiquidTheme.pillStyle(isDark: isDark, radius: 12),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildPillButton(
                              icon: Icons.access_time_rounded,
                              label: loc.translate('stats_metric_time'),
                              isSelected: metricMode == 'time',
                              onTap: () =>
                                  ref.read(statsMetricModeProvider.notifier).state = 'time',
                            ),
                            _buildPillButton(
                              icon: Icons.tag_rounded,
                              label: loc.translate('stats_metric_lessons'),
                              isSelected: metricMode == 'lessons',
                              onTap: () =>
                                  ref.read(statsMetricModeProvider.notifier).state = 'lessons',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // View Switcher: Subjects vs Days
                  Expanded(
                    child: LiquidGlassLens(
                      style: LiquidTheme.pillStyle(isDark: isDark, radius: 12),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildPillButton(
                              icon: Icons.bar_chart_rounded,
                              label: loc.translate('by_subjects'),
                              isSelected: viewMode == 'subjects',
                              onTap: () =>
                                  ref.read(statsViewModeProvider.notifier).state = 'subjects',
                            ),
                            _buildPillButton(
                              icon: Icons.calendar_view_day_rounded,
                              label: loc.translate('by_days'),
                              isSelected: viewMode == 'days',
                              onTap: () =>
                                  ref.read(statsViewModeProvider.notifier).state = 'days',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. Main Stats Content ──────────────────────────────────
          statsAsync.when(
            data: (data) => _buildStatsContent(
              context: context,
              ref: ref,
              data: data,
              loc: loc,
              isDark: isDark,
              metricMode: metricMode,
              viewMode: viewMode,
            ),
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: LiquidTheme.accent),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Error loading stats: $err'),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    IconData? icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? LiquidTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> data,
    required AppLocalizations loc,
    required bool isDark,
    required String metricMode,
    required String viewMode,
  }) {
    final rawSubjects = data['subjects'];
    final subjects = (rawSubjects is List)
        ? rawSubjects.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final rawDays = data['days'];
    final days = (rawDays is List)
        ? rawDays.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final totalLessons = (data['total_lessons'] as num?)?.toInt() ?? 0;
    final totalSubjects = (data['total_subjects'] as num?)?.toInt() ?? subjects.length;
    final avgLessons = (data['avg_lessons_per_day'] as num?)?.toDouble() ?? 0.0;
    final totalBreakMins = (data['total_break_minutes'] as num?)?.toInt() ?? 0;
    final cancelledCount = (data['cancelled_lessons_count'] as num?)?.toInt() ?? 0;
    final cancelledMins = (data['total_cancelled_minutes'] as num?)?.toInt() ?? 0;

    final hwStats = (data['homework_stats'] is Map)
        ? Map<String, dynamic>.from(data['homework_stats'] as Map)
        : <String, dynamic>{};
    final hwTotal = (hwStats['total'] as num?)?.toInt() ?? 0;
    final hwCompleted = (hwStats['completed'] as num?)?.toInt() ?? 0;
    final hwFailed = (hwStats['failed'] as num?)?.toInt() ?? 0;
    final hwRate = (hwStats['completion_rate'] as num?)?.toDouble() ?? 100.0;
    final hwFailureRate = (hwStats['failure_rate'] as num?)?.toDouble() ?? 0.0;
    final hwTotalSeconds = (hwStats['total_time_spent_seconds'] as num?)?.toInt() ?? 0;
    final hwAvgSeconds = (hwStats['avg_time_spent_seconds'] as num?)?.toInt() ?? 0;
    final failedItems = (hwStats['failed_items'] is List)
        ? (hwStats['failed_items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final eventCounts = (data['event_counts'] is Map)
        ? Map<String, dynamic>.from(data['event_counts'] as Map)
        : <String, dynamic>{};

    final rawReasons = data['cancellation_reasons'];
    final reasons = (rawReasons is List)
        ? rawReasons.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    // Calculate total study minutes & busiest subject
    int totalStudyMinutes = 0;
    Map<String, dynamic>? busiestSubject;
    for (final s in subjects) {
      final mins = (s['total_minutes'] as num?)?.toInt() ?? 0;
      totalStudyMinutes += mins;
      if (busiestSubject == null ||
          mins > ((busiestSubject['total_minutes'] as num?)?.toInt() ?? 0)) {
        busiestSubject = s;
      }
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Notice: Cancelled Lessons Callout ────────────────────────
        if (cancelledCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x22F43F5E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x55F43F5E)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, size: 18, color: Color(0xFFF43F5E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loc.translate('stats_cancelled_lessons')}: $cancelledCount (${cancelledMins ~/ 60} ${loc.translate('hours_short')} ${cancelledMins % 60} ${loc.translate('minutes_short')})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF43F5E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Notice: Academic Events Summary Badges ───────────────────
        if (eventCounts.values.any((v) => (v as num? ?? 0) > 0))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: LiquidGlassLens(
              style: LiquidTheme.cardStyle(isDark: isDark, radius: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${loc.translate('stats_events_summary')}:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    if ((eventCounts['control_work'] as num? ?? 0) > 0)
                      _buildEventBadge(
                        '🔥 ${eventCounts['control_work']} ${loc.translate('event_control_work')}',
                        const Color(0xFFF43F5E),
                      ),
                    if ((eventCounts['test'] as num? ?? 0) > 0)
                      _buildEventBadge(
                        '📝 ${eventCounts['test']} ${loc.translate('event_test')}',
                        Colors.amberAccent,
                      ),
                    if ((eventCounts['essay'] as num? ?? 0) > 0)
                      _buildEventBadge(
                        '✍️ ${eventCounts['essay']} ${loc.translate('event_essay')}',
                        Colors.purpleAccent,
                      ),
                    if ((eventCounts['project'] as num? ?? 0) > 0)
                      _buildEventBadge(
                        '🚀 ${eventCounts['project']} ${loc.translate('event_project')}',
                        Colors.lightBlueAccent,
                      ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 6),

        // ── View Mode: By Subjects vs By Days ────────────────────────
        if (viewMode == 'subjects')
          _buildSubjectsView(
            context: context,
            subjects: subjects,
            metricMode: metricMode,
            loc: loc,
            isDark: isDark,
          )
        else
          _buildDaysView(
            context: context,
            days: days,
            metricMode: metricMode,
            loc: loc,
            isDark: isDark,
          ),

        const SizedBox(height: 14),

        // ── Enriched Summary Metrics Grid (KPI Cards) ────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Row 1: Study time & Busiest subject
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      isDark: isDark,
                      icon: Icons.timer_rounded,
                      iconColor: LiquidTheme.accentLight,
                      title: loc.translate('total_hours'),
                      value:
                          '${totalStudyMinutes ~/ 60}${loc.translate('hours_short')} ${totalStudyMinutes % 60}${loc.translate('minutes_short')}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiCard(
                      isDark: isDark,
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.amberAccent,
                      title: loc.translate('busiest_subject'),
                      value: busiestSubject != null
                          ? (busiestSubject['subject_name'] ?? '-')
                          : '-',
                      valueColor: busiestSubject != null
                          ? parseHexColor(busiestSubject['color_hex'] ?? '#6366F1')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Total subjects & Total lessons
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      isDark: isDark,
                      icon: Icons.menu_book_rounded,
                      iconColor: Colors.indigoAccent,
                      title: loc.translate('stats_subjects_count'),
                      value: '$totalSubjects',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiCard(
                      isDark: isDark,
                      icon: Icons.calendar_month_rounded,
                      iconColor: Colors.blueAccent,
                      title: loc.translate('stats_lessons_count'),
                      value: '$totalLessons',
                      subtitle: '~${avgLessons.toStringAsFixed(1)} ${loc.translate('stats_per_day')}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 3: Homework completion with multi-segment progress bar
              LiquidGlassLens(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 18, color: LiquidTheme.success),
                              const SizedBox(width: 6),
                              Text(
                                loc.translate('stats_homework_rate'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${hwRate.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (hwFailed > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '• $hwFailed ${loc.translate('stats_failed')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: LiquidTheme.danger,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Multi-segment progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              if (hwCompleted > 0)
                                Flexible(
                                  flex: hwCompleted,
                                  child: Container(color: LiquidTheme.success),
                                ),
                              if (hwFailed > 0)
                                Flexible(
                                  flex: hwFailed,
                                  child: Container(color: LiquidTheme.danger),
                                ),
                              if (hwTotal > (hwCompleted + hwFailed))
                                Flexible(
                                  flex: hwTotal - (hwCompleted + hwFailed),
                                  child: Container(
                                    color: isDark ? const Color(0x33475569) : const Color(0x33CBD5E1),
                                  ),
                                ),
                              if (hwTotal == 0)
                                Expanded(
                                  child: Container(
                                    color: isDark ? const Color(0x33475569) : const Color(0x33CBD5E1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$hwCompleted ${loc.translate('stats_completed')}',
                            style: const TextStyle(fontSize: 11, color: LiquidTheme.success, fontWeight: FontWeight.w600),
                          ),
                          if (hwFailed > 0)
                            Text(
                              '$hwFailed ${loc.translate('stats_failed')}',
                              style: const TextStyle(fontSize: 11, color: LiquidTheme.danger, fontWeight: FontWeight.w600),
                            ),
                          Text(
                            '${(hwTotal - hwCompleted - hwFailed).clamp(0, hwTotal)} ${loc.translate('stats_pending')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Row 4: Homework study time
              _buildKpiCard(
                isDark: isDark,
                icon: Icons.hourglass_top_rounded,
                iconColor: LiquidTheme.accentLight,
                title: loc.translate('stats_homework_time'),
                value:
                    '${hwTotalSeconds ~/ 3600 > 0 ? '${hwTotalSeconds ~/ 3600}${loc.translate('hours_short')} ' : ''}${(hwTotalSeconds % 3600) ~/ 60}${loc.translate('minutes_short')}',
                subtitle: hwAvgSeconds > 0
                    ? '~${(hwAvgSeconds / 60).round()}${loc.translate('minutes_short')} ${loc.translate('stats_avg_homework_time')}'
                    : null,
              ),
            ],
          ),
        ),

        // ── 5. Standalone Box: Failed Homework Items (if any) ────────
        if (failedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark ? const Color(0x1AF43F5E) : const Color(0x11F43F5E),
                border: Border.all(color: const Color(0x44F43F5E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cancel_rounded, size: 20, color: LiquidTheme.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.translate('stats_failed_title'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: LiquidTheme.danger,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: LiquidTheme.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$hwFailed (${hwFailureRate.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: LiquidTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.translate('stats_failed_desc'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...failedItems.map((item) {
                    final color = parseHexColor(item['subject_color'] ?? '#6366F1');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? const Color(0x221E293B) : Colors.white,
                        border: Border.all(
                          color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['subject_name'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['text'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: LiquidTheme.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              loc.translate('hw_failed_badge'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: LiquidTheme.danger,
                              ),
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
        ],

        // ── 6. Standalone Box: Breaks & Interruption Analytics ───────
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LiquidGlassLens(
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
                  Row(
                    children: [
                      const Icon(Icons.coffee_rounded, size: 20, color: LiquidTheme.success),
                      const SizedBox(width: 8),
                      Text(
                        loc.translate('breaks_and_cancellations'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Total breaks
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('stats_breaks_duration'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${totalBreakMins ~/ 60}${loc.translate('hours_short')} ${totalBreakMins % 60}${loc.translate('minutes_short')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: LiquidTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Cancelled lessons
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('stats_cancelled_lessons'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$cancelledCount ${loc.translate('day_lessons')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: cancelledCount > 0 ? LiquidTheme.danger : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Cancellation reasons breakdown
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      loc.translate('stats_cancellation_reasons'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...reasons.map((r) {
                      final reason = r['reason'] ?? loc.translate('stats_reason_not_specified');
                      final count = (r['count'] as num?)?.toInt() ?? 1;
                      final mins = (r['total_minutes'] as num?)?.toInt() ?? 0;
                      final percent = cancelledCount > 0 ? (count / cancelledCount).clamp(0.0, 1.0) : 1.0;
                      final isAlert = reason.toString().toLowerCase().contains('тривог') ||
                          reason.toString().toLowerCase().contains('alert');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isAlert ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                      size: 13,
                                      color: isAlert ? LiquidTheme.danger : Colors.amberAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      reason,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$count ($mins${loc.translate('minutes_short')})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 4,
                                backgroundColor: isDark ? const Color(0x33334155) : const Color(0x33E2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isAlert ? LiquidTheme.danger : Colors.amberAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSubjectsView({
    required BuildContext context,
    required List<Map<String, dynamic>> subjects,
    required String metricMode,
    required AppLocalizations loc,
    required bool isDark,
  }) {
    if (subjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            loc.translate('no_data_week'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final maxVal = subjects.fold<num>(1, (prev, s) {
      final val = metricMode == 'time'
          ? (s['total_minutes'] as num? ?? 0)
          : (s['lessons_count'] as num? ?? 0);
      return val > prev ? val : prev;
    }).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: LiquidGlassLens(
        style: LiquidTheme.cardStyle(isDark: isDark, radius: 22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              ...subjects.map((s) {
                final name = s['subject_name'] ?? '';
                final shortName = s['short_name'] ?? '';
                final hex = s['color_hex'] ?? '#6366F1';
                final color = parseHexColor(hex);
                final mins = (s['total_minutes'] as num?)?.toInt() ?? 0;
                final lessonsCount = (s['lessons_count'] as num?)?.toInt() ?? 0;
                final val = metricMode == 'time' ? mins.toDouble() : lessonsCount.toDouble();
                final ratio = maxVal > 0 ? (val / maxVal).clamp(0.0, 1.0) : 0.0;

                final displayValue = metricMode == 'time'
                    ? '${mins ~/ 60}${loc.translate('hours_short')} ${mins % 60}${loc.translate('minutes_short')}'
                    : '$lessonsCount ${loc.translate('lesson')}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (shortName.isNotEmpty && shortName != name) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '($shortName)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            displayValue,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 7,
                          backgroundColor: isDark ? const Color(0x33334155) : const Color(0x33E2E8F0),
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
    );
  }

  Widget _buildDaysView({
    required BuildContext context,
    required List<Map<String, dynamic>> days,
    required String metricMode,
    required AppLocalizations loc,
    required bool isDark,
  }) {
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            loc.translate('no_data_week'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final activeDays = days.where((d) => (d['day_of_week'] as num? ?? 1) <= 5 || (d['lessons_count'] as num? ?? 0) > 0).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('daily_breakdown'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ...activeDays.map((day) {
            final dayKey = day['day_key'] ?? 'mon';
            final dayName = loc.translate(dayKey);
            final dateStr = day['date'] ?? '';
            final formattedDate = dateStr.isNotEmpty
                ? DateFormat('dd.MM').format(DateTime.tryParse(dateStr) ?? DateTime.now())
                : '';
            final count = (day['lessons_count'] as num?)?.toInt() ?? 0;
            final mins = (day['total_minutes'] as num?)?.toInt() ?? 0;
            final breakMins = (day['break_minutes'] as num?)?.toInt() ?? 0;
            final hwCount = (day['homework_count'] as num?)?.toInt() ?? 0;
            final hwCompleted = (day['homework_completed'] as num?)?.toInt() ?? 0;
            final hwFailed = (day['homework_failed'] as num?)?.toInt() ?? 0;
            final rawSubjs = day['subjects'];
            final daySubjects = (rawSubjs is List)
                ? rawSubjs.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                : <Map<String, dynamic>>[];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: LiquidGlassLens(
                style: LiquidTheme.cardStyle(isDark: isDark, radius: 18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? LiquidTheme.accent.withValues(alpha: 0.15)
                                  : (isDark ? const Color(0x33475569) : const Color(0x33CBD5E1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count ${loc.translate('day_lessons')}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: count > 0
                                    ? LiquidTheme.accentLight
                                    : (isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 13, color: LiquidTheme.accentLight),
                                const SizedBox(width: 4),
                                Text(
                                  '${mins ~/ 60}${loc.translate('hours_short')} ${mins % 60}${loc.translate('minutes_short')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            if (breakMins > 0) ...[
                              const SizedBox(width: 14),
                              Row(
                                children: [
                                  const Icon(Icons.coffee_rounded, size: 13, color: LiquidTheme.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$breakMins ${loc.translate('minutes_short')}',
                                    style: const TextStyle(fontSize: 11, color: LiquidTheme.success),
                                  ),
                                ],
                              ),
                            ],
                            if (hwCount > 0) ...[
                              const SizedBox(width: 14),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: hwCompleted == hwCount ? LiquidTheme.success : Colors.amberAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$hwCompleted/$hwCount',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  if (hwFailed > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '($hwFailed не здано)',
                                      style: const TextStyle(fontSize: 10, color: LiquidTheme.danger),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),

                        // Subject chips for that day
                        if (daySubjects.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: daySubjects.map((s) {
                              final hex = s['color_hex'] ?? '#6366F1';
                              final color = parseHexColor(hex);
                              final subjName = s['short_name'] ?? s['name'] ?? '';
                              final cab = s['cabinet'];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '$subjName${cab != null ? ' ($cab)' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ] else ...[
                        const SizedBox(height: 6),
                        Text(
                          loc.translate('day_no_lessons'),
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
    String? subtitle,
  }) {
    return LiquidGlassLens(
      style: LiquidTheme.cardStyle(isDark: isDark, radius: 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
