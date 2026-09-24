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
class ApiClient {
  late Dio _dio;
  String _currentBaseUrl = '';
  String? lastHealthCheckError;

  ApiClient([Dio? customDio]) {
    if (customDio != null) {
      _dio = customDio;
      _currentBaseUrl = customDio.options.baseUrl;
    } else {
      _initDio();
    }
  }

  void _initDio() {
    _currentBaseUrl = HiveBoxes.getServerUrl();
    _dio = Dio(
      BaseOptions(
        baseUrl: _currentBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Reconfigure Dio when user changes server URL in Settings.
  void updateBaseUrl(String newUrl) {
    var formatted = newUrl.trim();
    if (formatted.isNotEmpty && !formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    _currentBaseUrl = formatted;
    HiveBoxes.setServerUrl(formatted);
    _initDio();
  }

  String get currentBaseUrl => _currentBaseUrl;

  /// Formats DioException into human-friendly explanation
  String _formatDioError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout to $_currentBaseUrl (Check Wi-Fi / IP)';
        case DioExceptionType.sendTimeout:
          return 'Send timeout to $_currentBaseUrl';
        case DioExceptionType.receiveTimeout:
          return 'Receive timeout from $_currentBaseUrl';
        case DioExceptionType.badResponse:
          return 'HTTP ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Bad response'}';
        case DioExceptionType.connectionError:
          return 'Cannot connect to $_currentBaseUrl (Check Docker port 8080 & LAN IP)';
        case DioExceptionType.cancel:
          return 'Request cancelled';
        default:
          return e.message ?? e.toString();
      }
    }
    return e.toString();
  }

  /// Fast health check to test if server is reachable.
  Future<bool> checkHealth() async {
    lastHealthCheckError = null;
    try {
      final res = await _dio.get(
        '${AppConfig.apiPrefix}/subjects',
        options: Options(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 400) {
        return true;
      }
      lastHealthCheckError = 'Server returned HTTP ${res.statusCode}';
    } catch (e) {
      lastHealthCheckError = _formatDioError(e);
    }

    try {
      final res = await _dio.get(
        '/',
        options: Options(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 400) {
        lastHealthCheckError = null;
        return true;
      }
    } catch (_) {}

    return false;
  }

  // ── Schedule ──────────────────────────────────────────────────
  Future<List<DaySchedule>> getScheduleRange(String startDate, String endDate) async {
    final response = await _dio.get(
      '${AppConfig.apiPrefix}/schedule',
      queryParameters: {
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    if (response.data is List) {
      return (response.data as List)
          .map((d) => DaySchedule.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();
    }
    return [];
  }

  // ── Homework ──────────────────────────────────────────────────
  Future<List<HomeworkItem>> getHomeworkList({String? status, String? date}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (date != null) params['date'] = date;

    final response = await _dio.get(
      '${AppConfig.apiPrefix}/homework',
      queryParameters: params,
    );
    if (response.data is List) {
      return (response.data as List)
          .map((h) => HomeworkItem.fromJson(Map<String, dynamic>.from(h as Map)))
          .toList();
    }
    return [];
  }

  Future<HomeworkItem> createHomework(Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConfig.apiPrefix}/homework', data: data);
    return HomeworkItem.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<HomeworkItem> updateHomework(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('${AppConfig.apiPrefix}/homework/$id', data: data);
    return HomeworkItem.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteHomework(String id) async {
    await _dio.delete('${AppConfig.apiPrefix}/homework/$id');
  }

  // ── Subjects ──────────────────────────────────────────────────
  Future<List<SubjectModel>> getSubjects() async {
    final response = await _dio.get('${AppConfig.apiPrefix}/subjects');
    if (response.data is List) {
      return (response.data as List)
          .map((s) => SubjectModel.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    }
    return [];
  }

  Future<SubjectModel> createSubject(Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConfig.apiPrefix}/subjects', data: data);
    return SubjectModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<SubjectModel> updateSubject(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('${AppConfig.apiPrefix}/subjects/$id', data: data);
    return SubjectModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteSubject(String id) async {
    await _dio.delete('${AppConfig.apiPrefix}/subjects/$id');
  }

  // ── Bells ─────────────────────────────────────────────────────
  Future<List<BellSlotModel>> getBells() async {
    final response = await _dio.get('${AppConfig.apiPrefix}/bells');
    if (response.data is List) {
      return (response.data as List)
          .map((b) => BellSlotModel.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList();
    }
    return [];
  }

  Future<List<BellSlotModel>> saveBellsBulk(List<Map<String, dynamic>> slots) async {
    final response = await _dio.post(
      '${AppConfig.apiPrefix}/bells/bulk',
      data: {'slots': slots},
    );
    if (response.data is List) {
      return (response.data as List)
          .map((b) => BellSlotModel.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList();
    }
    return [];
  }

  // ── Lesson Notes ──────────────────────────────────────────────
  Future<List<LessonNoteModel>> getLessonNotes({String? date, String? subjectId}) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    if (subjectId != null) params['subject_id'] = subjectId;

    final response = await _dio.get(
      '${AppConfig.apiPrefix}/lesson-notes',
      queryParameters: params,
    );
    if (response.data is List) {
      return (response.data as List)
          .map((n) => LessonNoteModel.fromJson(Map<String, dynamic>.from(n as Map)))
          .toList();
    }
    return [];
  }

  Future<LessonNoteModel> createLessonNote(Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConfig.apiPrefix}/lesson-notes', data: data);
    return LessonNoteModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<LessonNoteModel> updateLessonNote(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('${AppConfig.apiPrefix}/lesson-notes/$id', data: data);
    return LessonNoteModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteLessonNote(String id) async {
    await _dio.delete('${AppConfig.apiPrefix}/lesson-notes/$id');
  }

  // ── Holidays ──────────────────────────────────────────────────
  Future<List<HolidayModel>> getHolidays() async {
    final response = await _dio.get('${AppConfig.apiPrefix}/holidays');
    if (response.data is List) {
      return (response.data as List)
          .map((h) => HolidayModel.fromJson(Map<String, dynamic>.from(h as Map)))
          .toList();
    }
    return [];
  }

  // ── Statistics ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getWeeklyStats(String dateStr, {String mode = 'actual'}) async {
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
  Future<Response> executeRaw(String method, String endpoint, dynamic data) async {
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
