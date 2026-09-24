# School Diary Mobile Client (`diary_flutter`)

Cross-platform Flutter mobile client for the School Diary ecosystem, featuring **Liquid Glass UI**, offline-first storage, real-time timetable tracking, homework management, lesson notes, and bidirectional synchronization with the self-hosted Docker backend.

---

## 📖 Documentation

For full architectural blueprints, package deep-dives, synchronization flows, and feature breakdowns, please refer to:
👉 **[DOCS.md](DOCS.md)**

---

## ✨ Core Features

- 🧊 **Liquid Glass UI (`liquid_glass_easy: 4.3.1`)**: High-performance backdrop filter lenses, ambient lighting shaders, and sleek dark/light theme support.
- 📴 **Offline-First Resilience**: Full local persistence using **Hive**. Create and edit homework, notes, and schedules even when completely offline.
- 🔄 **Bidirectional Auto-Sync**: Intelligent offline queue processor (`SyncQueueManager`) with conflict-free merges and network lifecycle monitoring.
- ⏰ **Live Lesson Tracker**: Real-time lesson progress bar and countdown to the next bell.
- 📅 **Academic Parity Support**: Alternating Numerator ("чисельник") and Denominator ("знаменник") week schedules with anchor date synchronization.
- 🚨 **Neptun Air Raid Alerts**: WebSocket live alert streaming for civil defense in Ukraine with region selection.
- 🖼️ **Lightbox Gallery**: Full-screen image preview with pinch-to-zoom and multi-attachment management.

---

## 🚀 Quick Start

### 1. Requirements
- Flutter SDK `^3.11.3` (or higher)
- Dart SDK `^3.11.3`
- Android SDK 21+ / iOS 13+

### 2. Installation & Run
```powershell
# Get dependencies
flutter pub get

# Run static checks
flutter analyze

# Run unit tests
flutter test

# Run app on connected device
flutter run
```

### 3. Server Configuration
To link with your self-hosted Docker stack:
1. Open the app and tap **Settings** (`⚙`) -> **Server Connection**.
2. Enter your server's LAN address (e.g. `http://192.168.1.100:8080`).
3. Tap **Test Connection** and **Save**.
