import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/database/hive_boxes.dart';
import '../models/schedule_model.dart';
import 'api_client_provider.dart';

/// Currently selected date in the schedule viewer
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Calculates Monday-based ISO week difference to determine Numerator or Denominator.
String calculateWeekType(DateTime targetDate, {String? anchorDateStr}) {
  final anchor = DateTime.tryParse(anchorDateStr ?? AppConfig.defaultAnchorDate) ??
      DateTime(2026, 9, 1);

  // Compute Monday of both weeks
  final targetMonday = targetDate.subtract(Duration(days: targetDate.weekday - 1));
  final anchorMonday = anchor.subtract(Duration(days: anchor.weekday - 1));

  final daysDiff = targetMonday.difference(anchorMonday).inDays;
  final weeksDiff = (daysDiff / 7).floor();

  return (weeksDiff % 2 == 0) ? 'numerator' : 'denominator';
}

/// Provides Monday date for any given date
DateTime getMonday(DateTime date) {
  return DateTime(date.year, date.month, date.day).subtract(
    Duration(days: date.weekday - 1),
  );
}

/// Flag indicating if the schedule couldn't be loaded from the server
final scheduleOfflineWarningProvider = StateProvider<bool>((ref) => false);

/// Schedule StateNotifier that loads and caches a week's schedule
class ScheduleNotifier extends StateNotifier<AsyncValue<List<DaySchedule>>> {
  final ApiClient _apiClient;
  final Ref _ref;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  ScheduleNotifier(this._apiClient, this._ref) : super(const AsyncValue.loading()) {
    loadWeekSchedule(DateTime.now());
  }

  Future<void> loadWeekSchedule(DateTime targetDate) async {
    final monday = getMonday(targetDate);
    final sunday = monday.add(const Duration(days: 6));
    final startStr = _dateFormat.format(monday);
    final endStr = _dateFormat.format(sunday);

    // 1. First populate from local cache so the UI never blocks
    final cachedDays = <DaySchedule>[];
    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dayStr = _dateFormat.format(dayDate);
      final cached = HiveBoxes.getScheduleForDate(dayStr);
      if (cached != null) {
        cachedDays.add(cached);
      }
    }

    if (cachedDays.isNotEmpty) {
      state = AsyncValue.data(cachedDays);
    }

    // 2. Fetch fresh schedule from server
    try {
      final remoteDays = await _apiClient.getScheduleRange(startStr, endStr);
      if (remoteDays.isNotEmpty) {
        await HiveBoxes.saveSchedules(remoteDays);
        state = AsyncValue.data(remoteDays);
        _ref.read(scheduleOfflineWarningProvider.notifier).state = false;
      }
    } catch (e) {
      _ref.read(scheduleOfflineWarningProvider.notifier).state = true;
      if (cachedDays.isEmpty) {
        // Generate empty 7 days for the selected week so UI stays intact
        final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
        final fallbackDays = List.generate(7, (i) {
          final dayDate = monday.add(Duration(days: i));
          final dayStr = _dateFormat.format(dayDate);
          return DaySchedule(
            date: dayStr,
            dayName: dayNames[i],
            weekType: calculateWeekType(dayDate),
            lessons: [],
          );
        });
        state = AsyncValue.data(fallbackDays);
      }
    }
  }

  /// Manually refresh current week
  Future<void> refresh(DateTime targetDate) async {
    await loadWeekSchedule(targetDate);
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<List<DaySchedule>>>((ref) {
  final api = ref.watch(apiClientProvider);
  return ScheduleNotifier(api, ref);
});
