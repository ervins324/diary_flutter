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
  final Ref _ref;

  ServerConnectionNotifier(this._apiClient, this._ref)
    : super(ConnectionStatus.unknown) {
    checkConnection();
  }

  Future<bool> checkConnection() async {
    state = ConnectionStatus.checking;
    final ok = await _apiClient.checkHealth();
    state = ok ? ConnectionStatus.connected : ConnectionStatus.offline;
    _ref.read(activeServerUrlProvider.notifier).state =
        _apiClient.activeBaseUrl;
    _ref.read(isTailscaleActiveProvider.notifier).state =
        _apiClient.isTailscaleActive;
    return ok;
  }

  void updateServerUrl(String newUrl) {
    _apiClient.updateBaseUrl(newUrl);
    _ref.read(serverUrlProvider.notifier).state = _apiClient.mainBaseUrl;
    checkConnection();
  }

  void updateUrls({String? mainUrl, String? tailscaleUrl}) {
    _apiClient.updateUrls(mainUrl: mainUrl, tailscaleUrl: tailscaleUrl);
    if (mainUrl != null) {
      _ref.read(serverUrlProvider.notifier).state = _apiClient.mainBaseUrl;
    }
    if (tailscaleUrl != null) {
      _ref.read(tailscaleUrlProvider.notifier).state =
          _apiClient.tailscaleBaseUrl;
    }
    checkConnection();
  }
}

final serverConnectionProvider =
    StateNotifierProvider<ServerConnectionNotifier, ConnectionStatus>((ref) {
      final api = ref.watch(apiClientProvider);
      return ServerConnectionNotifier(api, ref);
    });

/// Current configured primary server URL provider
final serverUrlProvider = StateProvider<String>((ref) {
  return HiveBoxes.getServerUrl();
});

/// Current configured Tailscale fallback URL provider
final tailscaleUrlProvider = StateProvider<String>((ref) {
  return HiveBoxes.getTailscaleUrl();
});

/// Dynamically active server URL (switches between primary and Tailscale fallback)
final activeServerUrlProvider = StateProvider<String>((ref) {
  return HiveBoxes.getActiveServerUrl();
});

/// Indicator whether Tailscale fallback channel is currently active
final isTailscaleActiveProvider = StateProvider<bool>((ref) {
  final api = ref.watch(apiClientProvider);
  return api.isTailscaleActive;
});
