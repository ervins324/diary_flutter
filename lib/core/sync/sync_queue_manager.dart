import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../database/hive_boxes.dart';
import '../../models/sync_action_model.dart';

/// Sync status state for UI indicators.
class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? lastError;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.lastError,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? lastError,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
    );
  }
}

/// Offline-first queue processor that pushes local mutations to the server.
class SyncQueueManager extends ChangeNotifier {
  final ApiClient _apiClient;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  bool _isProcessing = false;
  SyncState _state = SyncState(pendingCount: HiveBoxes.getPendingSyncCount());

  SyncState get state => _state;

  SyncQueueManager(this._apiClient, [Connectivity? connectivity]) {
    _connectivitySub = (connectivity ?? Connectivity()).onConnectivityChanged.listen(
      (results) {
        final hasConnection = results.any((r) => r != ConnectivityResult.none);
        if (hasConnection) {
          processQueue();
        }
      },
      onError: (_) {
        // Silently ignore connectivity stream errors in test/unsupported environments
      },
    );
    // Check initial queue count
    _updatePendingCount();
  }

  void _updatePendingCount() {
    _state = _state.copyWith(pendingCount: HiveBoxes.getPendingSyncCount());
    notifyListeners();
  }

  /// Add a mutation to the queue and immediately attempt sync if online.
  Future<void> enqueue(SyncAction action) async {
    await HiveBoxes.enqueueSyncAction(action);
    _updatePendingCount();
    // Attempt processing in background
    processQueue();
  }

  /// Sequentially flushes all pending actions to the Docker server.
  Future<void> processQueue() async {
    if (_isProcessing) return;

    final queue = HiveBoxes.getSyncQueue();
    if (queue.isEmpty) {
      _updatePendingCount();
      return;
    }

    _isProcessing = true;
    _state = _state.copyWith(isSyncing: true, lastError: null);
    notifyListeners();

    try {
      // First verify backend is responsive
      final isHealthy = await _apiClient.checkHealth();
      if (!isHealthy) {
        _isProcessing = false;
        _state = _state.copyWith(
          isSyncing: false,
          lastError: _apiClient.lastHealthCheckError ??
              'Server unreachable (${_apiClient.currentBaseUrl})',
          pendingCount: HiveBoxes.getPendingSyncCount(),
        );
        notifyListeners();
        return;
      }

      for (final action in queue) {
        try {
          var payload = Map<String, dynamic>.from(action.payload);

          // 1. Upload any staged local attachments first
          if (action.localFilePaths.isNotEmpty) {
            final uploadedAttachments = <Map<String, dynamic>>[];
            for (final localPath in action.localFilePaths) {
              final file = File(localPath);
              if (await file.exists()) {
                final uploadResult = await _apiClient.uploadFile(file);
                uploadedAttachments.add({
                  'id': uploadResult['id'],
                  'name': uploadResult['filename'] ?? file.path.split(Platform.pathSeparator).last,
                  'type': (uploadResult['content_type'] ?? '').contains('image') ? 'image' : 'pdf',
                  'url': uploadResult['url'],
                  'size': uploadResult['size'],
                });
              }
            }

            if (uploadedAttachments.isNotEmpty) {
              final existingAtts = payload['attachments'];
              if (existingAtts is List) {
                payload['attachments'] = [...existingAtts, ...uploadedAttachments];
              } else {
                payload['attachments'] = uploadedAttachments;
              }
            }
          }

          // 2. Execute the queued mutation
          final res = await _apiClient.executeRaw(
            action.httpMethod,
            action.endpoint,
            payload,
          );

          if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
            // Success: remove action from queue
            await HiveBoxes.removeSyncAction(action.id);
          } else if (res.statusCode != null && res.statusCode! >= 400 && res.statusCode! < 500) {
            // Client error (400/404/422): drop poison pill to prevent permanently blocked queue
            debugPrint('Dropping invalid sync action ${action.id}: HTTP ${res.statusCode} ${res.data}');
            await HiveBoxes.removeSyncAction(action.id);
            _state = _state.copyWith(lastError: 'HTTP ${res.statusCode}: ${res.data ?? res.statusMessage}');
          } else {
            // Server error (500)
            if (action.retryCount >= 3) {
              await HiveBoxes.removeSyncAction(action.id);
            } else {
              await HiveBoxes.enqueueSyncAction(
                action.copyWith(retryCount: action.retryCount + 1),
              );
            }
            _state = _state.copyWith(lastError: 'Server error: HTTP ${res.statusCode}');
          }
        } catch (e) {
          // Network interruption mid-queue: break and retry on next trigger
          _state = _state.copyWith(lastError: 'Sync interrupted: $e');
          break;
        }
      }

      final remaining = HiveBoxes.getPendingSyncCount();
      _state = _state.copyWith(
        isSyncing: false,
        pendingCount: remaining,
        lastSyncTime: DateTime.now(),
        lastError: remaining == 0 ? null : _state.lastError,
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }
}
