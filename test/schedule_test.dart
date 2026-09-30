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
      final result = calculateWeekType(
        nextWeekDate,
        anchorDateStr: '2026-09-01',
      );
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

    test('AdjacentLessonResult JSON roundtrip serialization', () {
      const adjacent = AdjacentLessonResult(
        date: '2026-09-03',
        lessonOrder: 2,
        subjectId: 'sub-1',
        subjectName: 'Mathematics',
        startTime: '09:25',
        endTime: '10:10',
        cabinet: '101',
      );

      final json = adjacent.toJson();
      final parsed = AdjacentLessonResult.fromJson(json);

      expect(parsed.date, equals('2026-09-03'));
      expect(parsed.lessonOrder, equals(2));
      expect(parsed.subjectId, equals('sub-1'));
      expect(parsed.subjectName, equals('Mathematics'));
      expect(parsed.startTime, equals('09:25'));
      expect(parsed.endTime, equals('10:10'));
      expect(parsed.cabinet, equals('101'));
    });

    test('LessonSlot copyWith preserves and modifies override fields', () {
      const originalSubject = SubjectModel(
        id: 'sub-1',
        name: 'Mathematics',
        shortName: 'Math',
        colorHex: '#6366F1',
      );
      const substitutedSubject = SubjectModel(
        id: 'sub-2',
        name: 'Physics',
        shortName: 'Phys',
        colorHex: '#3B82F6',
      );

      final slot = LessonSlot(
        date: '2026-09-01',
        lessonOrder: 1,
        subject: originalSubject,
        startTime: '08:30',
        endTime: '09:15',
        cabinet: '101',
      );

      final overrideSlot = slot.copyWith(
        subject: substitutedSubject,
        originalSubject: originalSubject,
        isOverride: true,
        isCancelled: false,
        eventType: 'control_work',
        overrideNote: 'Teacher substitution & Control work',
        cabinet: '204',
      );

      expect(overrideSlot.isOverride, isTrue);
      expect(overrideSlot.isCancelled, isFalse);
      expect(overrideSlot.subject.name, equals('Physics'));
      expect(overrideSlot.originalSubject?.name, equals('Mathematics'));
      expect(overrideSlot.eventType, equals('control_work'));
      expect(overrideSlot.cabinet, equals('204'));
      expect(overrideSlot.overrideNote, contains('Control work'));

      final cancelledSlot = overrideSlot.copyWith(
        isCancelled: true,
        overrideNote: 'Повітряна тривога',
      );

      expect(cancelledSlot.isCancelled, isTrue);
      expect(cancelledSlot.overrideNote, equals('Повітряна тривога'));
    });
  });
}
