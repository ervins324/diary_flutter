import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/api/api_client.dart';
import '../core/database/hive_boxes.dart';
import '../core/sync/sync_queue_manager.dart';
import '../models/homework_model.dart';
import '../models/lesson_note_model.dart';
import '../models/subject_model.dart';
import '../models/sync_action_model.dart';
import 'api_client_provider.dart';

final notesSearchProvider = StateProvider<String>((ref) => '');

class NotesNotifier extends StateNotifier<List<LessonNoteModel>> {
  final ApiClient _apiClient;
  final SyncQueueManager _syncQueue;

  NotesNotifier(this._apiClient, this._syncQueue) : super([]) {
    loadCached();
    fetchRemote();
  }

  void loadCached() {
    state = HiveBoxes.getNotes();
  }

  Future<void> fetchRemote() async {
    try {
      final remote = await _apiClient.getLessonNotes();
      final pendingIds = state.where((n) => n.isPendingSync).map((n) => n.id).toSet();
      final merged = <LessonNoteModel>[];

      for (final item in remote) {
        if (!pendingIds.contains(item.id)) {
          merged.add(item);
        }
      }
      merged.addAll(state.where((n) => n.isPendingSync));
      merged.sort((a, b) => b.date.compareTo(a.date));

      await HiveBoxes.saveNotes(merged);
      state = merged;
    } catch (_) {
      // Offline fallback
    }
  }

  Future<void> addNote({
    required String subjectId,
    required String date,
    required int lessonOrder,
    required String text,
    List<String> stagedLocalFiles = const [],
    SubjectModel? subject,
  }) async {
    final newId = const Uuid().v4();
    final stagedAttachments = stagedLocalFiles.map((path) {
      return AttachmentItem(
        name: path.split('/').last,
        type: path.endsWith('.pdf') ? 'pdf' : 'image',
        url: path,
        localFilePath: path,
      );
    }).toList();

    final newNote = LessonNoteModel(
      id: newId,
      subjectId: subjectId,
      date: date,
      lessonOrder: lessonOrder,
      text: text,
      attachments: stagedAttachments,
      subject: subject,
      isPendingSync: true,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final updated = [newNote, ...state]..sort((a, b) => b.date.compareTo(a.date));
    state = updated;
    await HiveBoxes.saveNote(newNote);

    await _syncQueue.enqueue(
      SyncAction(
        id: const Uuid().v4(),
        actionType: 'CREATE_NOTE',
        endpoint: '/api/v1/lesson-notes',
        httpMethod: 'POST',
        payload: {
          'id': newId,
          'subject_id': subjectId,
          'date': date,
          'lesson_order': lessonOrder,
          'text': text,
        },
        localFilePaths: stagedLocalFiles,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> editNote(LessonNoteModel note, String newText) async {
    final updated = note.copyWith(
      text: newText,
      updatedAt: DateTime.now().toIso8601String(),
      isPendingSync: true,
    );

    state = state.map((n) => n.id == note.id ? updated : n).toList();
    await HiveBoxes.saveNote(updated);

    await _syncQueue.enqueue(
      SyncAction(
        id: const Uuid().v4(),
        actionType: 'UPDATE_NOTE',
        endpoint: '/api/v1/lesson-notes/${note.id}',
        httpMethod: 'PATCH',
        payload: {'text': newText},
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> deleteNote(String id) async {
    state = state.where((n) => n.id != id).toList();
    await HiveBoxes.deleteNote(id);

    await _syncQueue.enqueue(
      SyncAction(
        id: const Uuid().v4(),
        actionType: 'DELETE_NOTE',
        endpoint: '/api/v1/lesson-notes/$id',
        httpMethod: 'DELETE',
        payload: {},
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}

final notesListProvider =
    StateNotifierProvider<NotesNotifier, List<LessonNoteModel>>((ref) {
  final api = ref.watch(apiClientProvider);
  final queue = ref.read(syncQueueProvider);
  return NotesNotifier(api, queue);
});
