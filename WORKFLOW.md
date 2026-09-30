# WORKFLOW.md: Solo Session-Consistent Build Guide

## 1. Read First

1. Follow `tech.md` literally. It is the single frozen source of truth for architecture, models, API shapes, Hive boxes, and conventions.
2. Every session must read `tech.md` before writing code.
3. Never invent a contract, endpoint, model field, or storage key that does not exist in `tech.md`.

---

## 2. Handling Missing Contracts: CONTRACT GAP

If a task requires a model field, endpoint, or storage box not specified in `tech.md`:
1. **STOP immediately**. Do not invent temporary fields or make ad-hoc schema modifications in code.
2. Output a formal CONTRACT GAP block:
   ```text
   CONTRACT GAP:
   - Missing item: [e.g. Model field, API endpoint, Hive box key]
   - Feature context: [Feature name and reason it is needed]
   - Proposed specification: [Exact signature, Dart type, JSON representation]
   ```
3. Update `tech.md` directly:
   - Append the contract to the relevant section.
   - Bump the version in `tech.md` and log the change in its changelog header.
4. Resume the task using the updated contract.

---

## 3. Structural Template & Reference Feature

All feature modules must mirror the architecture of the reference feature:
`lib/features/bells/`

Feature directory layout:
```
lib/features/<feature>/
├── presentation/ (or screen & widgets directly within feature directory)
│   ├── <feature>_screen.dart
│   └── widgets/
│       └── <feature>_card.dart
```
State management integration:
- Riverpod `StateNotifierProvider` or `NotifierProvider` located in `lib/providers/<feature>_provider.dart`.
- UI reads state with `ref.watch` for granular rebuilds.
- Background services and asynchronous dispatchers read state using `ref.read` to avoid rebuild loops.

---

## 4. Staged Vertical Task List

Each task represents one complete vertical slice (data, state, presentation, tests). Do not split tasks into horizontal layers.

### Task 0: App Skeleton & Foundation
- **Goal**: Establish the app shell, persistent bottom navigation, theme, Hive initialization, fake client, and shared widget catalog.
- **Folder**: `lib/core/`, `lib/features/navigation/`, `lib/features/common/`
- **Contracts**: `HiveBoxes` configuration, `ApiClient` abstract interface, `FakeApiClient`.
- **Shared Widgets Used**: `LiquidCard`, `LiquidButton`, `LazyIndexedStack`, `StateFeedbackView`.
- **Acceptance Criteria**:
  1. Hive initializes all boxes without throwing errors.
  2. Bottom navigation switches between tabs without losing child widget state.
  3. Kitchen-sink screen renders all shared widgets with glassmorphic shaders without layout overflow.
  4. `FakeApiClient` returns mock seed data.
- **Tests**:
  - `test/core/hive_boxes_test.dart`: Verifies box initialization and clean boot.
  - `test/core/fake_api_client_test.dart`: Validates contract shapes returned by mock client.
  - `test/features/navigation/navigation_scaffold_test.dart`: Asserts tab switching and state preservation.

---

### Task 1: Bells Schedule & Calendar Parity (Reference Feature)
- **Goal**: Implement bell slot inspection and numerator/denominator week parity calculation.
- **Folder**: `lib/features/bells/`
- **Contracts**: `BellSlotModel`, `HolidayModel`, `GET /api/v1/bells/`.
- **Shared Widgets Used**: `LiquidCard`, `StatusPill`, `StateFeedbackView`.
- **Acceptance Criteria**:
  1. Displays ordered bell intervals with start and end times.
  2. Correctly resolves numerator or denominator based on ISO week offset from `2026-09-01`.
  3. Displays active holiday breaks when dates fall within a defined holiday range.
- **Tests**:
  - `test/models/bell_slot_model_test.dart`: Contract test for JSON deserialization.
  - `test/utils/week_parity_test.dart`: Property-based and unit tests for parity resolution across semester boundaries.
  - `test/features/bells/bells_screen_test.dart`: Widget test verifying empty, loading, and loaded bell lists.

---

### Task 2: Timetable & Live Lesson Widget
- **Goal**: Build daily timetable view with carousel date strip, cancellation badges, and countdown progress bar.
- **Folder**: `lib/features/schedule/`
- **Contracts**: `ScheduleModel`, `GET /api/v1/schedule/rules`, `GET /api/v1/schedule/overrides`.
- **Shared Widgets Used**: `LiquidCard`, `StatusPill`, `StateFeedbackView`.
- **Acceptance Criteria**:
  1. Lessons render ordered by bell slots for the selected date.
  2. Overrides take precedence over master recurring schedule rules.
  3. Cancelled lessons display cancellation badges.
  4. Live tracker displays a progress bar during an active lesson and countdown during recess.
- **Tests**:
  - `test/models/schedule_model_test.dart`: Contract test matching `ScheduleModel` schema.
  - `test/features/schedule/schedule_override_precedence_test.dart`: Verifies override priority over master rules.
  - `test/features/schedule/live_lesson_widget_test.dart`: Widget test simulating time ticks during lesson and recess.

---

### Task 3: Homework Manager
- **Goal**: Provide offline-first homework assignment tracking with status filtering and optimistic completion toggles.
- **Folder**: `lib/features/homework/`
- **Contracts**: `HomeworkModel`, `GET|POST|PUT|DELETE /api/v1/homework/`.
- **Shared Widgets Used**: `LiquidCard`, `LiquidButton`, `AttachmentChipsView`, `StateFeedbackView`.
- **Acceptance Criteria**:
  1. Homework items can be filtered by `All`, `Pending`, and `Completed`.
  2. Toggling completion immediately updates local Hive state and enqueues a sync action.
  3. User can create new homework items specifying subject, due date, description, and attachments.
- **Tests**:
  - `test/models/homework_model_test.dart`: Contract test for model serialization.
  - `test/features/homework/homework_optimistic_toggle_test.dart`: Idempotency test verifying toggling twice maintains expected final state and logs single sync action.
  - `test/features/homework/homework_screen_test.dart`: Widget test for filter switching and item rendering.

---

### Task 4: Lesson Notes & Media Attachments
- **Goal**: Create and view free-form lesson notes with image and document attachments, including full-screen lightbox preview.
- **Folder**: `lib/features/notes/`
- **Contracts**: `LessonNoteModel`, `GET|POST|PUT|DELETE /api/v1/notes/`.
- **Shared Widgets Used**: `LiquidCard`, `AttachmentChipsView`, `LightboxGallery`, `LiquidTextField`, `LiquidButton`.
- **Acceptance Criteria**:
  1. Notes render with timestamps, subject tag, text content, and attached files.
  2. Tapping an image attachment launches `LightboxGallery` with zoom capabilities.
  3. Creating a note with attachments stores local paths in Hive and schedules file upload.
- **Tests**:
  - `test/models/lesson_note_model_test.dart`: Contract test for note structure and attachments array.
  - `test/features/notes/lightbox_gallery_test.dart`: Widget test verifying zoom gestures and image rendering.
  - `test/features/notes/notes_screen_test.dart`: Widget test validating note submission and error fallback.

---

### Task 5: Subjects & Teacher Directory
- **Goal**: Display directory of academic subjects with assigned teacher contacts, classroom numbers, and color indicators.
- **Folder**: `lib/features/subjects/`
- **Contracts**: `SubjectModel`, `GET /api/v1/subjects/`.
- **Shared Widgets Used**: `LiquidCard`, `StatusPill`, `StateFeedbackView`.
- **Acceptance Criteria**:
  1. Displays subjects with hex color chips and teacher information.
  2. Clicking a subject opens details showing associated homework and timetable distribution.
- **Tests**:
  - `test/models/subject_model_test.dart`: Contract test for JSON parsing and color hex validation.
  - `test/features/subjects/subjects_screen_test.dart`: Widget test for subject list rendering.

---

### Task 6: Offline Sync Engine & Network Resilience
- **Goal**: Implement two-phase mutation queue dispatching, attachment file resolution, and network recovery triggers.
- **Folder**: `lib/core/sync/`
- **Contracts**: `SyncActionModel`, `POST /api/v1/files/upload`.
- **Shared Widgets Used**: None (Core background service).
- **Acceptance Criteria**:
  1. Actions queued while offline persist across app restarts in `diary_sync_queue`.
  2. Connectivity restoration initiates queue processing sequentially.
  3. Attachments upload first; resulting server URLs replace local paths before payload dispatch.
  4. Successful 2xx responses remove the action from the queue. Failed attempts increment retry count.
- **Tests**:
  - `test/core/sync_queue_manager_test.dart`: Idempotency test checking repeated queue runs do not double-dispatch requests.
  - `test/core/two_phase_upload_test.dart`: Contract test verifying file upload URL substitution in payloads.
  - `test/core/sync_error_retry_test.dart`: Error-path test verifying backoff on network failures.

---

### Task 7: Air Raid Alerts Integration
- **Goal**: Stream real-time civil defense alerts via WebSocket with HTTP polling fallback and dynamic warning banner.
- **Folder**: `lib/features/alerts/`
- **Contracts**: Neptun Alert schema, `WSS wss://neptun.in.ua/api/v1/stream`.
- **Shared Widgets Used**: `LiquidCard`, `StatusPill`.
- **Acceptance Criteria**:
  1. Connects to Neptun WebSocket and updates alert status when payload is received.
  2. Falls back to HTTP polling if WebSocket connection drops.
  3. Displays red pulsing banner at the top of the app when an alert is active for the user's selected region.
- **Tests**:
  - `test/features/alerts/alerts_parser_test.dart`: Contract test validating incoming WebSocket JSON schema.
  - `test/features/alerts/alerts_banner_widget_test.dart`: Widget test checking alert active vs clear presentation.

---

### Task 8: Academic Analytics & Server Configuration
- **Goal**: Render workload distribution charts and provide server IP configuration wizard with connection diagnostics.
- **Folder**: `lib/features/stats/`, `lib/features/server_setup/`
- **Contracts**: `diary_settings` Hive storage, server ping endpoint.
- **Shared Widgets Used**: `LiquidCard`, `LiquidButton`, `LiquidTextField`, `StateFeedbackView`.
- **Acceptance Criteria**:
  1. Computes total lesson hours per subject and identifies heaviest study days.
  2. User can enter custom server IP, run a connection test, and view diagnostic error messages if unreachable.
- **Tests**:
  - `test/features/stats/stats_calculator_test.dart`: Unit tests for hour tallies and workload distribution.
  - `test/features/server_setup/connection_test.dart`: Verifies timeout, connection refused, and success responses.

---

## 5. Development Cycle for Each Task

Execute every task with the following sequence:

1. **Review Contract**: Confirm all required models and endpoints exist in `tech.md`. If missing, execute the CONTRACT GAP procedure.
2. **Derive Tests**: Write tests before or alongside implementation based on task acceptance criteria (contract, idempotency, error path, widget).
3. **Implement Feature**:
   - Write models and repositories in feature/core folder.
   - Wire Riverpod providers.
   - Build UI screens composing shared widgets from `lib/features/common/widgets/`.
4. **Run Verification Commands**:
   ```powershell
   flutter analyze
   dart format --output=none --set-exit-if-changed .
   flutter test
   ```
5. **Verify on Device**: Run on physical device or emulator to confirm visual rendering and gesture responsiveness.
6. **Bump Version & Log**:
   - Bump version in `pubspec.yaml`.
   - Add entry to `UPDATES.md` detailing changes with date and version.
7. **Commit & Ship**:
   - Commit following Conventional Commits format (`type(scope): summary`).

---

## 6. Prohibited Side-Effects Mid-Task

During an assigned feature task, do not:
- Redesign shared widgets in `lib/features/common/widgets/` for the convenience of one feature.
- Change global theme colors or font tokens in `lib/core/theme/`.
- Restructure root routing or bottom navigation in `lib/features/navigation/`.
- Alter existing Hive box schemas or remote API contracts without updating `tech.md` first.
