# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status and Current State

**IMPORTANT**: This Swift Package Manager project has been **migrated to a proper Xcode project** located at `/Users/mauricelecordier/Documents/SlashRemindApp/`. The SPM version in this repository serves as the source of truth for code but **cannot run properly** due to macOS app bundle requirements.

### Why This Migration Happened
macOS apps using UserNotifications framework require proper app bundle structure with Info.plist files. Swift Package Manager cannot create these bundles, causing runtime errors: `bundleProxyForCurrentProcess is nil`.

## Build and Development Commands

### For Active Development (Xcode Project)
- **Primary Development**: Use the Xcode project at `/Users/mauricelecordier/Documents/SlashRemindApp/`
- **Build and Run**: Open project in Xcode 15+ and press ⌘+R
- **All functionality works**: Menu bar, global hotkey, notifications, preferences

### For Code Testing and Verification (SPM)
- **Build Only**: `swift build` - Verifies compilation but app cannot run
- **All Tests**: `swift test` - Unit tests work fine in SPM
- **Specific Test**: `swift test --filter DoublePressDetectorTests`

### Package Management
- **Resolve Dependencies**: `swift package resolve`  
- **Update Dependencies**: `swift package update`
- **Note**: SPM commands work for development but not runtime

## Architecture Overview

### Core Application Structure
- **App/AppDelegate.swift**: NSApplicationDelegate that coordinates all major services and UI components
- **SlashRemindApp.swift**: SwiftUI main app entry point (in Xcode project, not SPM)
- **Info.plist**: Proper app bundle configuration with `LSUIElement=true` for menu bar app

### Swift 6 Concurrency Architecture
The app has been fully updated for Swift 6 strict concurrency with these patterns:

1. **MainActor Isolation**: UI components properly isolated (`@MainActor` on StatusBarController, AppDelegate methods)
2. **Sendable Protocols**: `RemindersAPI` is `Sendable`, `MockRemindersAPI` is an `actor`
3. **Safe Callback Patterns**: HotKeyService uses `@Sendable` closures to prevent data races
4. **Modern SwiftUI**: TextField uses `onSubmit` instead of deprecated `onCommit`

### Key Architecture Patterns
1. **Dependency Injection**: Services are injected through the AppDelegate and passed to UI components
2. **Observable Objects**: Settings and ViewModels use `@Published` properties for reactive UI updates  
3. **Protocol-Based API**: `RemindersAPI` protocol allows for both HTTP and mock implementations
4. **Global Event Handling**: HotKeyService uses CGEvent tap for system-wide key capture

### Directory Structure
- **App/**: Application entry points and main coordinator
- **StatusBar/**: Menu bar UI and controller
- **Palette/**: Command palette window, view, and double-press detection logic
- **Services/**: Core business logic (API, hotkeys, notifications, settings)
- **ViewModels/**: SwiftUI view models following MVVM pattern
- **Preferences/**: Settings/preferences UI
- **Utilities/**: Shared utilities and logging categories
- **Tests/**: XCTest unit tests

### Key Services Integration
- **HotKeyService**: Manages global event tap with `@Sendable` callback integration to DoublePressDetector
- **RemindersAPI**: `Sendable` HTTP client with protocol abstraction (`MockRemindersAPI` as `actor`)
- **SettingsStore**: Observable UserDefaults wrapper for app configuration
- **NotificationScheduler**: Handles local notifications when sync is enabled

### Critical Components
- **DoublePressDetector**: Configurable key detection (default: `/` key, 0.3s threshold)
- **CommandPaletteWindowController**: `@MainActor` isolated window lifecycle and positioning
- **StatusBarController**: `@MainActor` isolated menu bar with explicit NSMenuItem targets

## Platform and Permissions

### Requirements
- **Platform**: macOS 13+ only (`#if os(macOS)` guards throughout)
- **Swift Tools Version**: 6.1
- **Input Monitoring**: Required for global hotkey (prompts user for accessibility permissions)
- **Notifications**: Requested when sync is enabled

### Key Implementation Details
- Uses `CGEvent.tapCreate` for global key capture requiring accessibility permissions
- Menu bar app with no dock presence
- SwiftUI for preferences, AppKit for core functionality
- Logging via `os.log` with custom categories (see Utilities/OSLog+Categories.swift)

## Testing Strategy
- Unit tests focus on core logic: `DoublePressDetector` and `RemindersAPI`  
- Tests use XCTest framework with `@testable import SlashRemind`
- Mock implementations available for API testing (MockRemindersAPI)