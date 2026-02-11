# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

macOS menu bar app that creates native Apple Reminders via a Spotlight-style command palette. Press `Cmd+/` anywhere on macOS to open the palette, type a natural language reminder (must include a date/time), and hit Return.

## Build & Test

```bash
make build          # Debug build via xcodebuild
make run            # Build and launch the app
make test           # Run unit tests
make release        # Release build
make clean          # Clean build artifacts
```

The Xcode project (`SlashRemind.xcodeproj`) is the source of truth. There is no SPM build.

## Architecture

### Dependency Flow

```
AppDelegate (creates all services, wires dependencies)
  ├── SettingsStore (UserDefaults, @Published)
  ├── EventKitRemindersService (implements RemindersAPI protocol)
  ├── SoulverDateParser (implements DateParsing protocol)
  ├── NotificationScheduler (implements NotificationScheduling protocol)
  ├── PaletteViewModel (receives all services via constructor injection)
  │     └── CommandPaletteWindowController (SwiftUI palette window)
  ├── StatusBarController (menu bar icon + menu)
  └── HotKeyService (Carbon RegisterEventHotKey → toggles palette)
```

All services are protocol-based (`RemindersAPI`, `DateParsing`, `NotificationScheduling`) for testability. `MockRemindersAPI` is an `actor` for thread-safe test isolation.

### Directory Layout

```
SlashRemind.xcodeproj/       Xcode project
SlashRemindApp.swift          App entry point (@main)
App/                          AppDelegate
Palette/                      CommandPaletteView, WindowController, DoublePressDetector
Services/                     RemindersAPI, EventKitRemindersService, DateParsingService,
                              HotKeyService, NotificationScheduler, SettingsStore
ViewModels/                   PaletteViewModel
StatusBar/                    StatusBarController
Preferences/                  PreferencesWindow
Utilities/                    OSLog+Categories
Resources/                    Assets.xcassets
SlashRemind/                  Info.plist, entitlements (referenced by xcodeproj)
Info.plist                    Root Info.plist
SlashRemindTests/             Unit tests (DateParsing, RemindersAPI, PaletteViewModel)
SlashRemindUITests/           UI tests
Makefile                      Build/test/run shortcuts
```

### Reminder Creation Pipeline

User input → `SoulverDateParser` extracts date via SoulverCore's `String.dateValue` → `EventKitRemindersService` creates `EKReminder` with due date and alarm via EventKit → `NotificationScheduler` logs scheduling. If no date is parsed from input, submission is rejected with an error message.

### Key Concurrency Patterns (Swift 6 strict mode)

- **`@MainActor`**: All UI components (`StatusBarController`, `CommandPaletteWindowController`, `PaletteViewModel`, AppDelegate UI methods)
- **`@Sendable` closures**: `HotKeyService` callback bridges Carbon event handler to main thread via `DispatchQueue.main.async`
- **`@unchecked Sendable`**: Used for `EventKitRemindersService` (EKEventStore is thread-safe per Apple docs) and `SoulverDateParser` (stateless pure function)
- **`Unmanaged` pointer**: `HotKeyService` passes `self` to C callback via `Unmanaged.passUnretained`

### Global Hotkey Mechanism

`HotKeyService` → `RegisterEventHotKey` (Carbon API) registers `Cmd+/` (key code 44) → `InstallEventHandler` listens for `kEventHotKeyPressed` → triggers palette toggle via callback. No special permissions required (unlike CGEvent tap).

### Date Parsing Quirk

`SoulverDateParser` adjusts noon (12:00:00) results to 9:00 AM — when SoulverCore returns exactly noon it typically means no specific time was given, so 9 AM is used as a sensible default.

## Coding Conventions

- Swift 6.1, macOS 13+ (`#if os(macOS)` guards on platform-specific code, `#if canImport(os)` for os.log)
- 4-space indentation, standard Swift naming (UpperCamelCase types, lowerCamelCase members)
- Logging via `os_log` with categories defined in `Utilities/OSLog+Categories.swift`
- Commit messages: short, plain-sentence, lowercase, imperative-ish (e.g., `add makefile to run build from command line`)
- App runs as menu bar only (`LSUIElement=true`), no Dock presence
