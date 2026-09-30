# Updates Log

## [1.0.9] - 2026-09-30
### Added & Optimized
- **Liquid Glass Sliding Switchers (Smooth Physical Translation)**:
  - **Bottom Navigation Bar**: Replaced individual fading button highlights with an `AnimatedPositioned` glowing liquid glass capsule that smoothly translates (slides) across the bar between tabs with `Curves.easeOutCubic`. Tab icons subtly scale with `AnimatedScale` and labels smoothly transition typography via `AnimatedDefaultTextStyle`.
  - **Horizontal Page Translation**: Transformed `MainScaffold` into a stateful controller with `PageView` and `KeepAliveWrapper`, providing silky-smooth horizontal screen translation when switching tabs while preserving full scroll positions and states.
  - **Reusable `LiquidSlidingSwitcher<T>` Component**: Created an atomic, flexible liquid sliding segmented control with smooth translating gradient capsules and soft glow lighting.
  - **Stats Screen Switchers**: Upgraded Schedule Mode (`Actual` / `Numerator` / `Denominator`), Metric Switcher (`Time` / `Lessons`), and View Switcher (`By Subjects` / `By Days`) to `LiquidSlidingSwitcher`.
  - **Settings Screen Switchers**: Replaced standard segmented buttons with `LiquidSlidingSwitcher` for Language (`Українська` / `English`) and Theme (`Dark` / `Light`).
  - **Week Selector Day Track**: Replaced 6 disconnected day chip cards with a unified continuous liquid sliding track where the active day capsule smoothly glides from day to day with subtle today indicators.
- **WebSocket Unhandled Exception & Network Resilience Fix**:
  - Attached explicit error handlers to `WebSocketChannel.ready` and `stream.listen(cancelOnError: true)` in `AirRaidAlertNotifier`.
  - Safely handled DNS lookup failures (`SocketException: Failed host lookup: 'neptun.in.ua'`), preventing unhandled Dart VM zone exceptions when device is offline or network is unreachable.

## [1.0.8] - 2026-09-30
### Added & Optimized
- **Complete Elimination of Raster Stalls & `saveLayer` Overhead**:
  - Diagnosed `dart_perf_2` profile (1,274 frames): Revealed that UI thread build time was extremely fast (4.49 ms average), but the Raster / GPU thread was heavily bottlenecked (21.29 ms average raster time, 57.6% global jank rate, peaking at 88.85 ms raster time and 139.98 ms frame elapsed time).
  - **Stats Screen Overhaul**: Identified that the Stats tab was experiencing a **95.3% jank rate** averaging 30.70 ms raster time due to 18 unoptimized `LiquidGlassLens` widgets and over 13,148 `saveLayer` render-target switches across metric pills, KPI cards, academic badges, homework progress, breaks summary, and subject breakdown charts.
  - **Zero-Lens Performance Mode on Stats**: Refactored `StatsScreen` to wire every card and switcher into `performanceModeProvider`. When Performance Mode is active, all 18 lenses are replaced with lightweight, zero-backdrop frosted cards, eliminating 100% of lens render passes on the screen.
  - **Global Lens Bypass across Views**:
    - `MainScaffold`: In Performance Mode, completely bypasses `LiquidGlassView` and replaces it with a direct `Stack` over `AmbientBackground`, eliminating the continuous 24 FPS offscreen texture capture pipeline. Replaces `_BottomGlassNavBar` with a hardware-accelerated frosted navigation bar.
    - `WeekSelector`: Bypasses 7 active lenses (week pill and 6 day chips) in Performance Mode, preventing raster thrashing during day navigation.
    - `LiveLessonWidget` & `AirRaidBanner`: Bypassed lenses in favor of lightweight rounded cards in Performance Mode.
    - `ScheduleScreen` & `SettingsScreen`: Removed `LiquidGlassBatch` wrapper overhead and replaced all 5 settings cards with zero-cost frosted cards in Performance Mode.

## [1.0.7] - 2026-09-30
### Added & Optimized
- **Hero Collision Crash Fix**:
  - Resolved `FlutterError` ("multiple heroes that share the same tag within a subtree") by assigning explicit unique hero tags (`homework_fab` and `notes_fab`) to the `FloatingActionButton`s in `HomeworkScreen` and `NotesScreen`, preventing crashes when switching tabs within `LazyIndexedStack` or opening modal sheets.
- **Settings Parity with Web App**:
  - **Show/Hide Classrooms (`show_classrooms`)**: Added persistent setting and provider to toggle classroom/cabinet display. When disabled, room numbers and badges are hidden in `LessonSlotCard` and `LessonDetailSheet`.
  - **Weekend Auto-Advance (`skip_weekends_to_monday`)**: Added persistent setting and provider to automatically advance timetable view and schedule loading to the upcoming Monday when opened on Saturday or Sunday.
  - **Display & Interface Settings UI**: Added clean settings card with switches for Classrooms, Weekend Auto-Advance, and High Performance Smooth Scrolling Mode.
  - **Localization**: Added bilingual strings in Ukrainian (`uk`) and English (`en`) for all new display preferences.
- **DevTools Profiling & Jank Elimination**:
  - Diagnosed performance profile (`dart_devtools_2026-09-30_12_01_01.895.json` and `12_02_00.755.json`): Identified that 29.3% of total CPU time was consumed by procedural rim mesh calculations (`_buildRimMesh` in `liquid_glass_easy`) inside scrollable list items, and raster time was averaging 21.56ms (76.7% jank frames) under debug JIT execution.
  - **Smooth Scrolling / High Performance Mode**: Allows users to switch list cards (`LessonSlotCard`, `HomeworkCard`, `NoteCard`) to lightweight frosted containers with zero per-frame CPU rim tessellation and zero backdrop filter overdraw during fast scrolling.
  - **Background Repaint Elimination**: When Performance Mode is active, `AmbientBackground` pauses its continuous 60 FPS animation ticker and switches to a static, raster-cached ambient mesh with `RepaintBoundary(willChange: false)`, preventing full-screen repaint cycles on every frame.
- **Documentation Cleanup**:
  - Deleted obsolete `DOCS.md` and updated `README.md` to reference `tech.md` and `WORKFLOW.md` as the frozen single source of truth.

## [1.0.6] - 2026-09-30
### Added & Documented
- **Solo Session-Consistent Architecture Framework**:
  - Generated frozen core specification (`tech.md` v1.0.5) defining immutable stack choices, Hive box schemas, remote REST API contracts, shared Liquid Glass widget primitives, and testing doctrine.
  - Implemented session execution guide (`WORKFLOW.md`) establishing vertical slice task list (Tasks 0 through 8), acceptance criteria, per-slice test definitions, and strict `CONTRACT GAP` escalation process.

## [1.0.5] - 2026-09-29
### Added & Optimized
- **LiquidGlass Rendering & Shader Pipeline Optimizations**:
  - **Batch Rendering with `LiquidGlassBatch`**: Wrapped scrollable views across `ScheduleScreen`, `HomeworkScreen`, `NotesScreen`, `StatsScreen`, and `SettingsScreen` in `LiquidGlassBatch`. Descendant lenses now share a single backdrop read and composite pass rather than each taking independent readbacks every frame, drastically reducing mobile GPU overhead.
  - **Startup Shader Pre-compilation**: Integrated `LiquidGlassShaders.ensureLoaded()` in `main()` before `runApp()` to warm up lens, border, and blender fragment programs on application start, completely eliminating first-glass shader compilation jank.
  - **Android Skia Performance Tuning**:
    - Reduced `LiquidGlassView.pixelRatio` from default `1.0` to `0.6` in `MainScaffold`, reducing background capture pixel volume by 64% with negligible perceived difference under blur.
    - Set `LiquidGlassView.refreshRate` to `LiquidGlassRefreshRate.medium` (~24 FPS) to prevent 60–120 FPS capture cycles from saturating CPU/GPU pipelines on high-refresh-rate displays.
    - Reduced excessive blur sigmas across all styles to optimal Skia bounds (all $\le 7.0$): `cardStyle` reduced from 16.0 to 6.0, `pillStyle` reduced from 12.0 to 4.0, `navBarStyle` reduced from 24.0 to 7.0, `air_raid_banner` reduced from 16.0 to 6.0, and `week_selector` day chips reduced from 12.0 to 4.0.
  - **LiteGlass Fallback Pipeline & Impeller Shader Activation**:
    - Configured `LiquidGlassEngine.liteGlassOnSkia = true` with `LiquidGlassLitePickup.blend` so that older Android / Skia devices automatically fall back to lightweight frosted geometry without heavy real-time refraction passes.
    - Configured `LiquidGlassEngine.liteGlassOnImpeller = false` so modern Impeller-enabled devices utilize hardware-accelerated shaders paired with `LiquidGlassBatch`.
    - Added `liteGlass: LiquidGlassLitePickup.blend` to standalone styles (`air_raid_banner`, `week_selector`) to eliminate redundant backdrop reads during lite mode.
  - **Ambient Mesh Painter Isolation**: Wrapped `AnimatedBuilder` inside `AmbientBackground` with an isolated `RepaintBoundary` to decouple background gradient canvas invalidations from foreground widget layers.

## [1.0.4] - 2026-09-28
### Added & Optimized
- **Tailscale Tailnet IP Automatic Fallback & Dual-Probe Health System**:
  - Added configurable Tailscale / Tailnet fallback URL (`HiveBoxes.getTailscaleUrl`, `AppConfig.defaultTailscaleUrl`) allowing users to connect to their backend from anywhere outside home Wi-Fi.
  - Implemented dual-probe health checking in `ApiClient.checkHealth()`: tests primary LAN server first with fast 3-second timeout; if primary fails or times out, immediately and seamlessly falls back to Tailscale Tailnet IP.
  - Integrated `TailscaleFallbackInterceptor` into Dio to automatically catch mid-session connection timeouts/socket failures on primary LAN and auto-retry seamlessly over Tailscale without dropping mutations or sync tasks.
  - Updated `ServerSetupScreen` and `SettingsScreen` with dedicated Primary and Tailscale input fields, independent health probes, and active fallback status badges.
  - Added bilingual translations in Ukrainian (`uk`) and English (`en`) for Tailscale fallback configuration, active status indicators, and error diagnostics.
  - Updated `AttachmentHelper.resolveUrl()` to use `HiveBoxes.getActiveServerUrl()` so image and document attachments resolve reliably whether connected via LAN or Tailscale.
- **Application Display Name Refinement**:
  - Changed Android application launcher label from `diary_flutter` to `Diary` in `AndroidManifest.xml`.
  - Aligned display names in `Info.plist`, `web/manifest.json`, `web/index.html`, and `AppConfig.appName`.
- **Comprehensive Performance & Battery Optimizations**:
  - **AmbientBackground Lifecycle & Paint Recycling**: Added `AppLifecycleListener` to pause the 30-second gradient animation controller when the application is minimized, paused, or hidden, eliminating wasted GPU/CPU cycles in the background. Recycled static `Paint` instances in `AmbientMeshPainter` to prevent ~240 object allocations per second.
  - **Air Raid Alerts Background Pause**: Added `AppLifecycleListener` in `AirRaidAlertNotifier` to pause the 30-second HTTP polling timer and WebSocket reconnection when the application is backgrounded or hidden, mirroring web client behavior and saving mobile bandwidth and battery.
  - **LiveLessonWidget Lifecycle Management**: Paused the 15-second countdown timer in `LiveLessonWidget` while the app is in the background, resuming immediately upon returning to foreground.
  - **Scaffold Rebuild Isolation**: Refactored `MainScaffold` to extract `_ConnectionSyncBadge` and `_BottomGlassNavBar` into dedicated, self-contained widgets, preventing auto-sync state updates from triggering whole-page rebuilds of `LiquidGlassView` and navigation layouts.
  - **List Reconciliation with `findChildIndexCallback`**: Added `findChildIndexCallback` and explicit keys across `ScheduleScreen`, `HomeworkScreen`, and `NotesScreen` `SliverChildBuilderDelegate`s for fast child element recycling during list mutations.
  - **LiquidTheme Style Caching**: Introduced a static style cache in `LiquidTheme` (`cardStyle`, `pillStyle`, `navBarStyle`) to avoid reallocating `LiquidGlassStyle` objects on every widget build.

## [1.0.3] - 2026-09-25
### Fixed & Improved
- **Release Mode Server Connection**: Fixed failure to connect to the Docker backend (`http://<LAN_IP>:8080`) in Android release mode:
  - Added `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE` directly to `android/app/src/main/AndroidManifest.xml` (previously only injected in debug/profile builds).
  - Configured `android:usesCleartextTraffic="true"` and added a dedicated `res/xml/network_security_config.xml` with system and user trust anchors to enable unencrypted HTTP traffic to local Docker server LAN IP addresses on modern Android versions (Android 9+ through Android 16).
  - Configured `NSAppTransportSecurity` (`NSAllowsArbitraryLoads` & `NSAllowsLocalNetworking`) in `ios/Runner/Info.plist` for local network communication.
  - Enhanced `ApiClient` error diagnostics to show underlying socket details and added a warning when attempting to use `localhost` on mobile devices.
- **Test Suite Hermeticity**: Stabilized `widget_test.dart` by overriding `autoSyncProvider` to prevent background periodic timers from keeping tests open.

## [1.0.2] - 2026-09-24
### Added & Improved
- **Comprehensive Project Documentation (`DOCS.md`)**: Created exhaustive documentation covering project overview, layered clean architecture, offline-first sync lifecycle, complete package inventory, feature modules, and Docker backend setup. Updated `README.md` with quickstart instructions.
- **Auto-Sync Isolate Loop Resolution**: Fixed rapid ~600ms sync loops and VS Code isolate flooding by replacing `ref.watch(syncQueueProvider)` with `ref.read` across `AutoSyncService`, `HomeworkNotifier`, and `NotesNotifier`.
- **Accurate Connection & Health Diagnostics**: Added descriptive network diagnostic formatting in `ApiClient.checkHealth()` (`_formatDioError`) to pinpoint Docker port 8080 or LAN Wi-Fi issues instead of generic "Server unreachable" messages.
- **Image Anti-Flicker & List Reconciliation**:
  - Added `gaplessPlayback: true`, `cacheWidth: 200`, and `frameBuilder` listeners across `AttachmentChipsView` and `LightboxGallery`.
  - Added explicit `ValueKey`s across `NoteCard`, `HomeworkCard`, and lesson detail sheet items to stabilize widget reconciliation during cache invalidations.

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
