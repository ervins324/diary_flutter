import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/app_config.dart';
import '../core/database/hive_boxes.dart';

class AirRaidAlertState {
  final bool isAlertActive;
  final String activeRegion;
  final DateTime? lastChecked;
  final bool isConnected;

  const AirRaidAlertState({
    this.isAlertActive = false,
    required this.activeRegion,
    this.lastChecked,
    this.isConnected = false,
  });

  AirRaidAlertState copyWith({
    bool? isAlertActive,
    String? activeRegion,
    DateTime? lastChecked,
    bool? isConnected,
  }) {
    return AirRaidAlertState(
      isAlertActive: isAlertActive ?? this.isAlertActive,
      activeRegion: activeRegion ?? this.activeRegion,
      lastChecked: lastChecked ?? this.lastChecked,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class AirRaidAlertNotifier extends StateNotifier<AirRaidAlertState> {
  WebSocketChannel? _channel;
  Timer? _pollingTimer;
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  AirRaidAlertNotifier()
      : super(AirRaidAlertState(activeRegion: HiveBoxes.getAlertRegion())) {
    _startMonitoring();
  }

  void updateRegion(String newRegion) {
    HiveBoxes.setAlertRegion(newRegion);
    state = state.copyWith(activeRegion: newRegion);
    checkHttpFallback();
  }

  void _startMonitoring() {
    _connectWebSocket();
    // Also poll every 30 seconds as reliable fallback
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkHttpFallback();
    });
    checkHttpFallback();
  }

  void _connectWebSocket() {
    try {
      final uri = Uri.parse(AppConfig.neptunWsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel?.stream.listen(
        (data) {
          _processAlertData(data);
        },
        onError: (_) {
          state = state.copyWith(isConnected: false);
          _reconnectWsDelayed();
        },
        onDone: () {
          state = state.copyWith(isConnected: false);
          _reconnectWsDelayed();
        },
      );
      state = state.copyWith(isConnected: true);
    } catch (_) {
      state = state.copyWith(isConnected: false);
      _reconnectWsDelayed();
    }
  }

  void _reconnectWsDelayed() {
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        _connectWebSocket();
      }
    });
  }

  Future<void> checkHttpFallback() async {
    try {
      final res = await _dio.get(AppConfig.neptunHttpUrl);
      if (res.data != null) {
        _processAlertData(res.data);
      }
    } catch (_) {}
  }

  void _processAlertData(dynamic data) {
    try {
      dynamic parsed = data;
      if (data is String) {
        parsed = jsonDecode(data);
      }

      bool hasAlert = false;
      final region = state.activeRegion.toLowerCase();

      if (parsed is List) {
        for (final item in parsed) {
          final itemRegion = (item['region'] ?? item['name'] ?? item['location_title'] ?? '')
              .toString()
              .toLowerCase();
          final isActive = item['is_alert'] == true ||
              item['status'] == 'active' ||
              item['alert'] == true;

          if (itemRegion.contains(region) || region.contains(itemRegion)) {
            if (isActive) {
              hasAlert = true;
              break;
            }
          }
        }
      } else if (parsed is Map) {
        final alerts = parsed['alerts'] ?? parsed['data'];
        if (alerts is List) {
          for (final item in alerts) {
            final itemRegion = (item['region'] ?? item['location_title'] ?? '')
                .toString()
                .toLowerCase();
            if (itemRegion.contains(region) || region.contains(itemRegion)) {
              hasAlert = true;
              break;
            }
          }
        }
      }

      state = state.copyWith(
        isAlertActive: hasAlert,
        lastChecked: DateTime.now(),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final airRaidAlertProvider =
    StateNotifierProvider<AirRaidAlertNotifier, AirRaidAlertState>((ref) {
  return AirRaidAlertNotifier();
});
