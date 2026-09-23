/// Central configuration constants for the Diary mobile application.
class AppConfig {
  static const String appName = 'School Diary';
  static const String appVersion = '1.0.0';

  // Default server base URL (Nginx reverse proxy on port 8080)
  static const String defaultServerUrl = 'http://192.168.1.100:8080';
  static const String apiPrefix = '/api/v1';

  // Network timeouts
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Hive Box Names
  static const String boxSettings = 'diary_settings';
  static const String boxSchedule = 'diary_schedule';
  static const String boxHomework = 'diary_homework';
  static const String boxNotes = 'diary_notes';
  static const String boxSubjects = 'diary_subjects';
  static const String boxBells = 'diary_bells';
  static const String boxHolidays = 'diary_holidays';
  static const String boxSyncQueue = 'diary_sync_queue';

  // Semester Anchor Date for Numerator / Denominator calculation
  static const String defaultAnchorDate = '2026-09-01';

  // Neptun Air Raid Alerts
  static const String neptunWsUrl = 'wss://neptun.in.ua/api/v1/stream';
  static const String neptunHttpUrl = 'https://neptun.in.ua/api/v1/alerts';
  static const String neptunAttribution =
      'Дані: Карта повітряних тривог — NEPTUN (neptun.in.ua)';
}
