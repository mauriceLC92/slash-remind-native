# Repository Guidelines

## Project Structure & Module Organization
This repository is the Swift Package source of truth for SlashRemind (macOS 13+, Swift 6.1).

- `App/`: app lifecycle and dependency wiring (`AppDelegate`)
- `StatusBar/`: menu bar controller and menu actions
- `Palette/`: command palette UI, window controller, double-press detector
- `Services/`: API, hotkey capture, notifications, settings
- `ViewModels/`: SwiftUI-facing state and command handling
- `Preferences/`: preferences window and settings UI
- `Utilities/`: shared helpers and logging categories
- `Tests/`: XCTest unit tests
- `Resources/`: plist and assets

## Build, Test, and Development Commands
- `swift build`: compile package targets.
- `swift test`: run all XCTest suites in `Tests/`.
- `swift test --filter DateParsingServiceTests`: run a single suite.
- `make build`: Debug build via `xcodebuild` (external Xcode project path in `Makefile`).
- `make test`: run tests through Xcode build tooling.
- `make run`: build and open the app bundle.

Use `swift build`/`swift test` for fast validation; use `make` targets for app-bundle workflows.

## Coding Style & Naming Conventions
- Follow existing Swift style: 4-space indentation, concise methods, small focused types.
- Naming: `PascalCase` for types, `lowerCamelCase` for vars/functions, `test...` for test methods.
- Keep UI-facing code `@MainActor` where appropriate.
- Preserve Swift 6 concurrency safety (`Sendable`, actors, safe async boundaries).
- No formatter/linter is configured here; match surrounding file style exactly.

## Testing Guidelines
- Framework: XCTest (`@testable import SlashRemind`).
- Place tests in `Tests/` with filename pattern `*Tests.swift`.
- Prefer deterministic unit tests; mock services instead of real network/event-tap behavior.
- For behavior changes, add happy-path and invalid-input coverage before opening a PR.

## Commit & Pull Request Guidelines
- Current history uses short, task-focused subjects (for example: `add makefile...`, `Initial ...`).
- Keep commit subjects imperative and specific; one logical change per commit.
- PRs should include what changed and why, commands run (`swift test`, `make build`, etc.), screenshots/video for menu bar or palette UI changes, and linked issues/tasks when applicable.

## Security & Configuration Tips
- Do not commit secrets, API tokens, or machine-specific credentials.
- If changing permissions-related behavior (Accessibility/Notifications), update `Info.plist` and document manual verification steps.
