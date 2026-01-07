# Repository Guidelines

## Project Structure & Module Organization
- `App/` application entry points and main coordinator (`AppDelegate`).
- `StatusBar/`, `Palette/`, `Preferences/` UI for the menu bar, command palette, and settings.
- `Services/` core logic (hotkey capture, reminders API, notifications, settings store).
- `ViewModels/` SwiftUI view models; `Utilities/` shared helpers and logging.
- `Resources/` and `Info.plist` for assets and bundle configuration.
- `Tests/` XCTest targets (e.g., `Tests/DoublePressDetectorTests.swift`).
- `SlashRemindApp/` Xcode project assets are present, but active development targets the external Xcode project at `/Users/mauricelecordier/Documents/SlashRemindApp/` per `CLAUDE.md`.

## Build, Test, and Development Commands
- Xcode (preferred): open the external project and run the `SlashRemind` scheme (Xcode 15+, macOS 13+).
- Makefile (wraps Xcode): `make build`, `make run`, `make test`, `make release` (paths assume `../SlashRemindApp/SlashRemind/SlashRemind.xcodeproj`).
- SwiftPM (build/test only): `swift build`, `swift test`, `swift test --filter DoublePressDetectorTests`.
- Dependencies: `swift package resolve` or `swift package update`.
- Note: SPM builds but the app cannot run properly without a full app bundle.

## Coding Style & Naming Conventions
- Swift 6 strict concurrency patterns are in use: `@MainActor` for UI, `Sendable` protocols, `actor` for mock services.
- Indentation is 4 spaces; keep Swift standard formatting (no repo-wide formatter config).
- Naming: UpperCamelCase for types (`StatusBarController`), lowerCamelCase for properties/functions (`openPreferences`).
- Keep logging in `os.log` categories (`Utilities/OSLog+Categories.swift`).

## Testing Guidelines
- XCTest in `Tests/`, with filenames ending in `Tests.swift`.
- Focus on core logic (double-press detection, API behavior). Run `swift test` or `make test`.

## Commit & Pull Request Guidelines
- History uses short, plain-sentence subjects, often lower-case and imperative-ish (e.g., `add makefile to run build from command line`).
- Keep commit subjects concise and descriptive; avoid prefixes unless necessary.
- PRs: include a summary of behavior changes, link issues if relevant, and add screenshots/GIFs for UI tweaks.

## Security & Configuration Notes
- macOS 13+ only; global hotkey relies on Accessibility/Input Monitoring permissions.
- Notifications permission is requested when sync is enabled; test permission flows when changing related code.
