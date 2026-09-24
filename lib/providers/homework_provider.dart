import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/api/api_client.dart';
import '../core/database/hive_boxes.dart';
import '../core/sync/sync_queue_manager.dart';
import '../models/homework_model.dart';
import '../models/subject_model.dart';
import '../models/sync_action_model.dart';
import 'api_client_provider.dart';

/// Filter selection for homework view
final homeworkFilterProvider = StateProvider<String>((ref) => 'pending');

class HomeworkNotifier extends StateNotifier<List<HomeworkItem>> {
  final ApiClient _apiClient;
  final SyncQueueManager _syncQueue;

  HomeworkNotifier(this._apiClient, this._syncQueue) : super([]) {
    loadCached();
    fetchRemote();
  }

  void loadCached() {
    state = HiveBoxes.getHomeworkList();
  }

  Future<void> fetchRemote() async {
    try {
      final remote = await _apiClient.getHomeworkList();
      // Merge remote with local pending sync items so un-synced edits are never overwritten
      final pendingIds = state.where((h) => h.isPendingSync).map((h) => h.id).toSet();
      final merged = <HomeworkItem>[];

      for (final item in remote) {
        if (!pendingIds.contains(item.id)) {
          merged.add(item);
        }
      }
      // Keep pending items
      merged.addAll(state.where((h) => h.isPendingSync));
      merged.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      await HiveBoxes.saveHomeworkList(merged);
      state = merged;
    } catch (_) {
      // Offline fallback: keep cached state
    }
  }

  /// Toggle homework completion offline-first
  Future<void> toggleComplete(HomeworkItem item) async {
    final updated = item.copyWith(
      isCompleted: !item.isCompleted,
      isPendingSync: true,
    );

    // 1. Instant local update
    state = state.map((h) => h.id == item.id ? updated : h).toList();
    await HiveBoxes.saveHomeworkItem(updated);

    // 2. Queue sync action
    await _syncQueue.enqueue(
      SyncAction(
        id: const Uuid().v4(),
        actionType: 'UPDATE_HOMEWORK',
        endpoint: '/api/v1/homework/${item.id}',
        httpMethod: 'PATCH',
        payload: {'is_completed': updated.isCompleted},
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Toggle failed status offline-first
  Future<void> toggleFailed(HomeworkItem item) async {
    final updated = item.copyWith(
      isFailed: !item.isFailed,
      isPendingSync: true,
    );

    state = state.map((h) => h.id == item.id ? updated : h).toList();
    await HiveBoxes.saveHomeworkItem(updated);

    await _syncQueue.enqueue(
      SyncAction(
        id: const Uuid().v4(),
        actionType: 'UPDATE_HOMEWORK',
        endpoint: '/api/v1/homework/${item.id}',
        httpMethod: 'PATCH',
        payload: {'is_failed': updated.isFailed},
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Create new homework offline-first with staged attachments
  Future<void> addHomework({
    required String subjectId,
    required String dueDate,
    int? lessonOrder,
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

    final newItem = HomeworkItem(
      id: newId,
      subjectId: subjectId,
      dueDate: dueDate,
      lessonOrder: lessonOrder,
      text: text,
      attachments: stagedAttachments,
      subject: subject,
      isPendingSync: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Local instant save
    final updated = [...state, newItem]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    state = updated;
    await HiveBoxes.saveHomeworkItem(newItem);

    // Enqueue sync action
    await _syncQueue.enqueue(
      SyncAction(
        id: const Uuid().v4(),
        actionType: 'CREATE_HOMEWORK',
        endpoint: '/api/v1/homework',
        httpMethod: 'POST',
        payload: {
          'subject_id': subjectId,
          'due_date': dueDate,
          'lesson_order': lessonOrder,
          'text': text,
        },
        localFilePaths: stagedLocalFiles,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Update time spent counter
  Future<void> updateTimeSpent(HomeworkItem item, int additionalSeconds) async {
    final total = item.timeSpentSeconds + additionalSeconds;
    final updated = item.copyWith(
      timeSpentSeconds: total,
      isPendingSync: true,
    );

    state = state.map((h) => h.id == item.id ? updated : h).toList();
    await HiveBoxes.saveHomeworkItem(updated);

    await _syncQueue.enqueue(
      SyncAction(
        id: const Uuid().v4(),
        actionType: 'UPDATE_HOMEWORK',
        endpoint: '/api/v1/homework/${item.id}',
        httpMethod: 'PATCH',
        payload: {'time_spent_seconds': total},
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Delete homework offline-first
  Future<void> deleteHomework(String id) async {
    state = state.where((h) => h.id != id).toList();
    await HiveBoxes.deleteHomeworkItem(id);

    await _syncQueue.enqueue(
      SyncAction(
        id: const Uuid().v4(),
        actionType: 'DELETE_HOMEWORK',
        endpoint: '/api/v1/homework/$id',
        httpMethod: 'DELETE',
        payload: {},
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}

final homeworkListProvider =
    StateNotifierProvider<HomeworkNotifier, List<HomeworkItem>>((ref) {
  final api = ref.watch(apiClientProvider);
  final queue = ref.read(syncQueueProvider);
  return HomeworkNotifier(api, queue);
});
