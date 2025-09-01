# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Slash Remind Native is a macOS menu bar utility that provides a Spotlight-style command palette for creating reminders via a backend API. The app uses a global hotkey (double-press `/`) to show the command palette from anywhere on macOS.

## Build and Development Commands

### Building
- **Xcode**: Open in Xcode 15+ and run the `SlashRemind` scheme
- **Command Line**: `swift build` - Build the package
- **Release Build**: `swift build -c release`

### Testing  
- **All Tests**: `swift test`
- **Specific Test**: `swift test --filter DoublePressDetectorTests`
- **Tests require**: macOS 13+ target platform

### Package Management
- **Resolve Dependencies**: `swift package resolve`
- **Update Dependencies**: `swift package update`
- **Generate Xcode Project**: `swift package generate-xcodeproj` (if needed)

## Architecture Overview

### Core Application Structure
- **App/SpotlightRemindersApp.swift**: SwiftUI main app entry point with Settings scene
- **App/AppDelegate.swift**: NSApplicationDelegate that coordinates all major services and UI components

### Key Architecture Patterns
The app follows a service-oriented architecture with clear separation of concerns:

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
- **HotKeyService**: Manages global event tap and integrates with DoublePressDetector
- **RemindersAPI**: HTTP client for backend communication with protocol abstraction
- **SettingsStore**: Observable UserDefaults wrapper for app configuration
- **NotificationScheduler**: Handles local notifications when sync is enabled

### Critical Components
- **DoublePressDetector**: Configurable key detection (default: `/` key, 0.3s threshold)
- **CommandPaletteWindowController**: Manages the popup window lifecycle and positioning
- **StatusBarController**: Coordinates menu bar presence with palette controller

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