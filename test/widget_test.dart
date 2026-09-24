import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diary_flutter/main.dart';
import 'package:diary_flutter/core/api/api_client.dart';
import 'package:diary_flutter/core/database/hive_boxes.dart';
import 'package:diary_flutter/models/bell_slot_model.dart';
import 'package:diary_flutter/models/holiday_model.dart';
import 'package:diary_flutter/models/homework_model.dart';
import 'package:diary_flutter/models/lesson_note_model.dart';
import 'package:diary_flutter/models/schedule_model.dart';
import 'package:diary_flutter/models/subject_model.dart';
import 'package:diary_flutter/providers/alerts_provider.dart';
import 'package:diary_flutter/providers/api_client_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(Dio());

  @override
  Future<bool> checkHealth() async => true;

  @override
  Future<List<DaySchedule>> getScheduleRange(String startDate, String endDate) async => [];

  @override
  Future<List<HomeworkItem>> getHomeworkList({String? status, String? date}) async => [];

  @override
  Future<List<SubjectModel>> getSubjects() async => [];

  @override
  Future<List<BellSlotModel>> getBells() async => [];

  @override
  Future<List<LessonNoteModel>> getLessonNotes({String? date, String? subjectId}) async => [];

  @override
  Future<List<HolidayModel>> getHolidays() async => [];

  @override
  Future<Map<String, dynamic>> getWeeklyStats(String dateStr, {String mode = 'actual'}) async => {
    'total_lessons': 0,
    'total_minutes': 0,
    'study_time_display': '0h 0m',
    'cancelled_lessons': 0,
    'cancelled_minutes': 0,
    'cancellation_reasons': [],
    'events_summary': {},
    'homework_stats': {
      'total': 0,
      'completed': 0,
      'failed': 0,
      'rate': 0.0,
      'avg_completion_seconds': 0,
      'failed_items': [],
    },
    'break_stats': {'total_minutes': 0, 'avg_minutes': 0},
    'subjects_stats': [],
    'days_breakdown': [],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => ['wifi'],
    );
  });

  testWidgets('DiaryApp basic smoke test', (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    try {
      await tester.runAsync(() async {
        Hive.init(tempDir.path);
        await HiveBoxes.init(isTest: true);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(FakeApiClient()),
            airRaidAlertProvider.overrideWith(
              (ref) => AirRaidAlertNotifier(autoStart: false),
            ),
          ],
          child: const DiaryApp(),
        ),
      );

      // Pump a frame for initial layout
      await tester.pump();

      expect(find.byType(DiaryApp), findsOneWidget);
    } finally {
      await tester.runAsync(() async {
        await Hive.close();
      });
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });
}
