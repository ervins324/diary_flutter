import 'package:flutter_test/flutter_test.dart';
import 'package:diary_flutter/models/schedule_model.dart';
import 'package:diary_flutter/models/subject_model.dart';
import 'package:diary_flutter/providers/schedule_provider.dart';

void main() {
  group('Schedule Logic & Serialization Tests', () {
    test('calculateWeekType calculates numerator for anchor date', () {
      final anchor = DateTime(2026, 9, 1); // Tuesday
      // Week of Sept 1, 2026 should be numerator
      final result = calculateWeekType(anchor, anchorDateStr: '2026-09-01');
      expect(result, equals('numerator'));
    });

    test('calculateWeekType calculates denominator for subsequent week', () {
      final nextWeekDate = DateTime(2026, 9, 8);
      final result = calculateWeekType(nextWeekDate, anchorDateStr: '2026-09-01');
      expect(result, equals('denominator'));
    });

    test('DaySchedule JSON roundtrip serialization', () {
      const subject = SubjectModel(
        id: 'sub-1',
        name: 'Mathematics',
        shortName: 'Math',
        colorHex: '#6366F1',
        defaultCabinet: '101',
      );

      final lesson = LessonSlot(
        date: '2026-09-01',
        lessonOrder: 1,
        subject: subject,
        startTime: '08:30',
        endTime: '09:15',
        cabinet: '101',
        isConsultation: false,
      );

      final daySchedule = DaySchedule(
        date: '2026-09-01',
        dayName: 'Tuesday',
        weekType: 'numerator',
        lessons: [lesson],
      );

      final json = daySchedule.toJson();
      final parsed = DaySchedule.fromJson(json);

      expect(parsed.date, equals('2026-09-01'));
      expect(parsed.weekType, equals('numerator'));
      expect(parsed.lessons.length, equals(1));
      expect(parsed.lessons.first.subject.name, equals('Mathematics'));
    });
  });
}
