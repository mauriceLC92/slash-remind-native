# Repository Guidelines

## Project Structure & Module Organization

SlashRemind is a native macOS menu bar app built from `SlashRemind.xcodeproj`; the Xcode project is the source of truth. App startup lives in `SlashRemindApp.swift` and `App/AppDelegate.swift`. UI code is grouped by feature: `Palette/` for the command palette, `StatusBar/` for the menu bar controller, and `Preferences/` for settings UI. Core behavior lives in `Services/`, shared view state in `ViewModels/`, logging helpers in `Utilities/`, and app resources in `Resources/Assets.xcassets`. Unit tests are in `SlashRemindTests/`; UI tests are in `SlashRemindUITests/`.

## Build, Test, and Development Commands

Use the Makefile shortcuts for local work:

```bash
make build    # Build Debug configuration with xcodebuild
make run      # Build and launch the newest Debug app bundle
make test     # Run the XCTest suite
make release  # Build Release configuration
make clean    # Clean Xcode build artifacts
```

There is no Swift Package Manager build path in this repository.

## Coding Style & Naming Conventions

Write Swift 6.1 targeting macOS 13+. Use 4-space indentation and standard Swift names: `UpperCamelCase` for types and `lowerCamelCase` for methods, properties, and locals. Keep UI-bound types and methods on `@MainActor` where appropriate. Prefer constructor injection and protocol-backed services, matching existing patterns such as `RemindersAPI`, date parsing, and notification scheduling. Use `os_log` categories from `Utilities/OSLog+Categories.swift` for logging.

## Testing Guidelines

Tests use XCTest. Add focused unit tests under `SlashRemindTests/` for service, parser, and view-model behavior; use `*Tests.swift` filenames and descriptive `test...` method names. Put UI flow coverage in `SlashRemindUITests/` only when behavior cannot be covered at the unit level. Run `make test` before opening a pull request.

## Commit & Pull Request Guidelines

Recent commits use short, lowercase, plain-language subjects such as `fix double running of builds` and `add makefile to run build from command line`. Keep commits scoped to one logical change. Pull requests should include a brief description, the commands run for verification, linked issues if applicable, and screenshots or screen recordings for visible UI changes.

## Security & Configuration Tips

The app creates native Apple Reminders through EventKit, so avoid logging reminder contents beyond what is needed for debugging. Keep entitlements and plist changes in `SlashRemind/` and root `Info.plist` intentional and document any permission-impacting changes in the PR.
