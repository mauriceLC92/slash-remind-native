# Slash Remind Native

macOS menu bar app for creating reminders via command palette (double-press `/` hotkey).

## Files

| File | What | When to read |
| ---- | ---- | ------------ |
| `README.md` | Architecture, Swift 6 concurrency patterns, design decisions | Understanding project structure, adding features, debugging concurrency issues |
| `AGENTS.md` | Repository guidelines for AI assistants | Understanding project conventions, coding style, build commands |
| `Package.swift` | SPM package definition | Modifying dependencies, build targets, platform requirements |
| `Makefile` | Xcode build wrapper commands | Running build, test, release commands |

## Subdirectories

| Directory | What | When to read |
| --------- | ---- | ------------ |
| `App/` | Application entry point and AppDelegate | Modifying app lifecycle, service initialization, dependency wiring |
| `StatusBar/` | Menu bar UI controller | Changing menu bar appearance, adding menu items, handling menu actions |
| `Palette/` | Command palette window and double-press detection | Modifying palette UI, adjusting hotkey detection, changing window behavior |
| `Services/` | Core business logic (API, hotkeys, notifications, settings) | Adding services, modifying hotkey capture, changing API behavior, settings management |
| `ViewModels/` | SwiftUI view models | Modifying palette view logic, adding reactive properties |
| `Preferences/` | Settings/preferences UI | Changing preferences window, adding settings options |
| `Utilities/` | Shared utilities and logging | Adding logging categories, creating shared helpers |
| `Tests/` | XCTest unit tests | Adding tests, understanding test patterns, debugging test failures |
| `Resources/` | Assets and Info.plist | Modifying app icons, bundle configuration, asset management |
| `SlashRemindApp/` | Xcode project directory (not actively used) | - |

## Build

**Xcode (Primary)**:
```bash
make build          # Debug build
make run            # Build and launch
make test           # Run tests
make release        # Release build
```

**Swift Package Manager (verification only)**:
```bash
swift build         # Verify compilation
swift test          # Run unit tests
```

Note: SPM builds successfully but the app cannot run without proper Xcode app bundle structure. See README.md for SPM vs Xcode distinction.

## Test

```bash
swift test                                    # All tests
swift test --filter DoublePressDetectorTests  # Specific test
make test                                     # Via Xcode
```

## Development

- **Platform**: macOS 13+, Swift 6.1
- **Xcode Project**: `/Users/mauricelecordier/Documents/SlashRemindApp/` (required for running)
- **Permissions**: Accessibility (global hotkey), Notifications (when sync enabled)
- **Concurrency**: Swift 6 strict mode (`@MainActor`, `Sendable`, `actor`)
