import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../database/hive_boxes.dart';
import '../../models/subject_model.dart';
import '../../models/bell_slot_model.dart';
import '../../models/homework_model.dart';
import '../../models/lesson_note_model.dart';
import '../../models/schedule_model.dart';
import '../../models/holiday_model.dart';

/// Centralized HTTP client managing communication with the Diary FastAPI backend.
/// Supports automatic failover to Tailscale Tailnet IP when primary LAN server fails.
class ApiClient {
  late Dio _dio;
  String _mainBaseUrl = '';
  String _tailscaleBaseUrl = '';
  String _activeBaseUrl = '';
  bool _isTailscaleActive = false;
  String? lastHealthCheckError;
  String? lastTailscaleCheckError;

  ApiClient([Dio? customDio]) {
    if (customDio != null) {
      _dio = customDio;
      _activeBaseUrl = customDio.options.baseUrl;
      _mainBaseUrl = _activeBaseUrl;
    } else {
      _initDio();
    }
  }

  /// Cleans and formats raw server URLs.
  static String normalizeUrl(String raw) {
    var formatted = raw.trim();
    if (formatted.isNotEmpty &&
        !formatted.startsWith('http://') &&
        !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  void _initDio() {
    _mainBaseUrl = normalizeUrl(HiveBoxes.getServerUrl());
    _tailscaleBaseUrl = normalizeUrl(HiveBoxes.getTailscaleUrl());

    final savedActive = normalizeUrl(HiveBoxes.getActiveServerUrl());
    if (savedActive.isNotEmpty &&
        savedActive == _tailscaleBaseUrl &&
        _tailscaleBaseUrl.isNotEmpty) {
      _activeBaseUrl = _tailscaleBaseUrl;
      _isTailscaleActive = true;
    } else {
      _activeBaseUrl = _mainBaseUrl.isNotEmpty
          ? _mainBaseUrl
          : AppConfig.defaultServerUrl;
      _isTailscaleActive = false;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: _activeBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Failover interceptor: automatically retries with Tailscale IP if main server fails mid-flight
    _dio.interceptors.add(_buildFailoverInterceptor());
  }

  InterceptorsWrapper _buildFailoverInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException err, ErrorInterceptorHandler handler) async {
        final isConnectionIssue =
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError;

        if (isConnectionIssue &&
            _tailscaleBaseUrl.isNotEmpty &&
            !_isTailscaleActive) {
          // Switch to Tailscale fallback
          _switchToUrl(_tailscaleBaseUrl, isTailscale: true);

          try {
            final opts = Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
              contentType: err.requestOptions.contentType,
              responseType: err.requestOptions.responseType,
              validateStatus: err.requestOptions.validateStatus,
            );

            var path = err.requestOptions.path;
            if (path.startsWith(_mainBaseUrl)) {
              path = path.substring(_mainBaseUrl.length);
            }

            final retryResponse = await _dio.request(
              path,
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
              options: opts,
            );
            return handler.resolve(retryResponse);
          } catch (retryErr) {
            if (retryErr is DioException) {
              return handler.next(retryErr);
            }
          }
        }
        return handler.next(err);
      },
    );
  }

  void _switchToUrl(String targetUrl, {required bool isTailscale}) {
    _activeBaseUrl = targetUrl;
    _isTailscaleActive = isTailscale;
    _dio.options.baseUrl = targetUrl;
    HiveBoxes.setActiveServerUrl(targetUrl);
  }

  /// Reconfigure URLs when user updates settings.
  void updateUrls({String? mainUrl, String? tailscaleUrl}) {
    if (mainUrl != null) {
      _mainBaseUrl = normalizeUrl(mainUrl);
      HiveBoxes.setServerUrl(_mainBaseUrl);
    }
    if (tailscaleUrl != null) {
      _tailscaleBaseUrl = normalizeUrl(tailscaleUrl);
      HiveBoxes.setTailscaleUrl(_tailscaleBaseUrl);
    }
    // Prefer main URL upon explicit reconfiguration
    _switchToUrl(_mainBaseUrl, isTailscale: false);
  }

  /// Reconfigure Dio when user changes main server URL in Settings.
  void updateBaseUrl(String newUrl) {
    updateUrls(mainUrl: newUrl);
  }

  /// Reconfigure Tailscale fallback URL in Settings.
  void updateTailscaleUrl(String newUrl) {
    updateUrls(tailscaleUrl: newUrl);
  }

  String get currentBaseUrl => _activeBaseUrl;
  String get activeBaseUrl => _activeBaseUrl;
  String get mainBaseUrl => _mainBaseUrl;
  String get tailscaleBaseUrl => _tailscaleBaseUrl;
  bool get isTailscaleActive =>
      _isTailscaleActive && _tailscaleBaseUrl.isNotEmpty;

  /// Formats DioException into human-friendly explanation
  String _formatDioError(dynamic e, [String? url]) {
    final effectiveUrl = url ?? _activeBaseUrl;
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout to $effectiveUrl (Check Wi-Fi / IP)';
        case DioExceptionType.sendTimeout:
          return 'Send timeout to $effectiveUrl';
        case DioExceptionType.receiveTimeout:
          return 'Receive timeout from $effectiveUrl';
        case DioExceptionType.badResponse:
          return 'HTTP ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Bad response'}';
        case DioExceptionType.connectionError:
          final detail = e.error != null ? ' [${e.error}]' : '';
          final isLocalhost =
              effectiveUrl.contains('localhost') ||
              effectiveUrl.contains('127.0.0.1');
          final localhostHint = isLocalhost
              ? ' (On mobile use PC LAN IP, not localhost)'
              : '';
          return 'Cannot connect to $effectiveUrl$detail$localhostHint';
        case DioExceptionType.cancel:
          return 'Request cancelled';
        default:
          return e.message ?? e.toString();
      }
    }
    return e.toString();
  }

  /// Fast probe helper targeting a specific server URL
  Future<bool> _probeServer(String targetUrl) async {
    if (targetUrl.isEmpty) return false;
    try {
      final probeDio = Dio(
        BaseOptions(
          baseUrl: targetUrl,
          connectTimeout: AppConfig.fastHealthCheckTimeout,
          receiveTimeout: AppConfig.fastHealthCheckTimeout,
        ),
      );
      final res = await probeDio.get(
        '${AppConfig.apiPrefix}/subjects',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 400) {
        return true;
      }
    } catch (e) {
      lastHealthCheckError = _formatDioError(e, targetUrl);
    }

    try {
      final probeDio = Dio(
        BaseOptions(
          baseUrl: targetUrl,
          connectTimeout: AppConfig.fastHealthCheckTimeout,
          receiveTimeout: AppConfig.fastHealthCheckTimeout,
        ),
      );
      final res = await probeDio.get(
        '/',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 400) {
        lastHealthCheckError = null;
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Explicitly check primary LAN server health
  Future<bool> checkMainHealth() async {
    return await _probeServer(_mainBaseUrl);
  }

  /// Explicitly check Tailscale fallback server health
  Future<bool> checkTailscaleHealth() async {
    lastTailscaleCheckError = null;
    if (_tailscaleBaseUrl.isEmpty) {
      lastTailscaleCheckError = 'Tailscale URL not configured';
      return false;
    }
    final ok = await _probeServer(_tailscaleBaseUrl);
    if (!ok && lastHealthCheckError != null) {
      lastTailscaleCheckError = lastHealthCheckError;
    }
    return ok;
  }

  /// Intelligent dual health check:
  /// 1. Tries primary main server.
  /// 2. If main fails, seamlessly falls back to Tailscale Tailnet IP if configured.
  Future<bool> checkHealth() async {
    lastHealthCheckError = null;
    lastTailscaleCheckError = null;

    // 1. Probe primary main server
    final mainSuccess = await _probeServer(_mainBaseUrl);
    if (mainSuccess) {
      _switchToUrl(_mainBaseUrl, isTailscale: false);
      return true;
    }

    final mainErr =
        lastHealthCheckError ?? 'Main server unreachable ($_mainBaseUrl)';

    // 2. If primary failed, attempt Tailscale Tailnet fallback
    if (_tailscaleBaseUrl.isNotEmpty && _tailscaleBaseUrl != _mainBaseUrl) {
      final tailscaleSuccess = await _probeServer(_tailscaleBaseUrl);
      if (tailscaleSuccess) {
        _switchToUrl(_tailscaleBaseUrl, isTailscale: true);
        lastHealthCheckError = null;
        return true;
      }
      lastHealthCheckError =
          '$mainErr\nFallback: ${lastHealthCheckError ?? "Tailscale unreachable"}';
      return false;
    }

    lastHealthCheckError = mainErr;
    return false;
  }

  // ── Schedule ──────────────────────────────────────────────────
  Future<List<DaySchedule>> getScheduleRange(
    String startDate,
    String endDate,
  ) async {
    final response = await _dio.get(
      '${AppConfig.apiPrefix}/schedule',
      queryParameters: {'start_date': startDate, 'end_date': endDate},
    );
    if (response.data is List) {
      return (response.data as List)
          .map((d) => DaySchedule.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();
    }
    return [];
  }

  // ── Homework ──────────────────────────────────────────────────
  Future<List<HomeworkItem>> getHomeworkList({
    String? status,
    String? date,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (date != null) params['date'] = date;

    final response = await _dio.get(
      '${AppConfig.apiPrefix}/homework',
      queryParameters: params,
    );
    if (response.data is List) {
      return (response.data as List)
          .map(
            (h) => HomeworkItem.fromJson(Map<String, dynamic>.from(h as Map)),
          )
          .toList();
    }
    return [];
  }

  Future<HomeworkItem> createHomework(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${AppConfig.apiPrefix}/homework',
      data: data,
    );
    return HomeworkItem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<HomeworkItem> updateHomework(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '${AppConfig.apiPrefix}/homework/$id',
      data: data,
    );
    return HomeworkItem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteHomework(String id) async {
    await _dio.delete('${AppConfig.apiPrefix}/homework/$id');
  }

  // ── Subjects ──────────────────────────────────────────────────
  Future<List<SubjectModel>> getSubjects() async {
    final response = await _dio.get('${AppConfig.apiPrefix}/subjects');
    if (response.data is List) {
      return (response.data as List)
          .map(
            (s) => SubjectModel.fromJson(Map<String, dynamic>.from(s as Map)),
          )
          .toList();
    }
    return [];
  }

  Future<SubjectModel> createSubject(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${AppConfig.apiPrefix}/subjects',
      data: data,
    );
    return SubjectModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SubjectModel> updateSubject(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '${AppConfig.apiPrefix}/subjects/$id',
      data: data,
    );
    return SubjectModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteSubject(String id) async {
    await _dio.delete('${AppConfig.apiPrefix}/subjects/$id');
  }

  // ── Bells ─────────────────────────────────────────────────────
  Future<List<BellSlotModel>> getBells() async {
    final response = await _dio.get('${AppConfig.apiPrefix}/bells');
    if (response.data is List) {
      return (response.data as List)
          .map(
            (b) => BellSlotModel.fromJson(Map<String, dynamic>.from(b as Map)),
          )
          .toList();
    }
    return [];
  }

  Future<List<BellSlotModel>> saveBellsBulk(
    List<Map<String, dynamic>> slots,
  ) async {
    final response = await _dio.post(
      '${AppConfig.apiPrefix}/bells/bulk',
      data: {'slots': slots},
    );
    if (response.data is List) {
      return (response.data as List)
          .map(
            (b) => BellSlotModel.fromJson(Map<String, dynamic>.from(b as Map)),
          )
          .toList();
    }
    return [];
  }

  // ── Lesson Notes ──────────────────────────────────────────────
  Future<List<LessonNoteModel>> getLessonNotes({
    String? date,
    String? subjectId,
  }) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    if (subjectId != null) params['subject_id'] = subjectId;

    final response = await _dio.get(
      '${AppConfig.apiPrefix}/lesson-notes',
      queryParameters: params,
    );
    if (response.data is List) {
      return (response.data as List)
          .map(
            (n) =>
                LessonNoteModel.fromJson(Map<String, dynamic>.from(n as Map)),
          )
          .toList();
    }
    return [];
  }

  Future<LessonNoteModel> createLessonNote(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${AppConfig.apiPrefix}/lesson-notes',
      data: data,
    );
    return LessonNoteModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<LessonNoteModel> updateLessonNote(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '${AppConfig.apiPrefix}/lesson-notes/$id',
      data: data,
    );
    return LessonNoteModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteLessonNote(String id) async {
    await _dio.delete('${AppConfig.apiPrefix}/lesson-notes/$id');
  }

  // ── Holidays ──────────────────────────────────────────────────
  Future<List<HolidayModel>> getHolidays() async {
    final response = await _dio.get('${AppConfig.apiPrefix}/holidays');
    if (response.data is List) {
      return (response.data as List)
          .map(
            (h) => HolidayModel.fromJson(Map<String, dynamic>.from(h as Map)),
          )
          .toList();
    }
    return [];
  }

  // ── Statistics ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getWeeklyStats(
    String dateStr, {
    String mode = 'actual',
  }) async {
    final response = await _dio.get(
      '${AppConfig.apiPrefix}/stats/weekly',
      queryParameters: {'date': dateStr, 'mode': mode},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ── File Upload (Staged Attachments) ───────────────────────────
  Future<Map<String, dynamic>> uploadFile(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _dio.post(
      '${AppConfig.apiPrefix}/files/upload',
      data: formData,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ── Generic Request for Sync Queue ─────────────────────────────
  Future<Response> executeRaw(
    String method,
    String endpoint,
    dynamic data,
  ) async {
    var effectiveMethod = method.toUpperCase();
    if (effectiveMethod == 'PUT' &&
        (endpoint.contains('/homework') ||
            endpoint.contains('/lesson-notes') ||
            endpoint.contains('/subjects'))) {
      effectiveMethod = 'PATCH';
    }

    return await _dio.request(
      endpoint,
      data: data,
      options: Options(
        method: effectiveMethod,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
