import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/database/hive_boxes.dart';
import '../core/sync/sync_queue_manager.dart';

/// Global single instance of ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Global SyncQueueManager instance managing offline modifications
final syncQueueProvider = ChangeNotifierProvider<SyncQueueManager>((ref) {
  final api = ref.watch(apiClientProvider);
  return SyncQueueManager(api);
});

/// Server connection status state
enum ConnectionStatus { unknown, connected, offline, checking }

class ServerConnectionNotifier extends StateNotifier<ConnectionStatus> {
  final ApiClient _apiClient;

  ServerConnectionNotifier(this._apiClient) : super(ConnectionStatus.unknown) {
    checkConnection();
  }

  Future<bool> checkConnection() async {
    state = ConnectionStatus.checking;
    final ok = await _apiClient.checkHealth();
    state = ok ? ConnectionStatus.connected : ConnectionStatus.offline;
    return ok;
  }

  void updateServerUrl(String newUrl) {
    _apiClient.updateBaseUrl(newUrl);
    checkConnection();
  }
}

final serverConnectionProvider =
    StateNotifierProvider<ServerConnectionNotifier, ConnectionStatus>((ref) {
  final api = ref.watch(apiClientProvider);
  return ServerConnectionNotifier(api);
});

/// Current configured server URL provider
final serverUrlProvider = StateProvider<String>((ref) {
  return HiveBoxes.getServerUrl();
});
