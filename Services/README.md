# Services

Core business logic isolated from UI concerns.

## Architecture

Services follow dependency injection via AppDelegate:

1. **HotKeyService**: System-level event capture requiring Accessibility permissions
2. **RemindersAPI**: Protocol-based HTTP abstraction for testability
3. **SettingsStore**: Observable UserDefaults wrapper
4. **NotificationScheduler**: Local notification integration
5. **DateParsingService**: Natural language date/time extraction using SoulverCore

All services are long-lived (created once in AppDelegate) and injected into UI components.

### Date Parsing Flow

```
User Input: "remind me to do washing tomorrow at 9am"
    |
    v
CommandPaletteView (SwiftUI TextField)
    |
    v
PaletteViewModel (@MainActor)
    |
    +---> DateParsingService.parseDate() --> Date?
    |
    v
RemindersAPI.createReminder(text, dueDate)
    |
    v
EventKitRemindersService
    |
    +---> EKReminder.title = text (unchanged)
    +---> EKReminder.dueDateComponents = Calendar.dateComponents(from: dueDate)
    +---> EKReminder.addAlarm(EKAlarm(absoluteDate: dueDate))
    |
    v
EKEventStore.save() --> macOS Reminders.app
```

**Data flow phases:**

1. **Input**: User types natural language in command palette, presses Enter
2. **Parsing**: `DateParsingService` wraps SoulverCore's `String.dateValue` to extract Date
3. **Time Defaulting**: SoulverCore returns noon (12:00 PM) for date-only inputs like "tomorrow" - parser detects this and converts to 9:00 AM
4. **Storage**: `EventKitRemindersService` converts Date to DateComponents and creates both due date and alarm
5. **Rejection**: If parsing returns nil, ViewModel displays error and blocks reminder creation

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

### Why Protocol-Based DateParsing

The `DateParsing` protocol abstracts SoulverCore implementation:
- **Testing**: `MockDateParser` enables isolated tests without SoulverCore dependency
- **Swappability**: Can replace SoulverCore with different library without changing ViewModel
- **Sendable Conformance**: Protocol can be `Sendable` while implementations manage thread-safety
- **Follows Pattern**: Matches existing `RemindersAPI` protocol-based architecture

### Why Both dueDateComponents and Alarm

EventKit requires both for complete UX:
- **dueDateComponents**: Displays due date prominently in Reminders app UI (year/month/day/hour/minute)
- **addAlarm**: Triggers notification at specified time
- Setting only alarm shows notification but due date isn't prominent in UI
- Setting only dueDateComponents shows date but no notification fires
- Both together provide full functionality: visual date display + timed notification

### Why 9:00 AM Default for Date-Only Inputs

SoulverCore returns noon (12:00 PM) for date-only text like "tomorrow" or "next Monday". The parser detects noon time (hour=12, minute=0, second=0) and converts to 9:00 AM:
- Common morning time for task reminders
- Matches user expectation that "tomorrow" means "tomorrow morning"
- Avoids midday interruption for date-only tasks
- User can specify different time explicitly ("tomorrow at 3pm" remains 3pm)

## Invariants

- **HotKeyService Lifecycle**: Must call `stop()` in `applicationWillTerminate` to clean up event tap and run loop source
- **API Base URL**: Must be valid URL; invalid URLs will crash at initialization (force-unwrap in AppDelegate)
- **Settings Keys**: UserDefaults keys must match between SettingsStore and any direct UserDefaults access
- **Thread Safety**: All UI updates from service callbacks must dispatch to MainActor explicitly
- **Date Parsing Purity**: `DateParsingService.parseDate()` is pure function - no side effects, same input returns same output (relative to current time)
- **Parsing Nil is Valid**: Nil return from parser indicates no date found, not an error condition - ViewModel handles this as validation failure
- **Parser Preserves Text**: Parser does not modify input text - original text becomes reminder title unchanged
- **EventKit Permission Check**: Must verify `defaultCalendarForNewReminders()` non-nil before saving (EventKit returns nil if no calendar exists)
- **Due Date Components**: When setting due date, both `dueDateComponents` AND alarm must be set together for complete UX
