# Updates Log

## [1.0.1] - 2026-09-23
### Fixed & Improved
- **Bottom Navigation Overflow**: Refactored `MainScaffold` bottom bar to use `Expanded` children with `FittedBox` label scaling and condensed padding to eliminate pixel overflow on small and narrow devices.
- **Settings Screen Layout**: Replaced tight horizontal selections in language, theme, and connection status with responsive vertical layouts to eliminate right pixel overflows.
- **Attachment Display & Interactive Lightbox Gallery**:
  - Implemented `AttachmentChipsView` supporting server-hosted `/api/v1/files/UUID` links, local files, and base64 images.
  - Implemented `LightboxGallery` with pinch-to-zoom (up to 4.5x), double-tap zoom toggle (1x <-> 2.5x), 2D pan physics, on-screen zoom controls (+, -, reset), swipe between multiple attachments, and external download/browser opening.
  - Added document chips for PDF, PPT/PPTX, Word, and text files with file type icons, size formatters, and tap-to-open via `url_launcher`.
- **Full-Stack Statistics Parity**:
  - Enhanced `StatsScreen` with schedule mode switcher (`Actual`, `Numerator`, `Denominator`).
  - Added metric switcher (`Hours / Minutes` vs `Lesson count`) and view switcher (`By Subjects` vs `By Days`).
  - Added detailed homework analytics with completion rates, time spent averages, and failed homework item callouts.
  - Added breaks and lesson cancellation analytics with reason breakdowns and air raid alert tags.
- **Schedule Offline Resilience**:
  - Automatically synthesizes fallback 7-day schedule if offline and cache is empty, avoiding raw `DioException` crashes.
  - Added friendly offline warning banner with quick navigation to `ServerSetupScreen` and instant retry.
- **App Icons**:
  - Generated Android and iOS launcher icons from the web app's SVG favicon using `flutter_launcher_icons: ^0.14.4`.
- **Hermetic Testing & Code Quality**:
  - Resolved all analyzer warnings and lints (0 errors, 0 warnings across the entire codebase).
  - Configured unit & widget tests with mocked network clients and isolated Hive storage.

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
