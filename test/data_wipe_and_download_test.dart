import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:diary_flutter/core/api/api_client.dart';
import 'package:diary_flutter/core/database/hive_boxes.dart';
import 'package:diary_flutter/core/sync/sync_queue_manager.dart';
import 'package:diary_flutter/core/utils/file_download_helper.dart';
import 'package:diary_flutter/models/bell_slot_model.dart';
import 'package:diary_flutter/models/homework_model.dart';
import 'package:diary_flutter/models/lesson_note_model.dart';
import 'package:diary_flutter/models/schedule_model.dart';
import 'package:diary_flutter/models/subject_model.dart';
import 'package:diary_flutter/models/sync_action_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_wipe_test_');
    FileDownloadHelper.overrideSaveDirectory = tempDir;
    Hive.init(tempDir.path);
    await HiveBoxes.init(isTest: true);
  });

  tearDownAll(() async {
    FileDownloadHelper.overrideSaveDirectory = null;
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('FileDownloadHelper Utility Tests', () {
    test('sanitizeFileName removes illegal filesystem characters', () {
      expect(
        FileDownloadHelper.sanitizeFileName('homework:math/ch1*test?.pdf'),
        equals('homework_math_ch1_test_.pdf'),
      );
      expect(FileDownloadHelper.sanitizeFileName('   '), startsWith('file_'));
    });

    test('guessExtension detects common academic document and image types', () {
      expect(FileDownloadHelper.guessExtension('image/png'), equals('.png'));
      expect(
        FileDownloadHelper.guessExtension('application/pdf'),
        equals('.pdf'),
      );
      expect(
        FileDownloadHelper.guessExtension('presentation.pptx'),
        equals('.pptx'),
      );
      expect(FileDownloadHelper.guessExtension('image/webp'), equals('.webp'));
      expect(FileDownloadHelper.guessExtension('image/jpeg'), equals('.jpg'));
      expect(
        FileDownloadHelper.guessExtension('unknown/mime', '.bin'),
        equals('.bin'),
      );
    });

    test(
      'downloadOrSave successfully decodes and writes base64 image data',
      () async {
        // 1x1 transparent PNG base64
        const base64Png =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

        final result = await FileDownloadHelper.downloadOrSave(
          rawUrl: base64Png,
          preferredFileName: 'test_unit_saved.png',
        );

        expect(result.success, isTrue);
        expect(result.filePath, isNotNull);
        expect(result.fileName, contains('test_unit_saved'));

        final file = File(result.filePath!);
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThan(0));

        // Clean up test artifact
        try {
          file.deleteSync();
        } catch (_) {}
      },
    );

    test('downloadOrSave copies existing local staged file', () async {
      final staged = File('${tempDir.path}/staged_hw_test.txt');
      await staged.writeAsString('Homework assignment notes content');

      final result = await FileDownloadHelper.downloadOrSave(
        rawUrl: staged.path,
        preferredFileName: 'copied_hw_test.txt',
      );

      expect(result.success, isTrue);
      expect(result.filePath, isNotNull);

      final file = File(result.filePath!);
      expect(file.existsSync(), isTrue);
      expect(
        file.readAsStringSync(),
        equals('Homework assignment notes content'),
      );

      try {
        staged.deleteSync();
        file.deleteSync();
      } catch (_) {}
    });
  });

  group('Wipe All Local Data Tests', () {
    test(
      'wipeAllLocalData empties all 7 data boxes and clears last_sync_timestamp',
      () async {
        // Populate boxes with test entities
        await HiveBoxes.saveSubject(
          const SubjectModel(
            id: 'sub-test',
            name: 'History',
            shortName: 'Hist',
            colorHex: '#E11D48',
          ),
        );
        await HiveBoxes.saveBells([
          const BellSlotModel(
            id: '1',
            lessonOrder: 1,
            startTime: '08:30',
            endTime: '09:15',
          ),
        ]);
        await HiveBoxes.saveHomeworkItem(
          const HomeworkItem(
            id: 'hw-test',
            subjectId: 'sub-test',
            dueDate: '2026-10-01',
            text: 'Read Chapter 4',
          ),
        );
        await HiveBoxes.saveNote(
          const LessonNoteModel(
            id: 'note-test',
            subjectId: 'sub-test',
            date: '2026-10-01',
            lessonOrder: 1,
            text: 'Notes from lesson',
          ),
        );
        await HiveBoxes.saveSchedules([
          const DaySchedule(
            date: '2026-10-01',
            dayName: 'Thursday',
            weekType: 'numerator',
            lessons: [],
          ),
        ]);
        await HiveBoxes.enqueueSyncAction(
          const SyncAction(
            id: 'sync-test',
            actionType: 'CREATE_HOMEWORK',
            endpoint: '/api/v1/homework',
            httpMethod: 'POST',
            payload: {'text': 'sync me'},
            createdAt: '2026-10-01T10:00:00Z',
          ),
        );
        await HiveBoxes.setLastSyncTime(DateTime.now());

        // Verify populated state
        expect(HiveBoxes.getSubjects().length, equals(1));
        expect(HiveBoxes.getBells().length, equals(1));
        expect(HiveBoxes.getHomeworkList().length, equals(1));
        expect(HiveBoxes.getNotes().length, equals(1));
        expect(HiveBoxes.getAllCachedSchedules().length, equals(1));
        expect(HiveBoxes.getPendingSyncCount(), equals(1));
        expect(HiveBoxes.getLastSyncTime(), isNotNull);

        // Execute complete wipe
        await HiveBoxes.wipeAllLocalData();

        // Verify all boxes are completely empty
        expect(HiveBoxes.getSubjects(), isEmpty);
        expect(HiveBoxes.getBells(), isEmpty);
        expect(HiveBoxes.getHomeworkList(), isEmpty);
        expect(HiveBoxes.getNotes(), isEmpty);
        expect(HiveBoxes.getAllCachedSchedules(), isEmpty);
        expect(HiveBoxes.getHolidays(), isEmpty);
        expect(HiveBoxes.getPendingSyncCount(), equals(0));
        expect(HiveBoxes.getLastSyncTime(), isNull);
      },
    );

    test(
      'SyncQueueManager clearQueue sets pending count to 0 and clears queue box',
      () async {
        final client = ApiClient();
        final queueManager = SyncQueueManager(client);

        await queueManager.enqueue(
          const SyncAction(
            id: 'sync-action-1',
            actionType: 'UPDATE_HOMEWORK',
            endpoint: '/api/v1/homework/1',
            httpMethod: 'PATCH',
            payload: {'is_completed': true},
            createdAt: '2026-10-01T10:00:00Z',
          ),
        );

        expect(queueManager.state.pendingCount, equals(1));
        expect(HiveBoxes.getPendingSyncCount(), equals(1));

        await queueManager.clearQueue();

        expect(queueManager.state.pendingCount, equals(0));
        expect(HiveBoxes.getPendingSyncCount(), equals(0));

        queueManager.dispose();
      },
    );
  });
}
