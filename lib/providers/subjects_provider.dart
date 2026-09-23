import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/database/hive_boxes.dart';
import '../models/subject_model.dart';
import 'api_client_provider.dart';

class SubjectsNotifier extends StateNotifier<List<SubjectModel>> {
  final ApiClient _apiClient;

  SubjectsNotifier(this._apiClient) : super([]) {
    loadCached();
    fetchRemote();
  }

  void loadCached() {
    state = HiveBoxes.getSubjects();
  }

  Future<void> fetchRemote() async {
    try {
      final remote = await _apiClient.getSubjects();
      if (remote.isNotEmpty) {
        await HiveBoxes.saveSubjects(remote);
        state = remote;
      }
    } catch (_) {
      // Offline fallback
    }
  }

  Future<void> addSubject(SubjectModel subject) async {
    state = [...state, subject];
    await HiveBoxes.saveSubject(subject);
    try {
      final created = await _apiClient.createSubject(subject.toJson());
      state = state.map((s) => s.id == subject.id ? created : s).toList();
      await HiveBoxes.saveSubject(created);
    } catch (_) {}
  }

  Future<void> updateSubject(SubjectModel subject) async {
    state = state.map((s) => s.id == subject.id ? subject : s).toList();
    await HiveBoxes.saveSubject(subject);
    try {
      await _apiClient.updateSubject(subject.id, subject.toJson());
    } catch (_) {}
  }

  Future<void> deleteSubject(String id) async {
    state = state.where((s) => s.id != id).toList();
    await HiveBoxes.deleteSubject(id);
    try {
      await _apiClient.deleteSubject(id);
    } catch (_) {}
  }
}

final subjectsProvider =
    StateNotifierProvider<SubjectsNotifier, List<SubjectModel>>((ref) {
  final api = ref.watch(apiClientProvider);
  return SubjectsNotifier(api);
});
