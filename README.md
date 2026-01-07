# Slash Remind Native

A native macOS menu bar utility that exposes a Spotlight-style command palette to create reminders via a backend API.

## Overview

This Swift Package Manager project serves as the source of truth for code but has been migrated to a proper Xcode project at `/Users/mauricelecordier/Documents/SlashRemindApp/` for runtime execution. The SPM version can build and test but cannot run due to macOS app bundle requirements.

## Architecture

### SPM vs Xcode Project Distinction

macOS apps using the UserNotifications framework require proper app bundle structure with Info.plist files. Swift Package Manager cannot create these bundles, causing runtime errors (`bundleProxyForCurrentProcess is nil`). Therefore:

- **This repository (SPM)**: Source of truth for code, runs tests, verifies compilation
- **Xcode project**: Required for running the app with proper bundle structure

### Core Application Structure

The app uses dependency injection coordinated through AppDelegate:

1. **AppDelegate** (App/AppDelegate.swift): NSApplicationDelegate that initializes and wires all services
2. **Services**: Core business logic injected into UI components
3. **UI Components**: StatusBar, CommandPalette, and Preferences receive service dependencies
4. **ViewModels**: Bridge between services and SwiftUI views

### Swift 6 Concurrency Patterns

The codebase enforces Swift 6 strict concurrency:

- **MainActor Isolation**: UI components (`StatusBarController`, `CommandPaletteWindowController`, AppDelegate UI methods) use `@MainActor`
- **Sendable Protocols**: `RemindersAPI` is `Sendable` to allow safe cross-concurrency sharing
- **Actor-Based Mocks**: `MockRemindersAPI` is an `actor` for thread-safe test isolation
- **Safe Callbacks**: HotKeyService uses `@Sendable` closures with `Task { @MainActor in ... }` to safely bridge CGEvent callbacks to UI updates

### Key Architecture Patterns

1. **Dependency Injection**: Services created in AppDelegate and passed to UI components, enabling testability
2. **Observable Objects**: `SettingsStore` and ViewModels use `@Published` for reactive UI
3. **Protocol-Based API**: `RemindersAPI` protocol allows HTTP and mock implementations
4. **Global Event Handling**: `HotKeyService` uses `CGEvent.tapCreate` for system-wide key capture

### Critical Components

- **DoublePressDetector** (Palette/): Detects double-press of `/` key (default: 0.3s threshold) using `DispatchTime` for precise timing
- **HotKeyService** (Services/): Creates CGEvent tap requiring Accessibility permissions, uses `Unmanaged` pointer to bridge C callbacks to Swift
- **CommandPaletteWindowController** (Palette/): Manages window lifecycle with `@MainActor` isolation for positioning and visibility
- **StatusBarController** (StatusBar/): `@MainActor` isolated menu bar with explicit NSMenuItem targets to satisfy Swift 6 concurrency

## Platform and Permissions

### Requirements

- **Platform**: macOS 13+ only (enforced via `#if os(macOS)` guards)
- **Swift Tools Version**: 6.1
- **Input Monitoring**: Required for global hotkey (prompts user for Accessibility permissions)
- **Notifications**: Requested when sync is enabled

### Permission Handling

- **Accessibility**: CGEvent tap creation fails without Input Monitoring permission, requiring user grant in System Settings
- **Notifications**: `UNUserNotificationCenter.requestAuthorization` called in `applicationDidFinishLaunching` only when `settings.syncEnabled` is true
- **No Dock Presence**: App runs as menu bar only (`LSUIElement=true` in Info.plist)

## Design Decisions

### Why Protocol-Based API

The `RemindersAPI` protocol abstracts HTTP details, enabling:
- Mock implementations for testing without network calls
- Future flexibility to swap backends (e.g., local database, different API)
- Sendable conformance for safe concurrency

### Why CGEvent Tap Over NSEvent

`NSEvent.addGlobalMonitorForEvents` only captures events for other applications, not the current one. `CGEvent.tapCreate` with `.listenOnly` provides true global capture without interfering with normal event processing.

### Why Separate DoublePressDetector

Extracting double-press logic into a standalone class:
- Enables unit testing without CGEvent infrastructure
- Allows configurable key codes and thresholds
- Simplifies HotKeyService to focus on event tap lifecycle

### Why Dependency Injection Through AppDelegate

Services must outlive individual UI components (menu bar persists while palette shows/hides). AppDelegate provides a natural singleton-like lifecycle while maintaining testability through constructor injection.

## Testing Strategy

- **Unit tests** focus on pure logic: `DoublePressDetector` (timing windows) and `RemindersAPI` (mock responses)
- **XCTest framework** with `@testable import SlashRemind`
- **No UI tests**: CGEvent taps and menu bars are difficult to test; integration testing done manually
- Tests run in SPM without Xcode project dependency

## Hotkey

Press `/` twice quickly to reveal the command palette from anywhere on macOS. Type a reminder and hit Return to send it to the configured backend.
