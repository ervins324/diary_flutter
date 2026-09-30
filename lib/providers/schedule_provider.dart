import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/database/hive_boxes.dart';
import '../models/schedule_model.dart';
import '../models/subject_model.dart';
import '../models/sync_action_model.dart';
import 'api_client_provider.dart';

/// Helper to determine the initial schedule date, optionally skipping weekends to Monday
DateTime getDefaultScheduleDate({bool? skipWeekends}) {
  final shouldSkip = skipWeekends ?? HiveBoxes.getSkipWeekends();
  final now = DateTime.now();
  if (shouldSkip) {
    if (now.weekday == DateTime.saturday) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 2));
    } else if (now.weekday == DateTime.sunday) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
    }
  }
  return now;
}

/// Currently selected date in the schedule viewer
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return getDefaultScheduleDate();
});

/// Calculates Monday-based ISO week difference to determine Numerator or Denominator.
String calculateWeekType(DateTime targetDate, {String? anchorDateStr}) {
  final anchor =
      DateTime.tryParse(anchorDateStr ?? AppConfig.defaultAnchorDate) ??
      DateTime(2026, 9, 1);

  // Compute Monday of both weeks
  final targetMonday = targetDate.subtract(
    Duration(days: targetDate.weekday - 1),
  );
  final anchorMonday = anchor.subtract(Duration(days: anchor.weekday - 1));

  final daysDiff = targetMonday.difference(anchorMonday).inDays;
  final weeksDiff = (daysDiff / 7).floor();

  return (weeksDiff % 2 == 0) ? 'numerator' : 'denominator';
}

/// Provides Monday date for any given date
DateTime getMonday(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - 1));
}

/// Flag indicating if the schedule couldn't be loaded from the server
final scheduleOfflineWarningProvider = StateProvider<bool>((ref) => false);

/// Schedule StateNotifier that loads and caches a week's schedule
class ScheduleNotifier extends StateNotifier<AsyncValue<List<DaySchedule>>> {
  final ApiClient _apiClient;
  final Ref _ref;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  ScheduleNotifier(this._apiClient, this._ref)
    : super(const AsyncValue.loading()) {
    loadWeekSchedule(_ref.read(selectedDateProvider));
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

  /// Create or update a lesson temporal override
  Future<void> setOverride(Map<String, dynamic> data) async {
    final dateStr = data['date']?.toString() ?? '';
    final lessonOrder = (data['lesson_order'] as num?)?.toInt() ?? 1;
    final newSubjectId = data['subject_id']?.toString();
    final isCancelled = data['is_cancelled'] as bool? ?? false;
    final cabinet = data['cabinet'] as String?;
    final note = data['note'] as String?;
    final eventType = data['event_type'] as String?;

    // Optimistically update local day schedule if present
    final currentList = state.valueOrNull;
    if (currentList != null && dateStr.isNotEmpty) {
      final cachedSubjects = HiveBoxes.getSubjects();
      SubjectModel? newSubj;
      if (newSubjectId != null && newSubjectId.isNotEmpty) {
        for (final s in cachedSubjects) {
          if (s.id == newSubjectId) {
            newSubj = s;
            break;
          }
        }
      }

      final updatedList = currentList.map((day) {
        if (day.date == dateStr) {
          final updatedLessons = day.lessons.map((l) {
            if (l.lessonOrder == lessonOrder) {
              return l.copyWith(
                subject: newSubj ?? l.subject,
                originalSubject: l.originalSubject ?? l.subject,
                cabinet: cabinet,
                isCancelled: isCancelled,
                overrideNote: note,
                eventType: eventType,
                isOverride: true,
              );
            }
            return l;
          }).toList();
          return day.copyWith(lessons: updatedLessons);
        }
        return day;
      }).toList();

      state = AsyncValue.data(updatedList);
      await HiveBoxes.saveSchedules(updatedList);
    }

    try {
      await _apiClient.setScheduleOverride(data);
      final parsedDate = DateTime.tryParse(dateStr);
      final DateTime targetDate =
          parsedDate ?? _ref.read<DateTime>(selectedDateProvider);
      await loadWeekSchedule(targetDate);
    } catch (_) {
      final action = SyncAction(
        id: const Uuid().v4(),
        actionType: 'SET_SCHEDULE_OVERRIDE',
        endpoint: '${AppConfig.apiPrefix}/schedule/override',
        httpMethod: 'POST',
        payload: data,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _ref.read(syncQueueProvider).enqueue(action);
    }
  }

  /// Remove an override and restore regular recurring schedule rule
  Future<void> deleteOverride(String targetDate, int lessonOrder) async {
    try {
      await _apiClient.deleteScheduleOverride(targetDate, lessonOrder);
      final parsedDate = DateTime.tryParse(targetDate);
      final DateTime dt =
          parsedDate ?? _ref.read<DateTime>(selectedDateProvider);
      await loadWeekSchedule(dt);
    } catch (_) {
      final action = SyncAction(
        id: const Uuid().v4(),
        actionType: 'DELETE_SCHEDULE_OVERRIDE',
        endpoint:
            '${AppConfig.apiPrefix}/schedule/override?target_date=$targetDate&lesson_order=$lessonOrder',
        httpMethod: 'DELETE',
        payload: {},
        createdAt: DateTime.now().toIso8601String(),
      );
      await _ref.read(syncQueueProvider).enqueue(action);
      final parsedDate = DateTime.tryParse(targetDate);
      final DateTime dt =
          parsedDate ?? _ref.read<DateTime>(selectedDateProvider);
      await loadWeekSchedule(dt);
    }
  }

  /// Find next lesson strictly after (currentDate, currentLessonOrder)
  Future<AdjacentLessonResult?> findNextLesson(
    String subjectId, {
    String? currentDate,
    int? currentLessonOrder,
  }) async {
    try {
      final res = await _apiClient.getNextLesson(
        subjectId,
        currentDate: currentDate,
        currentLessonOrder: currentLessonOrder,
      );
      if (res != null) return res;
    } catch (_) {}

    return _findAdjacentCached(
      subjectId,
      currentDate: currentDate,
      currentLessonOrder: currentLessonOrder,
      isNext: true,
    );
  }

  /// Find previous lesson strictly before (currentDate, currentLessonOrder)
  Future<AdjacentLessonResult?> findPreviousLesson(
    String subjectId, {
    String? currentDate,
    int? currentLessonOrder,
  }) async {
    try {
      final res = await _apiClient.getPreviousLesson(
        subjectId,
        currentDate: currentDate,
        currentLessonOrder: currentLessonOrder,
      );
      if (res != null) return res;
    } catch (_) {}

    return _findAdjacentCached(
      subjectId,
      currentDate: currentDate,
      currentLessonOrder: currentLessonOrder,
      isNext: false,
    );
  }

  AdjacentLessonResult? _findAdjacentCached(
    String subjectId, {
    String? currentDate,
    int? currentLessonOrder,
    required bool isNext,
  }) {
    final cached = HiveBoxes.getAllCachedSchedules();
    if (cached.isEmpty) return null;

    final currDate = currentDate ?? _dateFormat.format(DateTime.now());
    final currOrder = currentLessonOrder ?? (isNext ? 0 : 999);

    final allLessons = <LessonSlot>[];
    for (final day in cached) {
      for (final l in day.lessons) {
        if (l.subject.id == subjectId || (l.originalSubject?.id == subjectId)) {
          allLessons.add(l);
        }
      }
    }

    if (isNext) {
      allLessons.sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.lessonOrder.compareTo(b.lessonOrder);
      });
      for (final l in allLessons) {
        if (l.date.compareTo(currDate) > 0 ||
            (l.date == currDate && l.lessonOrder > currOrder)) {
          return AdjacentLessonResult(
            date: l.date,
            lessonOrder: l.lessonOrder,
            subjectId: l.subject.id,
            subjectName: l.subject.name,
            startTime: l.startTime,
            endTime: l.endTime,
            cabinet: l.cabinet,
          );
        }
      }
    } else {
      allLessons.sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.lessonOrder.compareTo(a.lessonOrder);
      });
      for (final l in allLessons) {
        if (l.date.compareTo(currDate) < 0 ||
            (l.date == currDate && l.lessonOrder < currOrder)) {
          return AdjacentLessonResult(
            date: l.date,
            lessonOrder: l.lessonOrder,
            subjectId: l.subject.id,
            subjectName: l.subject.name,
            startTime: l.startTime,
            endTime: l.endTime,
            cabinet: l.cabinet,
          );
        }
      }
    }
    return null;
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<List<DaySchedule>>>((
      ref,
    ) {
      final api = ref.watch(apiClientProvider);
      return ScheduleNotifier(api, ref);
    });
