import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';
import '../../models/subject_model.dart';
import '../../models/bell_slot_model.dart';
import '../../models/homework_model.dart';
import '../../models/lesson_note_model.dart';
import '../../models/schedule_model.dart';
import '../../models/holiday_model.dart';
import '../../models/sync_action_model.dart';

/// Centralized manager for local Hive storage boxes.
class HiveBoxes {
  static late Box _settingsBox;
  static late Box _scheduleBox;
  static late Box _homeworkBox;
  static late Box _notesBox;
  static late Box _subjectsBox;
  static late Box _bellsBox;
  static late Box _holidaysBox;
  static late Box _syncQueueBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(AppConfig.boxSettings);
    _scheduleBox = await Hive.openBox(AppConfig.boxSchedule);
    _homeworkBox = await Hive.openBox(AppConfig.boxHomework);
    _notesBox = await Hive.openBox(AppConfig.boxNotes);
    _subjectsBox = await Hive.openBox(AppConfig.boxSubjects);
    _bellsBox = await Hive.openBox(AppConfig.boxBells);
    _holidaysBox = await Hive.openBox(AppConfig.boxHolidays);
    _syncQueueBox = await Hive.openBox(AppConfig.boxSyncQueue);
  }

  // ── Settings ──────────────────────────────────────────────────
  static String getServerUrl() {
    return _settingsBox.get('server_url', defaultValue: AppConfig.defaultServerUrl) as String;
  }

  static Future<void> setServerUrl(String url) async {
    await _settingsBox.put('server_url', url);
  }

  static String getLanguage() {
    return _settingsBox.get('language', defaultValue: 'uk') as String;
  }

  static Future<void> setLanguage(String lang) async {
    await _settingsBox.put('language', lang);
  }

  static String getThemeMode() {
    return _settingsBox.get('theme_mode', defaultValue: 'system') as String;
  }

  static Future<void> setThemeMode(String mode) async {
    await _settingsBox.put('theme_mode', mode);
  }

  static String getAlertRegion() {
    return _settingsBox.get('alert_region', defaultValue: 'м. Київ') as String;
  }

  static Future<void> setAlertRegion(String region) async {
    await _settingsBox.put('alert_region', region);
  }

  // ── Subjects ──────────────────────────────────────────────────
  static List<SubjectModel> getSubjects() {
    return _subjectsBox.values.map((v) {
      if (v is Map) {
        return SubjectModel.fromJson(Map<String, dynamic>.from(v));
      }
      return SubjectModel.fromJson(jsonDecode(v.toString()));
    }).toList();
  }

  static Future<void> saveSubjects(List<SubjectModel> subjects) async {
    await _subjectsBox.clear();
    for (final s in subjects) {
      await _subjectsBox.put(s.id, s.toJson());
    }
  }

  static Future<void> saveSubject(SubjectModel subject) async {
    await _subjectsBox.put(subject.id, subject.toJson());
  }

  static Future<void> deleteSubject(String id) async {
    await _subjectsBox.delete(id);
  }

  // ── Bells ─────────────────────────────────────────────────────
  static List<BellSlotModel> getBells() {
    final list = _bellsBox.values.map((v) {
      if (v is Map) {
        return BellSlotModel.fromJson(Map<String, dynamic>.from(v));
      }
      return BellSlotModel.fromJson(jsonDecode(v.toString()));
    }).toList();
    list.sort((a, b) => a.lessonOrder.compareTo(b.lessonOrder));
    return list;
  }

  static Future<void> saveBells(List<BellSlotModel> bells) async {
    await _bellsBox.clear();
    for (final b in bells) {
      await _bellsBox.put(b.id, b.toJson());
    }
  }

  // ── Schedule ──────────────────────────────────────────────────
  static DaySchedule? getScheduleForDate(String dateStr) {
    final raw = _scheduleBox.get(dateStr);
    if (raw == null) return null;
    if (raw is Map) {
      return DaySchedule.fromJson(Map<String, dynamic>.from(raw));
    }
    return DaySchedule.fromJson(jsonDecode(raw.toString()));
  }

  static List<DaySchedule> getAllCachedSchedules() {
    return _scheduleBox.values.map((v) {
      if (v is Map) {
        return DaySchedule.fromJson(Map<String, dynamic>.from(v));
      }
      return DaySchedule.fromJson(jsonDecode(v.toString()));
    }).toList();
  }

  static Future<void> saveSchedules(List<DaySchedule> schedules) async {
    for (final s in schedules) {
      await _scheduleBox.put(s.date, s.toJson());
    }
  }

  // ── Homework ──────────────────────────────────────────────────
  static List<HomeworkItem> getHomeworkList() {
    final list = _homeworkBox.values.map((v) {
      if (v is Map) {
        return HomeworkItem.fromJson(Map<String, dynamic>.from(v));
      }
      return HomeworkItem.fromJson(jsonDecode(v.toString()));
    }).toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  static Future<void> saveHomeworkList(List<HomeworkItem> items) async {
    for (final h in items) {
      await _homeworkBox.put(h.id, h.toJson());
    }
  }

  static Future<void> saveHomeworkItem(HomeworkItem item) async {
    await _homeworkBox.put(item.id, item.toJson());
  }

  static Future<void> deleteHomeworkItem(String id) async {
    await _homeworkBox.delete(id);
  }

  // ── Lesson Notes ──────────────────────────────────────────────
  static List<LessonNoteModel> getNotes() {
    final list = _notesBox.values.map((v) {
      if (v is Map) {
        return LessonNoteModel.fromJson(Map<String, dynamic>.from(v));
      }
      return LessonNoteModel.fromJson(jsonDecode(v.toString()));
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> saveNotes(List<LessonNoteModel> notes) async {
    for (final n in notes) {
      await _notesBox.put(n.id, n.toJson());
    }
  }

  static Future<void> saveNote(LessonNoteModel note) async {
    await _notesBox.put(note.id, note.toJson());
  }

  static Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  // ── Holidays ──────────────────────────────────────────────────
  static List<HolidayModel> getHolidays() {
    return _holidaysBox.values.map((v) {
      if (v is Map) {
        return HolidayModel.fromJson(Map<String, dynamic>.from(v));
      }
      return HolidayModel.fromJson(jsonDecode(v.toString()));
    }).toList();
  }

  static Future<void> saveHolidays(List<HolidayModel> holidays) async {
    await _holidaysBox.clear();
    for (final h in holidays) {
      await _holidaysBox.put(h.id, h.toJson());
    }
  }

  // ── Offline Sync Queue ────────────────────────────────────────
  static List<SyncAction> getSyncQueue() {
    return _syncQueueBox.values.map((v) {
      if (v is Map) {
        return SyncAction.fromJson(Map<String, dynamic>.from(v));
      }
      return SyncAction.fromJson(jsonDecode(v.toString()));
    }).toList();
  }

  static Future<void> enqueueSyncAction(SyncAction action) async {
    await _syncQueueBox.put(action.id, action.toJson());
  }

  static Future<void> removeSyncAction(String id) async {
    await _syncQueueBox.delete(id);
  }

  static int getPendingSyncCount() {
    return _syncQueueBox.length;
  }

  static Future<void> clearAllCache() async {
    await _scheduleBox.clear();
    await _homeworkBox.clear();
    await _notesBox.clear();
    await _subjectsBox.clear();
    await _bellsBox.clear();
    await _holidaysBox.clear();
  }
}
