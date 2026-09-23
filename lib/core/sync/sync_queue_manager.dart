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

  SyncQueueManager(this._apiClient) {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        processQueue();
      }
    });
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
        _state = _state.copyWith(isSyncing: false, lastError: 'Server unreachable');
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
          } else {
            // Server responded with an error (e.g. 400/500)
            if (action.retryCount >= 5) {
              // Discard after 5 retries to avoid poisoning the queue
              await HiveBoxes.removeSyncAction(action.id);
            } else {
              await HiveBoxes.enqueueSyncAction(
                action.copyWith(retryCount: action.retryCount + 1),
              );
            }
          }
        } catch (e) {
          // Network interruption mid-queue: break and retry on next trigger
          _state = _state.copyWith(lastError: e.toString());
          break;
        }
      }

      _state = _state.copyWith(
        isSyncing: false,
        pendingCount: HiveBoxes.getPendingSyncCount(),
        lastSyncTime: DateTime.now(),
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
