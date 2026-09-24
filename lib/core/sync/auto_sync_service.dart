import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../database/hive_boxes.dart';
import 'sync_queue_manager.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/bells_provider.dart';
import '../../providers/homework_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/subjects_provider.dart';

/// State representation of the auto-synchronization engine.
class AutoSyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? lastError;
  final int pendingCount;
  final bool isAutoSyncEnabled;
  final int syncIntervalSeconds;
  final bool isOnline;

  const AutoSyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastError,
    this.pendingCount = 0,
    this.isAutoSyncEnabled = true,
    this.syncIntervalSeconds = 30,
    this.isOnline = true,
  });

  AutoSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? lastError,
    int? pendingCount,
    bool? isAutoSyncEnabled,
    int? syncIntervalSeconds,
    bool? isOnline,
  }) {
    return AutoSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      pendingCount: pendingCount ?? this.pendingCount,
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
      syncIntervalSeconds: syncIntervalSeconds ?? this.syncIntervalSeconds,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Centralized coordinator that automatically keeps mobile client state and Docker server in sync.
class AutoSyncService extends StateNotifier<AutoSyncState> {
  final Ref _ref;
  final ApiClient _apiClient;
  final SyncQueueManager _syncQueue;

  Timer? _periodicTimer;
  Timer? _initialTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  AppLifecycleListener? _lifecycleListener;
  bool _isDisposed = false;

  AutoSyncService(this._ref, this._apiClient, this._syncQueue)
      : super(AutoSyncState(
          isAutoSyncEnabled: HiveBoxes.getAutoSyncEnabled(),
          syncIntervalSeconds: HiveBoxes.getAutoSyncInterval(),
          lastSyncTime: HiveBoxes.getLastSyncTime(),
          pendingCount: HiveBoxes.getPendingSyncCount(),
        )) {
    _initAutoSync();
  }

  void _initAutoSync() {
    // 1. Listen for connectivity restoration
    try {
      _connectivitySub = Connectivity().onConnectivityChanged.listen(
        (results) {
          final hasConnection = results.any((r) => r != ConnectivityResult.none);
          state = state.copyWith(isOnline: hasConnection);
          if (hasConnection && state.isAutoSyncEnabled) {
            syncAll();
          }
        },
        onError: (_) {},
      );
    } catch (_) {}

    // 2. Listen for app returning to foreground
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (state.isAutoSyncEnabled) {
          syncAll();
        }
      },
    );

    // 3. Configure periodic timer
    _resetTimer();

    // 4. Trigger initial sync after slight delay to allow UI to mount smoothly
    _initialTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!_isDisposed && state.isAutoSyncEnabled) {
        syncAll();
      }
    });
  }

  void _resetTimer() {
    _periodicTimer?.cancel();
    if (state.isAutoSyncEnabled && state.syncIntervalSeconds > 0) {
      _periodicTimer = Timer.periodic(
        Duration(seconds: state.syncIntervalSeconds),
        (_) {
          if (!_isDisposed && !state.isSyncing) {
            syncAll();
          }
        },
      );
    }
  }

  /// Toggles automatic periodic background synchronization.
  Future<void> toggleAutoSync(bool enabled) async {
    await HiveBoxes.setAutoSyncEnabled(enabled);
    state = state.copyWith(isAutoSyncEnabled: enabled);
    _resetTimer();
  }

  /// Sets the sync interval frequency in seconds (e.g. 15, 30, 60, 300).
  Future<void> setSyncInterval(int seconds) async {
    await HiveBoxes.setAutoSyncInterval(seconds);
    state = state.copyWith(syncIntervalSeconds: seconds);
    _resetTimer();
  }

  /// Executes full bidirectional synchronization:
  /// 1. Flushes pending local mutations to the server.
  /// 2. Pulls latest schedule, homework, notes, subjects, bells, and stats.
  Future<bool> syncAll({bool isManual = false}) async {
    if (state.isSyncing || _isDisposed || !mounted) return false;

    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      // Step A: Fast health check
      final isHealthy = await _apiClient.checkHealth();
      if (!isHealthy) {
        if (_isDisposed || !mounted) return false;
        state = state.copyWith(
          isSyncing: false,
          isOnline: false,
          lastError: _apiClient.lastHealthCheckError ??
              'Server unreachable (${_apiClient.currentBaseUrl})',
          pendingCount: HiveBoxes.getPendingSyncCount(),
        );
        return false;
      }

      if (_isDisposed || !mounted) return false;
      state = state.copyWith(isOnline: true);

      // Step B: Push queued local changes to server first
      await _syncQueue.processQueue();

      // Step C: Pull latest remote data across all domains
      final syncTasks = <Future>[
        _ref.read(homeworkListProvider.notifier).fetchRemote(),
        _ref.read(notesListProvider.notifier).fetchRemote(),
        _ref.read(subjectsProvider.notifier).fetchRemote(),
        _ref.read(bellsProvider.notifier).fetchRemote(),
        _ref.read(scheduleProvider.notifier).refresh(_ref.read(selectedDateProvider)),
      ];

      await Future.wait(syncTasks);

      // Invalidate stats cache so stats screen receives fresh aggregates
      _ref.invalidate(weeklyStatsProvider);

      final now = DateTime.now();
      await HiveBoxes.setLastSyncTime(now);

      if (_isDisposed || !mounted) return false;
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: now,
        lastError: null,
        pendingCount: HiveBoxes.getPendingSyncCount(),
      );
      return true;
    } catch (e) {
      if (_isDisposed || !mounted) return false;
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
        pendingCount: HiveBoxes.getPendingSyncCount(),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _initialTimer?.cancel();
    _periodicTimer?.cancel();
    _connectivitySub?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }
}

/// Global provider for the auto-sync service.
final autoSyncProvider = StateNotifierProvider<AutoSyncService, AutoSyncState>((ref) {
  final api = ref.watch(apiClientProvider);
  final queue = ref.read(syncQueueProvider);
  return AutoSyncService(ref, api, queue);
});
