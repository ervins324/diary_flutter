import 'subject_model.dart';
import 'homework_model.dart';
import 'lesson_note_model.dart';

/// Lesson slot model representing one lesson in a day's schedule.
class LessonSlot {
  final String date;
  final int lessonOrder;
  final SubjectModel subject;
  final String startTime;
  final String endTime;
  final String? cabinet;
  final List<HomeworkItem> homework;
  final List<LessonNoteModel> notes;
  final SubjectModel? originalSubject;
  final bool isOverride;
  final bool isCancelled;
  final String? overrideNote;
  final String? eventType; // 'control_work' | 'test' | 'essay' | 'project' | null
  final bool isConsultation;

  const LessonSlot({
    required this.date,
    required this.lessonOrder,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.cabinet,
    this.homework = const [],
    this.notes = const [],
    this.originalSubject,
    this.isOverride = false,
    this.isCancelled = false,
    this.overrideNote,
    this.eventType,
    this.isConsultation = false,
  });

  static String formatTime(String timeStr) {
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  factory LessonSlot.fromJson(Map<String, dynamic> json) {
    var rawHw = json['homework'];
    List<HomeworkItem> parsedHw = [];
    if (rawHw is List) {
      parsedHw = rawHw
          .map((h) => HomeworkItem.fromJson(Map<String, dynamic>.from(h as Map)))
          .toList();
    }

    var rawNotes = json['notes'];
    List<LessonNoteModel> parsedNotes = [];
    if (rawNotes is List) {
      parsedNotes = rawNotes
          .map((n) => LessonNoteModel.fromJson(Map<String, dynamic>.from(n as Map)))
          .toList();
    }

    SubjectModel parsedSubject = SubjectModel.fromJson(
      Map<String, dynamic>.from(json['subject'] as Map? ?? {}),
    );

    SubjectModel? parsedOrigSubject;
    if (json['original_subject'] is Map) {
      parsedOrigSubject = SubjectModel.fromJson(
        Map<String, dynamic>.from(json['original_subject'] as Map),
      );
    }

    return LessonSlot(
      date: json['date']?.toString() ?? '',
      lessonOrder: (json['lesson_order'] as num?)?.toInt() ?? 1,
      subject: parsedSubject,
      startTime: formatTime(json['start_time'] as String? ?? '08:30'),
      endTime: formatTime(json['end_time'] as String? ?? '09:15'),
      cabinet: json['cabinet'] as String?,
      homework: parsedHw,
      notes: parsedNotes,
      originalSubject: parsedOrigSubject,
      isOverride: json['is_override'] as bool? ?? false,
      isCancelled: json['is_cancelled'] as bool? ?? false,
      overrideNote: json['override_note'] as String?,
      eventType: json['event_type'] as String?,
      isConsultation: json['is_consultation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'lesson_order': lessonOrder,
      'subject': subject.toJson(),
      'start_time': startTime,
      'end_time': endTime,
      'cabinet': cabinet,
      'homework': homework.map((h) => h.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'original_subject': originalSubject?.toJson(),
      'is_override': isOverride,
      'is_cancelled': isCancelled,
      'override_note': overrideNote,
      'event_type': eventType,
      'is_consultation': isConsultation,
    };
  }
}

/// Day schedule containing date, week type, and lessons.
class DaySchedule {
  final String date; // YYYY-MM-DD
  final String dayName;
  final String weekType; // 'numerator' | 'denominator' | 'all'
  final List<LessonSlot> lessons;
  final bool isHoliday;
  final String? holidayName;

  const DaySchedule({
    required this.date,
    required this.dayName,
    required this.weekType,
    required this.lessons,
    this.isHoliday = false,
    this.holidayName,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    var rawLessons = json['lessons'];
    List<LessonSlot> parsedLessons = [];
    if (rawLessons is List) {
      parsedLessons = rawLessons
          .map((l) => LessonSlot.fromJson(Map<String, dynamic>.from(l as Map)))
          .toList();
    }

    return DaySchedule(
      date: json['date']?.toString() ?? '',
      dayName: json['day_name'] as String? ?? '',
      weekType: json['week_type'] as String? ?? 'numerator',
      lessons: parsedLessons,
      isHoliday: json['is_holiday'] as bool? ?? false,
      holidayName: json['holiday_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_name': dayName,
      'week_type': weekType,
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'is_holiday': isHoliday,
      'holiday_name': holidayName,
    };
  }
}
