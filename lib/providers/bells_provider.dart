import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/database/hive_boxes.dart';
import '../models/bell_slot_model.dart';
import 'api_client_provider.dart';

class BellsNotifier extends StateNotifier<List<BellSlotModel>> {
  final ApiClient _apiClient;

  BellsNotifier(this._apiClient) : super([]) {
    loadCached();
    fetchRemote();
  }

  void loadCached() {
    state = HiveBoxes.getBells();
  }

  Future<void> fetchRemote() async {
    try {
      final remote = await _apiClient.getBells();
      if (remote.isNotEmpty) {
        await HiveBoxes.saveBells(remote);
        state = remote;
      }
    } catch (_) {
      // Offline fallback
    }
  }

  Future<void> saveBellsBulk(List<BellSlotModel> slots) async {
    state = slots;
    await HiveBoxes.saveBells(slots);
    try {
      final res = await _apiClient.saveBellsBulk(
        slots.map((s) => s.toJson()).toList(),
      );
      if (res.isNotEmpty) {
        state = res;
        await HiveBoxes.saveBells(res);
      }
    } catch (_) {}
  }
}

final bellsProvider =
    StateNotifierProvider<BellsNotifier, List<BellSlotModel>>((ref) {
  final api = ref.watch(apiClientProvider);
  return BellsNotifier(api);
});
