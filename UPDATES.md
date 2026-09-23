# Updates Log

## [1.0.0] - 2026-09-23
### Added
- **Liquid Glass UI System (`liquid_glass_easy: 4.3.1`)**:
  - Ambient moving gradient mesh background (`AmbientBackground`) providing rich colors for shader refraction.
  - `LiquidGlassView` backdrop capture with frosted liquid glass cards and pills.
  - Floating liquid glass bottom navigation bar and adaptive headers.
- **Server Connection & Dynamic Setup**:
  - Configurable server address (e.g. `http://192.168.1.100:8080`) connecting to the FastAPI backend running in Docker.
  - `ServerSetupScreen` with real-time ping health check and latency status.
- **Offline-First Architecture & Sync Queue**:
  - Local high-performance NoSQL database powered by `hive_flutter`.
  - Background `SyncQueueManager` that records offline edits and flushes pending mutations when connectivity is restored.
  - Staged local photo and document attachments (`image_picker` / `file_picker` + `path_provider`), uploaded to `/api/v1/files/upload` upon sync.
- **Full Feature Parity with Web App**:
  - **Schedule Screen**: Numerator and Denominator week switcher, date navigator, live lesson progress bar and countdown timer widget (`LiveLessonWidget`), lesson slot cards with academic event tags (`control_work`, `test`, `essay`, `project`), teacher, room, and consultation indicators.
  - **Lesson Detail Sheet**: Tap any lesson to view or add homework and lesson notes.
  - **Homework Tracker**: Status filters (Pending, Completed, Failed, All), study stopwatch timer, completion checkboxes, and offline attachment previews.
  - **Lesson Notes Screen**: Searchable notes grouped by subject and date with photo staging.
  - **Statistics Dashboard**: Weekly analytics on lesson totals, study time counters, homework completion rates, and subject distribution meters.
  - **Subjects & Bells Management**: Manage subject colors, names, default classrooms, and school bell intervals.
  - **Neptun Air Raid Alerts**: Live warning banner connected to `wss://neptun.in.ua/api/v1/stream` with HTTP fallback and Ukrainian region selection.
  - **Bilingual Localization**: Seamless runtime switching between Ukrainian (`uk`, default) and English (`en`).
