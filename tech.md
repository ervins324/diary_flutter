# tech.md: Frozen Technical Specification & Core Contract

Version: v1.0.6
Last Updated: 2026-09-30
Changelog:
- v1.0.6 (2026-09-30): Documented display settings parity keys (show_classrooms, skip_weekends_to_monday, performance_mode) and performance mode rendering architecture.
- v1.0.5 (2026-09-30): Initial frozen core specification for solo session-consistent build.

---

## 1. Project Overview

School Diary Mobile (`diary_flutter`) is an offline-first mobile client for the School Diary academic management platform. It operates autonomously without a network connection, stores all academic records locally, and performs bidirectional optimistic synchronization with a self-hosted FastAPI Docker backend when online. It also integrates real-time Ukrainian civil defense air raid alerts streamed via WebSocket.

Target users: Students and parents managing timetables, homework assignments, notes, and academic schedules.
Distribution: Personal use only. Direct Android APK sideloading and local iOS device debugging. No app store publication pipeline.

---

## 2. Stack Definition

- **Runtime**: Flutter 3.x / Dart 3.x (`sdk: ^3.11.3`).
- **State Management**: `flutter_riverpod: ^2.6.1`.
- **UI Design System**: `liquid_glass_easy: 4.3.1` (Liquid Glass UI, frosted translucent lenses, custom ambient canvas).
- **Navigation**: `ScaffoldWithNavBar` shell containing `LazyIndexedStack` for persistent tab states and modal bottom sheets.
- **Local Persistence**:
  - `hive_flutter: ^1.1.0` (Offline NoSQL key-value boxes).
  - `shared_preferences: ^2.5.5` (Bootstrap preferences, base URLs, active theme).
- **Networking**:
  - `dio: ^5.11.1` (REST API client, timeout management, multipart uploads).
  - `web_socket_channel: ^3.0.3` (Real-time alert streams).
  - `connectivity_plus: ^7.3.1` (Network transition watcher).
- **Media & File Handling**:
  - `image_picker: ^1.2.3` (Camera and gallery image selection).
  - `file_picker: ^13.1.0` (Document selection for PDF, DOCX, PPTX).
  - `path_provider: ^2.1.6` (Local file path management).
- **Backend**:
  - School Diary API (FastAPI backend running in Docker at `/api/v1`).
  - Neptun Air Raid Alerts API (`wss://neptun.in.ua/api/v1/stream` with polling fallback `https://neptun.in.ua/api/v1/alerts`).
- **Testing**:
  - `flutter_test` (Unit and widget tests).
  - Test seams: `FakeApiClient` and `mocktail`.

---

## 3. Architecture & Directory Structure

Feature-first structure with centralized infrastructure and domain models:

```
lib/
├── main.dart                      # Application initialization, Hive startup, root provider scope
├── core/
│   ├── api/                       # Dio network client, interceptors, error handling
│   │   ├── api_client.dart        # ApiClient abstract interface and Dio implementation
│   │   └── fake_api_client.dart   # In-memory fake client for testing and offline development
│   ├── config/                    # Configuration parameters, timeout constants, fallback URLs
│   │   └── app_config.dart
│   ├── database/                  # Hive database manager and box name definitions
│   │   └── hive_boxes.dart
│   ├── localization/              # Bilingual i18n support (Ukrainian default, English)
│   │   └── app_localizations.dart
│   ├── sync/                      # Synchronization services
│   │   ├── auto_sync_service.dart # Lifecycle and network-state sync coordinator
│   │   └── sync_queue_manager.dart# Persistent mutation queue dispatcher
│   └── theme/                     # Liquid glass styling, ambient shaders, colors
│       ├── ambient_background.dart# Animated gradient background
│       └── liquid_theme.dart      # Color tokens, glass lens styles
├── features/
│   ├── alerts/                    # Air raid alerts banner, widget, and polling
│   ├── bells/                     # Bell schedules, slot inspectors (Reference feature)
│   ├── common/                    # Shared reusable UI primitives
│   │   └── widgets/
│   │       ├── attachment_chips_view.dart
│   │       ├── lazy_indexed_stack.dart
│   │       └── lightbox_gallery.dart
│   ├── homework/                  # Homework list, status filter, creation and edit sheet
│   ├── navigation/                # Bottom navigation bar, root scaffold shell
│   ├── notes/                     # Lesson notes, attachment manager
│   ├── schedule/                  # Daily and weekly timetable, live lesson tracker
│   ├── server_setup/              # Host IP configuration and connection test tool
│   ├── settings/                  # User preferences, theme toggle, backup tools
│   ├── stats/                     # Academic workload analytics and charts
│   └── subjects/                  # Subject directory and teacher profiles
├── models/                        # Immutable data models with JSON and Hive serialization
│   ├── bell_slot_model.dart
│   ├── holiday_model.dart
│   ├── homework_model.dart
│   ├── lesson_note_model.dart
│   ├── schedule_model.dart
│   ├── subject_model.dart
│   └── sync_action_model.dart
└── providers/                     # Global Riverpod state notifiers and providers
    ├── alerts_provider.dart
    ├── api_client_provider.dart
    ├── bells_provider.dart
    ├── homework_provider.dart
    ├── notes_provider.dart
    ├── schedule_provider.dart
    ├── settings_provider.dart
    ├── stats_provider.dart
    └── subjects_provider.dart
```

---

## 4. Shared Widget Library

Every feature imports and composes these shared primitives rather than reimplementing ad-hoc UI elements:

1. `LiquidCard`: Translucent frosted glass surface using `LiquidGlassLens` with adaptive background blur and thin border refractions.
2. `LiquidButton`: Frosted glass interactive button supporting loading indicator, disabled state, and icon prefixes.
3. `LiquidTextField`: Frosted input field supporting input hints, validation error states, and clear buttons.
4. `AttachmentChipsView`: Horizontal list of attachment thumbnails and document chips with mime-type icons and tap handlers.
5. `LightboxGallery`: Fullscreen interactive image viewer utilizing `InteractiveViewer` with pinch-to-zoom, swipe-to-dismiss, and `gaplessPlayback: true`.
6. `LazyIndexedStack`: State-preserving indexed stack for bottom navigation tabs that prevents widget recreation during tab switching.
7. `StatusPill`: Compact colored pill for academic event types (`control_work`, `test`, `essay`, `project`), cancellation badges, and week parity indicators.
8. `StateFeedbackView`: Standardized container for loading shimmers, empty collection placeholders, and network error recovery messages.

---

## 5. Frozen Data Contracts & Schemas

### 5.1 Local Storage Contracts (Hive Boxes)

- `diary_bells`: Box storing `BellSlotModel` records keyed by `slot.id.toString()`.
- `diary_schedule`: Box storing `ScheduleModel` records keyed by `${date}_${lessonOrder}`.
- `diary_homework`: Box storing `HomeworkModel` records keyed by `homework.id`.
- `diary_notes`: Box storing `LessonNoteModel` records keyed by `note.id`.
- `diary_subjects`: Box storing `SubjectModel` records keyed by `subject.id`.
- `diary_settings`: Box storing raw configuration keys and values (`server_url`, `tailscale_url`, `language`, `theme_mode`, `alert_region`, `show_classrooms`, `skip_weekends_to_monday`, `performance_mode`).
- `diary_sync_queue`: Box storing `SyncActionModel` records keyed by `action.id`.

### 5.2 Model Field Schemas

#### `BellSlotModel`
```dart
class BellSlotModel {
  final int id;
  final int order;
  final String startTime; // "HH:MM"
  final String endTime;   // "HH:MM"
}
```

#### `ScheduleModel`
```dart
class ScheduleModel {
  final String date;          // "YYYY-MM-DD"
  final int lessonOrder;      // 1-indexed slot
  final String subject;
  final String? teacher;
  final String? room;
  final bool isCancelled;
  final String? eventType;    // "control_work" | "test" | "essay" | "project" | null
  final String? homeworkId;
  final String? noteId;
}
```

#### `HomeworkModel`
```dart
class HomeworkModel {
  final String id;            // UUID v4
  final String subjectId;
  final String subjectName;
  final String dueDate;       // "YYYY-MM-DD"
  final String description;
  final bool isCompleted;
  final List<String> attachments; // URLs or local file paths
  final bool isPendingSync;
}
```

#### `LessonNoteModel`
```dart
class LessonNoteModel {
  final String id;            // UUID v4
  final String date;          // "YYYY-MM-DD"
  final int lessonOrder;
  final String subject;
  final String text;
  final List<String> attachments; // URLs or local file paths
  final bool isPendingSync;
}
```

#### `SubjectModel`
```dart
class SubjectModel {
  final String id;            // UUID v4 or slug
  final String name;
  final String? teacher;
  final String? room;
  final String colorHex;      // "#RRGGBB"
}
```

#### `SyncActionModel`
```dart
class SyncActionModel {
  final String id;            // UUID v4
  final String endpoint;      // e.g. "/homework/"
  final String httpMethod;    // "POST" | "PUT" | "DELETE"
  final Map<String, dynamic> payload;
  final List<String> localFilePaths;
  final DateTime timestamp;
  final int retryCount;
}
```

### 5.3 Remote API Contracts (`/api/v1`)

- `GET /api/v1/bells/`: Returns `List<BellSlotModel>` JSON.
- `GET /api/v1/schedule/rules`: Returns recurring timetable rules.
- `GET /api/v1/schedule/overrides`: Returns date-specific overrides and cancellations.
- `GET /api/v1/homework/`: Returns `List<HomeworkModel>` JSON.
- `POST /api/v1/homework/`: Accepts `{ subject_id, due_date, description, attachments }`. Returns created entity.
- `PUT /api/v1/homework/{id}`: Accepts partial homework update payload.
- `DELETE /api/v1/homework/{id}`: Returns 204 No Content.
- `GET /api/v1/notes/`: Returns `List<LessonNoteModel>` JSON.
- `POST /api/v1/notes/`: Accepts `{ date, lesson_order, subject, text, attachments }`.
- `PUT /api/v1/notes/{id}`: Accepts updated note payload.
- `DELETE /api/v1/notes/{id}`: Returns 204 No Content.
- `GET /api/v1/subjects/`: Returns `List<SubjectModel>` JSON.
- `POST /api/v1/files/upload`: Multipart upload with `file` field. Returns `{ id: string, filename: string, url: string }`.
- `WSS wss://neptun.in.ua/api/v1/stream`: Returns real-time JSON alert payload with region status.

---

## 6. Academic Calendar & Parity Calculation

- `SEMESTER_ANCHOR_DATE` is `2026-09-01`.
- Week parity is calculated using Monday-based ISO week difference:
  - Even week delta: `numerator` (чисельник).
  - Odd week delta: `denominator` (знаменник).
- Schedule resolution algorithm:
  1. Retrieve master recurring rule for the day of week matching parity (`all` or current week parity).
  2. Overlay temporal override matching `(date, lesson_order)`. Overrides take precedence over master rules.
  3. Apply cancellation flags (`is_cancelled: true`).

---

## 7. Test Strategy & Rules

Tests attach to the slice and its task, not to a stage. A stage is several slices; there is no separate stage tests entity. A slice merges only with tests; the gate is red without them.

Tests are derived from the task acceptance criteria, not from the implementation. A test encodes the contract, not a mirror of the code.

Required test types per slice:
1. **Contract tests at boundaries**: The slice request/response or local model matches the shape in `tech.md`. The fake client is the test seam: it validates input against the contract and fails if the slice sends invalid data.
2. **Idempotency/retry tests for retryable operations**: A sync operation, a retried network call, or a background queue processor. Every such handler gets a test that runs it twice with the same input and checks the effect happens exactly once (no duplicated local records, no duplicate remote writes).
3. **Error-path tests**: Backend/API returns an error, times out, or the device is offline. Exercised through the fake client, which can be configured to fail.
4. **Widget tests for screens**: Renders expected state, responds to interaction, shows loading, error, and empty states.
5. **Property-based tests**: Applied to pure business logic (such as calendar parity calculations and bell countdown timers) where invariants exist.

---

## 8. Development & Commit Discipline

- Everything in English: commit messages, PR descriptions, code comments.
- Fixed commit format (Conventional Commits): `type(scope): summary`. Types: `feat`, `fix`, `test`, `refactor`, `chore`, `docs`. Summary in the imperative, lowercase, no trailing period, around 50 characters, specific.
- Commit in small logical steps as you go, not one massive commit at the end.
- Code comments are short and explain why, not what. Never delete existing comments. Never leave commented-out code in a PR.
- Stop-slop discipline: active voice, imperative mood, no em-dashes, no filler text.
- Version tracking: Update `pubspec.yaml` version and append details to `UPDATES.md` after every feature or fix.

---

## 9. Definition of Done for One Task

A task or vertical slice is done only when:
1. `flutter analyze` reports zero warnings or errors.
2. `dart format --output=none --set-exit-if-changed .` passes cleanly.
3. `flutter test` passes with zero failures.
4. Acceptance criteria tests (contract, idempotency, error path, widget) are written and green.
5. Local Hive persistence operates cleanly without unhandled exceptions.
6. The app runs on device/emulator without visual regressions or layout overflows.
7. `pubspec.yaml` version is bumped and changes are logged in `UPDATES.md`.
