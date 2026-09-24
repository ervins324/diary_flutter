import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'api_client_provider.dart';

/// Currently navigated date for stats calculation (defaults to today)
final statsDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Schedule calculation template mode: 'actual' | 'numerator' | 'denominator'
final statsScheduleModeProvider = StateProvider<String>((ref) => 'actual');

/// Metric toggle: 'time' (Hours & minutes) | 'lessons' (Number of lessons)
final statsMetricModeProvider = StateProvider<String>((ref) => 'time');

/// View mode toggle: 'subjects' (by subject bars) | 'days' (by daily breakdown)
final statsViewModeProvider = StateProvider<String>((ref) => 'subjects');

/// Comprehensive weekly stats provider mirroring FastAPI /api/v1/stats/weekly
final weeklyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final date = ref.watch(statsDateProvider);
  final scheduleMode = ref.watch(statsScheduleModeProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);

  try {
    return await api.getWeeklyStats(dateStr, mode: scheduleMode);
  } catch (_) {
    // Return empty fallback map on error or offline
    return {
      'start_date': dateStr,
      'end_date': dateStr,
      'mode': scheduleMode,
      'subjects': <Map<String, dynamic>>[],
      'days': <Map<String, dynamic>>[],
      'total_subjects': 0,
      'total_lessons': 0,
      'avg_lessons_per_day': 0.0,
      'total_break_minutes': 0,
      'cancelled_lessons_count': 0,
      'total_cancelled_minutes': 0,
      'cancellation_reasons': <Map<String, dynamic>>[],
      'event_counts': {
        'control_work': 0,
        'test': 0,
        'essay': 0,
        'project': 0,
      },
      'homework_stats': {
        'total': 0,
        'completed': 0,
        'failed': 0,
        'completion_rate': 100.0,
        'failure_rate': 0.0,
        'total_time_spent_seconds': 0,
        'avg_time_spent_seconds': 0,
        'failed_items': <Map<String, dynamic>>[],
      },
    };
  }
});
