# Diary Mobile Client (`diary_flutter`) — Complete Documentation

> **Version**: 1.0.2  
> **Framework**: Flutter 3.x / Dart 3.x  
> **UI Design System**: Liquid Glass UI (`liquid_glass_easy: 4.3.1`)  
> **State Management**: Flutter Riverpod 2.x  
> **Local Storage**: Hive (Offline-First)  

---

## 1. Project Overview & Ecosystem

`diary_flutter` is the cross-platform mobile client for the School Diary ecosystem. It functions both as an autonomous offline timetable and study organizer, and as a companion to the full-stack School Diary platform (FastAPI backend + React frontend + PostgreSQL in Docker).

### Key Highlights
- **Offline-First Resilience**: All schedule items, homework assignments, notes, bells, and subject lists are stored locally in Hive boxes. You can read, create, edit, or delete items even with zero network connectivity.
- **Bi-Directional Auto-Synchronization**: Automatically flushes queued offline mutations and fetches server updates upon network recovery, app foregrounding, or periodic intervals.
- **Liquid Glass Aesthetics**: Built using `liquid_glass_easy: 4.3.1` with fluid backdrop blur lenses, frosted translucent surfaces, animated ambient color orbs, and full dark/light theme support.
- **Live Lesson Tracking**: Real-time lesson progress bar, countdown to next bell, and current status indicators.
- **Academic Parity System**: Supports Numerator ("чисельник") and Denominator ("знаменник") alternating weeks synchronized with academic calendar anchor dates.
- **Air Raid Alerts Integration**: Real-time Ukrainian civil defense alerts streamed via WebSocket from the Neptun API (`wss://neptun.in.ua/api/v1/stream`) with HTTP polling fallback.

---

## 2. System Architecture

The project adheres to a **Layered Clean Architecture** emphasizing separation of concerns, testability, and atomic module boundaries.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                              │
│   (Screens, Liquid Glass Widgets, Ambient Canvas, Lightbox, Dialogs)   │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Watches / Reads
┌───────────────────────────────────┴────────────────────────────────────┐
│                  Application / State Management Layer                  │
│   (Riverpod StateNotifiers: Schedule, Homework, Notes, Sync, Alerts)   │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Invokes / Subscribes
┌───────────────────────────────────┴────────────────────────────────────┐
│                        Domain / Core Layer                             │
│   (Immutable Data Models, Numerator/Denominator Parity, Bells Logic)   │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Persists / Requests
┌───────────────────────────────────┴────────────────────────────────────┐
│                    Data & Infrastructure Layer                         │
│  ┌────────────────────────┐  ┌────────────────┐  ┌──────────────────┐  │
│  │    Hive Local Boxes    │  │   Dio Client   │  │ SyncQueueManager │  │
│  │ (Schedule, HW, Notes)  │  │ (REST / Files) │  │  (Offline Queue) │  │
│  └────────────────────────┘  └────────────────┘  └──────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

### Architecture Pillars
1. **Offline Queue Pattern (`SyncQueueManager`)**:
   - Any write action (creating homework, adding a note, toggling completion, deleting) creates a `SyncAction` model.
   - The action is appended to `diary_sync_queue` in Hive and the UI updates **optimistically** (zero user wait time).
   - `SyncQueueManager` sequentially processes queued mutations when online. Local attachment files (photos/PDFs) are uploaded first, resolved into server URLs, and attached to the payload.
2. **Reactivity vs Stability with Riverpod**:
   - Providers managing long-lived network services (`AutoSyncService`, `HomeworkNotifier`, `NotesNotifier`) use `ref.read(syncQueueProvider)` rather than `ref.watch`. This prevents infinite recreation cascades when queue notifications fire.
   - UI widgets use `ref.watch` to selectively rebuild only when their specific domain state changes.
3. **Image Cache & Anti-Blink Engine**:
   - Thumbnail previews and full-screen lightbox galleries use `gaplessPlayback: true`, explicit `ValueKey`s, and `frameBuilder` listeners.
   - Decoded images stay displayed during provider refreshes and network pulls, completely preventing UI flicker.

---

## 3. Project Directory Map

```
diary_flutter/
├── android/                 # Native Android project files, manifest, and icons
├── ios/                     # Native iOS project configuration
├── assets/                  # Static assets (App icon, logos)
├── lib/
│   ├── main.dart            # Application entry point, Hive initialization, Engine config
│   │
│   ├── core/                # Core infrastructure independent of specific UI features
│   │   ├── api/             # REST HTTP client (Dio), base URL resolver, health check
│   │   │   └── api_client.dart
│   │   ├── config/          # Central configuration constants, defaults, and timeouts
│   │   │   └── app_config.dart
│   │   ├── database/        # Hive boxes manager, getters, setters, and queue storage
│   │   │   └── hive_boxes.dart
│   │   ├── localization/    # Bilingual i18n localization engine (Ukrainian & English)
│   │   │   └── app_localizations.dart
│   │   ├── sync/            # Offline synchronization engine
│   │   │   ├── auto_sync_service.dart   # Lifecycle, timer, and connectivity sync coordinator
│   │   │   └── sync_queue_manager.dart  # Offline mutation queue processor
│   │   └── theme/           # Design system, Liquid Glass styling, and ambient shaders
│   │       ├── ambient_background.dart  # Animated gradient canvas
│   │       └── liquid_theme.dart        # Semantic color palettes and glass lens styles
│   │
│   ├── features/            # Feature modules (Domain-driven screens & widgets)
│   │   ├── alerts/          # Air raid alerts banner & live status
│   │   ├── bells/           # Bell schedule view & slot inspector
│   │   ├── common/          # Reusable shared UI widgets
│   │   │   ├── attachment_chips_view.dart # Preview chips for images/docs with zoom
│   │   │   ├── lazy_indexed_stack.dart    # High-performance tab state preservation
│   │   │   └── lightbox_gallery.dart      # Fullscreen interactive zoom image viewer
│   │   ├── homework/        # Homework screen, task cards, filter chips, creation dialog
│   │   ├── navigation/      # Main scaffold, top navigation bar, liquid bottom bar
│   │   ├── notes/           # Lesson notes screen, cards, dialog with attachments
│   │   ├── schedule/        # Daily & weekly timetable, week selector, live tracker
│   │   ├── server_setup/    # Onboarding & server URL configuration wizard
│   │   ├── settings/        # App settings (Theme, Language, Sync, Region, Backup)
│   │   ├── stats/           # Academic analytics, subject load distribution, completion
│   │   └── subjects/        # Subjects drawer & teacher overview
│   │
│   ├── models/              # Strongly-typed immutable data entities
│   │   ├── bell_slot_model.dart     # Lesson order, start/end times
│   │   ├── holiday_model.dart       # Academic calendar breaks
│   │   ├── homework_model.dart      # Task description, completion, attachments
│   │   ├── lesson_note_model.dart   # Lesson notes with images & attachments
│   │   ├── schedule_model.dart      # Daily lessons, teacher, classroom, overrides
│   │   ├── subject_model.dart       # Subject metadata and color markers
│   │   └── sync_action_model.dart   # Queued offline mutation payloads
│   │
│   └── providers/           # Global Riverpod state providers
│       ├── alerts_provider.dart
│       ├── api_client_provider.dart
│       ├── bells_provider.dart
│       ├── homework_provider.dart
│       ├── notes_provider.dart
│       ├── schedule_provider.dart
│       ├── settings_provider.dart
│       ├── stats_provider.dart
│       └── subjects_provider.dart
│
├── test/                    # Unit and widget test suite
├── pubspec.yaml             # Project dependencies, assets, and metadata
└── UPDATES.md               # Version changelog and feature log
```

---

## 4. Dependencies & Packages Deep Dive

All packages have been selected for performance, modern Flutter 3 compatibility, and minimal memory overhead.

| Package | Version | Purpose & Usage in Project |
| :--- | :--- | :--- |
| [`liquid_glass_easy`](https://pub.dev/packages/liquid_glass_easy) | `4.3.1` | **Core UI Glassmorphism**: Provides `LiquidGlassLens` and `LiquidGlassEngine` for high-performance backdrop filters, frosted translucent borders, and light refractions optimized for Skia & Impeller. |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | `^2.6.1` | **State Management**: Reactive, compile-safe dependency injection and state observation. Manages app lifecycles, schedule caching, and sync states. |
| [`dio`](https://pub.dev/packages/dio) | `^5.11.1` | **HTTP Networking**: Robust HTTP client configured with timeouts, file uploads (`FormData`), header interceptors, and descriptive network diagnostic reporting. |
| [`hive_flutter`](https://pub.dev/packages/hive_flutter) | `^1.1.0` | **Local Key-Value Storage**: Ultra-fast, lightweight NoSQL database storing timetable rules, homework, notes, settings, and offline mutation queues. |
| [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) | `^7.3.1` | **Network State Listener**: Observes network transitions (Cellular, Wi-Fi, Offline) and triggers automatic sync when a connection is restored. |
| [`image_picker`](https://pub.dev/packages/image_picker) | `^1.2.3` | **Media Attachments**: Allows users to take camera photos or select gallery pictures to attach to homework assignments and lesson notes. |
| [`file_picker`](https://pub.dev/packages/file_picker) | `^13.1.0` | **Document Attachments**: Enables selecting PDF, DOCX, PPTX, or ZIP files to attach to lessons and homework. |
| [`path_provider`](https://pub.dev/packages/path_provider) | `^2.1.6` | **Filesystem Access**: Locates application temporary and document directories for local attachment storage and cache maintenance. |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | `^2.5.5` | **Simple Persistence**: Auxiliary preference storage alongside Hive for bootstrap parameters. |
| [`intl`](https://pub.dev/packages/intl) | `^0.20.2` | **Date & Time Formatting**: Formats ISO 8601 timestamps, day names, calendar dates, and localized clock displays. |
| [`web_socket_channel`](https://pub.dev/packages/web_socket_channel) | `^3.0.3` | **Real-Time Streaming**: Maintains persistent WebSocket stream with the Neptun Air Raid Alerts API for instantaneous alert dispatching. |
| [`uuid`](https://pub.dev/packages/uuid) | `^4.6.0` | **UUID Generation**: Generates cryptographically secure v4 UUIDs for client-side offline entities (notes, homework items, sync actions). |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | `^6.3.2` | **External Link Dispatcher**: Opens web links, file URLs, and remote attachments in system browsers or third-party viewer apps. |
| [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) | `^0.14.4` | **Build Utility (dev)**: Automatically generates Android adaptive icons and iOS app icons from `assets/icon/app_icon.png`. |

---

## 5. Core Feature Modules

### 5.1 Timetable & Schedule (`features/schedule`)
- **Daily View & Week Carousel**: Displays lessons ordered by bell slots. Supports jumping across dates with a horizontal date strip.
- **Numerator / Denominator Logic**: Automatically resolves alternating week rules according to `SEMESTER_ANCHOR_DATE` (default `2026-09-01`). Even week delta = Numerator; Odd week delta = Denominator.
- **Overrides & Substitutions**: Overrides (`is_cancelled: true`, teacher replacements, custom event types such as `control_work`, `test`, `essay`, `project`) are badged visually.
- **Lesson Detail Sheet**: Modal bottom drawer displaying lesson metadata, homework tasks, lesson notes, and attachments with direct editing capabilities.

### 5.2 Live Lesson Widget (`features/schedule/widgets/live_lesson_widget.dart`)
- Continuously calculates current time against bell schedules.
- Visual progress bar showing remaining minutes in the active lesson or countdown to the next bell during recess/breaks.

### 5.3 Homework Manager (`features/homework`)
- Filterable by **All**, **Pending**, and **Completed**.
- Displays subject color pill, due date, description, and attached photos/documents.
- One-tap completion toggle with optimistic offline synchronization.

### 5.4 Lesson Notes (`features/notes`)
- Free-form notes linked to specific lessons, dates, or subjects.
- Supports attaching multiple photos and documents with full-screen lightbox preview and interactive zoom (`InteractiveViewer`).

### 5.5 Academic Statistics (`features/stats`)
- **Subject Load Breakdown**: Visual progress bars displaying total hours per subject.
- **Daily Distribution**: Identifies heaviest study days of the week.
- **Homework Performance**: Completion percentage and task counts.

### 5.6 Air Raid Alerts (`features/alerts`)
- Directly monitors Ukrainian civil defense air raid alerts via Neptun WebSocket API.
- User-selectable alert region (e.g. `м. Київ`, `Київська область`, etc.).
- Animated top banner with danger pulse when an alert is active.

---

## 6. Offline Synchronization Mechanics

### The Data Flow
```
[User Action in App] (e.g. Create Homework)
         │
         ▼
[1. Local Optimistic Update]
   • Entity saved to Hive box (isPendingSync = true)
   • UI updates immediately
         │
         ▼
[2. Enqueue SyncAction]
   • Action appended to `diary_sync_queue` in Hive
         │
         ▼
[3. Sync Trigger Check]
   • Online? ──► Execute processQueue()
   • Offline? ─► Wait for Connectivity restoration / Foreground event
         │
         ▼
[4. Queue Processor (SyncQueueManager)]
   • Upload local files (if any) to `/api/v1/files/upload`
   • Replace local paths in payload with server URLs
   • Execute HTTP mutation (POST / PUT / DELETE)
   • Remove item from queue upon HTTP 2xx
         │
         ▼
[5. Bidirectional Pull]
   • Fetch latest remote items from server
   • Merge remote items with local pending changes
   • Overwrite Hive cache with authoritative state
```

---

## 7. Connecting to the Docker Server

The mobile app connects to the self-hosted School Diary Docker container.

### Default Server Endpoints
- **Nginx Web & API Gateway**: `http://<SERVER_IP>:8080`
- **Direct FastAPI Port**: `http://<SERVER_IP>:8000` (optional)
- **API Prefix**: `/api/v1`

### Configuring in Mobile App
1. Open the app and navigate to **Settings** (`⚙`) -> **Server Connection**.
2. Enter your host machine's Local Area Network IP address:
   ```text
   http://192.168.1.XXX:8080
   ```
3. Tap **Test Connection**.
   - If reachable, a green success confirmation is shown.
   - If unreachable, the built-in diagnostic tool will state the exact cause (e.g., *Connection Timeout — check Wi-Fi*, or *Connection Refused — check Docker port 8080*).
4. Tap **Save & Connect**.

---

## 8. Developer Guide & Verification

### Running the App Locally
```powershell
# 1. Fetch packages
flutter pub get

# 2. Run static analysis
flutter analyze

# 3. Run unit tests
flutter test

# 4. Launch on connected physical device or emulator
flutter run
```

### Generating App Icons
To regenerate adaptive Android and iOS icons from `assets/icon/app_icon.png`:
```powershell
dart run flutter_launcher_icons
```

### Building Release APK
```powershell
flutter build apk --release
```
The output APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`
