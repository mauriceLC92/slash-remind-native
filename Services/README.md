# Services

Core business logic isolated from UI concerns.

## Architecture

Services follow dependency injection via AppDelegate:

1. **HotKeyService**: System-level event capture requiring Accessibility permissions
2. **RemindersAPI**: Protocol-based HTTP abstraction for testability
3. **SettingsStore**: Observable UserDefaults wrapper
4. **NotificationScheduler**: Local notification integration

All services are long-lived (created once in AppDelegate) and injected into UI components.

## Design Decisions

### Why CGEvent Tap Over NSEvent

`NSEvent.addGlobalMonitorForEvents` cannot capture events in the current application, only in other apps. `CGEvent.tapCreate` with `.cgSessionEventTap` provides true global capture.

Using `.listenOnly` option means the tap doesn't modify or suppress events - the `/` key still functions normally in other applications.

### Why Protocol-Based RemindersAPI

The `RemindersAPI` protocol abstracts HTTP implementation:
- **Testing**: `MockRemindersAPI` as `actor` enables isolated tests without network
- **Sendable Conformance**: Protocol can be `Sendable` while implementations manage their own thread-safety
- **Future Flexibility**: Easy to swap HTTP backend for local database or different API

### Why Sendable Callbacks in HotKeyService

CGEvent callback executes on arbitrary thread. The callback must be `@Sendable` and explicitly dispatch to `@MainActor` via `Task { @MainActor in ... }` to safely interact with UI components. This satisfies Swift 6 strict concurrency.

### Why Observable SettingsStore

Using `@Published` properties makes settings reactively update UI. Changes to `baseURL` or `syncEnabled` automatically propagate to all observing views without manual notification wiring.

## Invariants

- **HotKeyService Lifecycle**: Must call `stop()` in `applicationWillTerminate` to clean up event tap and run loop source
- **API Base URL**: Must be valid URL; invalid URLs will crash at initialization (force-unwrap in AppDelegate)
- **Settings Keys**: UserDefaults keys must match between SettingsStore and any direct UserDefaults access
- **Thread Safety**: All UI updates from service callbacks must dispatch to MainActor explicitly
