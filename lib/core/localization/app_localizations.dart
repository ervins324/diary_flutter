import 'package:flutter/material.dart';

/// In-app localization dictionary matching web app translations.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('uk'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'uk': {
      // Navigation
      'app_title': 'Шкільний Щоденник',
      'nav_schedule': 'Розклад',
      'nav_homework': 'Д/З',
      'nav_notes': 'Нотатки',
      'nav_stats': 'Статистика',
      'nav_settings': 'Налаштування',

      // Schedule & Daily
      'today': 'Сьогодні',
      'now': 'Зараз',
      'ongoing': 'Триває',
      'upcoming': 'Наступний',
      'no_lessons': 'Немає уроків',
      'no_lessons_scheduled': 'На цей день немає запланованих уроків',
      'numerator_week': 'Чисельник',
      'denominator_week': 'Знаменник',
      'week': 'Тиждень',
      'lesson': 'урок',
      'break_now': 'Перерва',
      'cab': 'каб.',
      'teacher': 'Вчитель',
      'consultation': 'Консультація',
      'cancelled': 'Скасовано',
      'control_work': 'Контрольна робота',
      'test': 'Самостійна робота',
      'essay': 'Твір / Есе',
      'project': 'Проєкт',

      // Days of week
      'mon': 'Пн',
      'tue': 'Вт',
      'wed': 'Ср',
      'thu': 'Чт',
      'fri': 'Пт',
      'sat': 'Сб',
      'sun': 'Нд',
      'monday': 'Понеділок',
      'tuesday': 'Вівторок',
      'wednesday': 'Середа',
      'thursday': 'Четвер',
      'friday': 'П\'ятниця',
      'saturday': 'Субота',
      'sunday': 'Неділя',

      // Homework
      'homework': 'Домашні завдання',
      'pending': 'До виконання',
      'completed': 'Виконано',
      'failed': 'Не здано',
      'all': 'Всі',
      'due_date': 'Термін здачі',
      'add_homework': 'Додати Д/З',
      'edit_homework': 'Редагувати Д/З',
      'time_spent': 'Витрачено часу',
      'minutes': 'хв',
      'seconds': 'сек',
      'attachments': 'Вкладення',
      'add_photo': 'Додати фото',
      'camera': 'Камера',
      'gallery': 'Галерея',
      'attach_file': 'Прикріпити файл',
      'no_homework': 'Немає домашніх завдань',

      // Notes
      'lesson_notes': 'Нотатки уроків',
      'add_note': 'Додати нотатку',
      'edit_note': 'Редагувати нотатку',
      'note_text': 'Текст нотатки',
      'search_notes': 'Пошук нотаток...',
      'no_notes': 'Немає нотаток для цього уроку',

      // Subjects & Bells
      'subjects': 'Предмети',
      'add_subject': 'Додати предмет',
      'subject_name': 'Назва предмета',
      'short_name': 'Скорочена назва',
      'color': 'Колір',
      'default_cabinet': 'Кабінет за замовчуванням',
      'bells': 'Розклад дзвінків',
      'add_bell': 'Додати дзвінок',
      'start_time': 'Початок',
      'end_time': 'Кінець',

      // Stats
      'statistics': 'Статистика',
      'weekly_overview': 'Огляд за тиждень',
      'study_time': 'Час навчання',
      'homework_rate': 'Виконання Д/З',
      'total_lessons': 'Всього уроків',

      // Server & Sync
      'server_connection': 'Підключення до сервера',
      'server_url': 'Адреса сервера (Docker)',
      'server_url_hint': 'наприклад http://192.168.1.100:8080',
      'test_connection': 'Перевірити з\'єднання',
      'connection_ok': 'З\'єднання успішне! Сервер доступний.',
      'connection_failed': 'Не вдалося підключитися до сервера.',
      'sync_status': 'Стан синхронізації',
      'sync_now': 'Синхронізувати зараз',
      'synced': 'Синхронізовано',
      'syncing': 'Синхронізація...',
      'offline_mode': 'Офлайн режим (локальна база)',
      'pending_sync': 'Очікують відправки на сервер',
      'save_and_continue': 'Зберегти та продовжити',

      // Air Raid Alerts
      'air_raid_alert': 'Повітряна тривога',
      'alert_active': 'Увага! Повітряна тривога у вашому регіоні!',
      'alert_calm': 'Повітряної тривоги немає',
      'select_region': 'Область для моніторингу тривог',

      // Common actions
      'save': 'Зберегти',
      'cancel': 'Скасувати',
      'delete': 'Видалити',
      'edit': 'Редагувати',
      'close': 'Закрити',
      'language': 'Мова інтерфейсу',
      'theme': 'Тема оформлення',
      'theme_dark': 'Темна',
      'theme_light': 'Світла',
      'theme_system': 'Системна',
    },
    'en': {
      // Navigation
      'app_title': 'School Diary',
      'nav_schedule': 'Schedule',
      'nav_homework': 'Homework',
      'nav_notes': 'Notes',
      'nav_stats': 'Stats',
      'nav_settings': 'Settings',

      // Schedule & Daily
      'today': 'Today',
      'now': 'Now',
      'ongoing': 'Ongoing',
      'upcoming': 'Upcoming',
      'no_lessons': 'No lessons',
      'no_lessons_scheduled': 'No lessons scheduled for this day',
      'numerator_week': 'Numerator',
      'denominator_week': 'Denominator',
      'week': 'Week',
      'lesson': 'lesson',
      'break_now': 'Break',
      'cab': 'Cab.',
      'teacher': 'Teacher',
      'consultation': 'Consultation',
      'cancelled': 'Cancelled',
      'control_work': 'Control Work',
      'test': 'Test',
      'essay': 'Essay',
      'project': 'Project',

      // Days of week
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',

      // Homework
      'homework': 'Homework',
      'pending': 'Pending',
      'completed': 'Completed',
      'failed': 'Failed',
      'all': 'All',
      'due_date': 'Due Date',
      'add_homework': 'Add Homework',
      'edit_homework': 'Edit Homework',
      'time_spent': 'Time Spent',
      'minutes': 'min',
      'seconds': 'sec',
      'attachments': 'Attachments',
      'add_photo': 'Add Photo',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'attach_file': 'Attach File',
      'no_homework': 'No homework assigned',

      // Notes
      'lesson_notes': 'Lesson Notes',
      'add_note': 'Add Note',
      'edit_note': 'Edit Note',
      'note_text': 'Note content',
      'search_notes': 'Search notes...',
      'no_notes': 'No notes for this lesson',

      // Subjects & Bells
      'subjects': 'Subjects',
      'add_subject': 'Add Subject',
      'subject_name': 'Subject Name',
      'short_name': 'Short Name',
      'color': 'Color',
      'default_cabinet': 'Default Cabinet',
      'bells': 'Bell Schedule',
      'add_bell': 'Add Bell',
      'start_time': 'Start Time',
      'end_time': 'End Time',

      // Stats
      'statistics': 'Statistics',
      'weekly_overview': 'Weekly Overview',
      'study_time': 'Study Time',
      'homework_rate': 'HW Completion',
      'total_lessons': 'Total Lessons',

      // Server & Sync
      'server_connection': 'Server Connection',
      'server_url': 'Server Address (Docker)',
      'server_url_hint': 'e.g. http://192.168.1.100:8080',
      'test_connection': 'Test Connection',
      'connection_ok': 'Connected successfully! Server is healthy.',
      'connection_failed': 'Could not connect to server.',
      'sync_status': 'Sync Status',
      'sync_now': 'Sync Now',
      'synced': 'Synced',
      'syncing': 'Syncing...',
      'offline_mode': 'Offline Mode (Local Cache)',
      'pending_sync': 'Pending Sync Queue',
      'save_and_continue': 'Save & Continue',

      // Air Raid Alerts
      'air_raid_alert': 'Air Raid Alert',
      'alert_active': 'Warning! Air raid alert in your region!',
      'alert_calm': 'No active air raid alert',
      'select_region': 'Region for Alert Monitoring',

      // Common actions
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'language': 'Language',
      'theme': 'Theme',
      'theme_dark': 'Dark',
      'theme_light': 'Light',
      'theme_system': 'System',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['uk', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
