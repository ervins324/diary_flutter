import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'api_client_provider.dart';

final statsDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final weeklyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final date = ref.watch(statsDateProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);

  try {
    return await api.getWeeklyStats(dateStr);
  } catch (_) {
    return {
      'total_lessons': 0,
      'completed_homeworks': 0,
      'total_homeworks': 0,
      'total_time_spent_seconds': 0,
      'subjects_breakdown': <Map<String, dynamic>>[],
    };
  }
});
