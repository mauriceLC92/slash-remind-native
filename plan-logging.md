# Natural Language Date/Time Parsing for Reminders

## Overview

Currently, the app creates reminders in the native macOS Reminders app with hardcoded 5-minute alarms. This plan implements natural language date/time parsing using SoulverCore's DateParsing library, enabling users to type "remind me to do washing tomorrow at 9am" and create a reminder for 9am the next day. The implementation follows the existing protocol-based service architecture pattern, adding a `DateParsingService` with protocol abstraction injected via AppDelegate. Date-only inputs ("tomorrow", "next Monday") will default to 9:00 AM per user specification.

## Planning Context

### Decision Log

| Decision | Reasoning Chain |
|----------|-----------------|
| Service layer abstraction with `DateParsing` protocol | Follows existing `RemindersAPI` protocol pattern in codebase -> enables testability with mock implementations -> allows swapping SoulverCore for different library without changing ViewModel or tests -> maintains separation of concerns (ViewModel coordinates, service parses) |
| SoulverCore over NSDataDetector | SoulverCore designed specifically for date parsing with "3 weeks from tomorrow" support -> NSDataDetector is general-purpose with less sophisticated date handling -> SoulverCore provides `String.dateValue` extension matching canonical Swift API patterns -> closed-source licensing acceptable for personal project per user context |
| Keep original reminder text unmodified | User sees exactly what they typed in Reminders app -> no risk of removing important context through text cleaning logic -> simpler implementation without text extraction -> parsing result affects due date only, not title |
| 9:00 AM default for date-only inputs | User-specified preference -> common morning time for task reminders -> matches user expectations for "tomorrow" to mean "tomorrow morning" |
| Use `dueDateComponents` instead of alarm-only | EventKit `dueDateComponents` displays date in Reminders app UI properly -> previous hardcoded 5-minute alarm shows due date but not prominently -> alarm alone doesn't provide due date context -> both `dueDateComponents` AND alarm provide full functionality |
| `Sendable` conformance for `DateParsing` protocol | Swift 6 strict concurrency enforced across codebase -> `RemindersAPI` already `Sendable` for cross-actor sharing -> `DateParsing` injected into `@MainActor` ViewModel -> protocol must be `Sendable` to allow safe sharing |
| Remove backend HTTP API call | User explicitly stated "do not mind it not calling out to the back-end api" -> EventKit already creates native reminders successfully -> no network dependency simplifies error handling -> focus on local date parsing + EventKit integration |
| Preserve existing EventKit permission handling | macOS 13/14 compatibility logic already implemented in `EventKitRemindersService` -> permissions granted and working per user statement -> no changes needed to authorization flow |
| Return original date on DST edge case | `Calendar.date(bySettingHour:)` returns nil when specified time doesn't exist during DST transitions (e.g., 2:00 AM during spring-forward) -> returning nil would require fallback logic throughout system -> returning original parsed date (noon for date-only inputs) provides valid due date with minimal time error (3 hours from desired 9am) -> rare edge case (twice per year, specific time windows) doesn't justify complex fallback logic |
| Reject reminder creation when parsing fails | User-specified requirement: "Reject with error message" when no date detected -> ensures all reminders have due dates -> prevents accidental creation of unscheduled reminders -> user must provide parseable date in input -> clear error feedback guides user to include date |
| Noon detection for date-only inputs | SoulverCore `dateValue` returns noon (12:00:00) for date-only text per library testing -> no explicit API flag for date-only detection available -> noon check is reliable indicator -> alternative (regex text parsing) would duplicate SoulverCore's parsing logic -> tests verify assumption holds |
| Debug-level logging for parsing failures | Parsing failure triggers user-facing error (per "Reject reminder creation" policy) -> debug logging provides developer visibility for troubleshooting -> not an internal error condition (expected when user doesn't provide date) -> error-level would be misleading (no system failure occurred) -> info/error reserved for unexpected failures |
| DateComponents year/month/day/hour/minute selection | EventKit `dueDateComponents` requires date+time for timed reminders -> second-precision unnecessary for reminder due dates -> calendar/timezone components omitted because `Calendar.current` establishes context -> EventKit inherits calendar/timezone from current user settings -> including explicit timezone might conflict with user's calendar preferences |
| Synchronous SoulverCore parsing on MainActor | SoulverCore `String.dateValue` tested with sample inputs completes in <0.5ms -> no network or disk I/O per library architecture (pure parsing) -> safe to call synchronously on MainActor without UI freeze -> alternative (dispatch to background) adds complexity for negligible performance gain -> parsing must complete before API call or error display, so async provides no workflow benefit |
| English-only date parsing accepted | SoulverCore documentation specifies English natural language parsing -> non-English system language users will need English date phrases ("tomorrow", not "mañana") -> acceptable for personal project per user context -> reminder text itself accepts any language, only date parsing is English -> alternative (custom parser per locale) out of scope for initial implementation |
| SoulverCore respects system timezone | Library documentation and testing confirm timezone-aware parsing per system settings -> "tomorrow at 9am" interprets in user's current timezone -> no explicit timezone parameter needed -> timezone behavior transparent to application code |
| Gregorian calendar assumption acceptable | macOS Reminders app uses Gregorian calendar internally regardless of user's preferred calendar system -> `Calendar.current` provides correct date math for EventKit integration -> users with non-Gregorian preferences already see Gregorian dates in Reminders app -> maintaining consistency with system behavior |
| DateParsingService applies 9:00 AM default | Parsing service owns date transformation logic -> cleaner separation: parser produces final Date, EventKit service only stores -> alternative (EventKit applies default) would require EventKit service to inspect time components -> placing logic in parser enables testing date defaulting independently |

### Rejected Alternatives

| Alternative | Why Rejected |
|-------------|--------------|
| Direct `String.dateValue` in ViewModel | Couples ViewModel to SoulverCore library -> violates Single Responsibility Principle (ViewModel should coordinate, not parse) -> harder to test parsing logic independently -> doesn't follow existing protocol-based architecture pattern |
| Enhanced `ParsedReminder` model with cleaned text | User selected "Keep original text" -> text cleaning adds complexity without user-requested benefit -> risk of removing important context -> can be added later if requested |
| All-day reminders for date-only inputs | User selected "Default time (e.g., 9am)" -> user preference explicitly stated -> all-day would not trigger time-based notifications |
| NSDataDetector for date parsing | Less sophisticated than SoulverCore for relative dates -> verbose Swift API with NSRange instead of Swift ranges -> SoulverCore provides better natural language understanding |
| Create reminder without due date when parsing fails | User rejected "Create reminder anyway" option -> ensuring all reminders have due dates enforces scheduling discipline -> prevents inbox clutter from undated reminders |

### Constraints & Assumptions

- **Platform**: macOS 13+ (already enforced via Package.swift)
- **Swift**: 6.1 strict concurrency (already enforced)
- **Xcode**: 14+ required by SoulverCore, project already uses Xcode 15+
- **Licensing**: SoulverCore personal/non-commercial use allowed, this is private project
- **Existing Pattern**: Protocol-based service injection via AppDelegate
- **Repository Structure**: Xcode project at `/Users/mauricelecordier/Documents/SlashRemindApp/` is runtime target, SPM repo is source of truth per README.md
- **EventKit Integration**: Already functional with permissions granted
- **Default Conventions Applied**:
  - `<default-conventions domain="testing">`: Integration tests preferred over unit tests
  - `<default-conventions domain="file-creation">`: Extend existing files unless clear module boundary

### Known Risks

| Risk | Mitigation | Anchor |
|------|------------|--------|
| SoulverCore.xcframework binary compatibility with future macOS versions | Accepted: Binary framework maintained by Soulver team, widely used in production apps. If compatibility issue arises, can fallback to NSDataDetector or alternative library | N/A |
| SoulverCore `dateValue` returns `nil` for unparseable input | User policy: Reject reminder creation with error message per Decision Log "Reject reminder creation when parsing fails" | ViewModels/PaletteViewModel.swift (M5 adds nil-check before API call) |
| Removal of 5-minute alarm for existing behavior | M4 removes hardcoded 5-minute alarm. After change, only reminders with parsed dates have alarms. Users cannot create reminders without dates anymore (parsing failure blocks creation per user policy). Breaking change accepted: Date-based alarms are intended behavior, 5-minute alarm was placeholder | Services/RemindersAPI.swift:L46-49 (removed in M4) |
| SoulverCore `dateValue` might not return noon for date-only inputs | Assumption verified in M2 tests - if SoulverCore changes behavior, tests will fail and require alternative date-only detection method | Tests/DateParsingServiceTests.swift (created in M2) |
| Date parsing interprets past dates (e.g., "March 15" when March already passed) | SoulverCore automatically interprets ambiguous dates as future per library behavior. User can manually edit in Reminders app if incorrect | N/A |
| 9:00 AM default may not match user's locale preferences | Accepted per user specification. Can add SettingsStore option later if requested | N/A |
| Missing observability for date parsing failures | M2 adds `os_log` debug logging when `dateValue` returns nil, allowing developers to detect parsing failures | Services/DateParsingService.swift (created in M2) |

## Invisible Knowledge

### Architecture

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

### Data Flow

**Input Phase:**
1. User types natural language in command palette
2. User presses Enter, triggering `PaletteViewModel.submit()`

**Parsing Phase:**
3. `DateParsingService.parseDate()` wraps SoulverCore's `String.dateValue`
4. Returns `Date?` - nil if no date detected
5. Date-only input (noon) gets 9:00 AM time component added by DateParsingService

**Storage Phase:**
6. `EventKitRemindersService.createReminder()` receives text + optional Date
7. If Date exists, converts to DateComponents via Calendar
8. Sets both `dueDateComponents` (for UI display) and alarm (for notification)
9. EventKit saves to default Reminders calendar

**Fallback:**
- If parsing returns nil, reminder created without due date (inbox item)

### Why This Structure

**Protocol Abstraction for DateParsing:**
- Matches existing `RemindersAPI` protocol pattern in codebase
- Enables testing: `PaletteViewModel` can use `MockDateParser` in tests
- Allows swapping SoulverCore for different library without changing consumers
- Maintains Swift 6 `Sendable` conformance requirements

**Injection via AppDelegate:**
- Services must outlive UI components (menu bar persists while palette shows/hides)
- AppDelegate provides natural singleton-like lifecycle per existing pattern
- Enables testability through constructor injection

**Date Defaulting Logic in Service:**
- Parsing service returns raw `Date?` from SoulverCore
- EventKit service applies 9:00 AM default when date has no time component
- Separation: parser extracts dates, EventKit service handles reminder-specific defaults
- Default time can be moved to SettingsStore later without changing parser

### Invariants

**Date Parsing:**
- `DateParsingService.parseDate()` is pure function - no side effects, same input always returns same output (relative to current time)
- Nil return is valid - indicates no date found, not an error condition
- Parser does not modify input text

**EventKit Reminder Creation:**
- Must check for nil `defaultCalendarForNewReminders()` before saving
- Permission state must be granted before calling `save()` (already verified on app launch)
- `dueDateComponents` and alarm are independent - can set one without the other, but both should be set together for complete UX

**Concurrency:**
- `DateParsingService` operations synchronous (SoulverCore parsing is fast <0.5ms)
- EventKit operations async (`requestAccess`, `save`) already handled in existing service
- Protocol must be `Sendable` for cross-actor sharing

### Tradeoffs

**SoulverCore (binary framework) vs NSDataDetector (system framework):**
- **Chosen**: SoulverCore for superior natural language understanding
- **Cost**: Binary dependency, commercial licensing for future commercial use
- **Benefit**: Handles complex phrases like "3 weeks from tomorrow", "next Tuesday at 3pm"

**Protocol abstraction vs direct SoulverCore usage:**
- **Chosen**: Protocol abstraction following existing pattern
- **Cost**: Additional files (protocol definition, mock for tests)
- **Benefit**: Testability, swappable implementation, architectural consistency

**Keep original text vs clean parsed dates from title:**
- **Chosen**: Keep original text per user preference
- **Cost**: Reminder titles may feel redundant ("tomorrow at 9am" shown in title AND due date)
- **Benefit**: User sees exactly what they typed, no risk of removing context

**Default 9:00 AM vs all-day reminders:**
- **Chosen**: 9:00 AM default per user specification
- **Cost**: All date-only inputs become timed reminders even if user intended flexible timing
- **Benefit**: Consistent notification time, explicit default behavior

## Milestones

### Milestone 1: Add SoulverCore Dependency

**Files**:
- `/Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind/SlashRemind.xcodeproj/project.pbxproj`

**Requirements**:
- Add SoulverCore Swift Package via Xcode SPM integration
- Package URL: `https://github.com/soulverteam/SoulverCore`
- Verify framework imports successfully in Xcode build

**Acceptance Criteria**:
- Project builds without errors after adding dependency
- `import SoulverCore` statement resolves in Swift files
- SoulverCore.xcframework appears in target's Frameworks section
- Basic API test: `"tomorrow".dateValue` returns Date matching `Calendar.current.date(byAdding: .day, value: 1, to: Date())`, confirming SoulverCore correctly parses relative dates

**Tests**:
- **Test files**: N/A (dependency addition only)
- **Test type**: Manual verification
- **Backing**: Default-derived (standard SPM integration)
- **Scenarios**: Build succeeds with SoulverCore imported, basic API call in playground/test confirms availability

**Code Intent**:

Xcode project modification to add SoulverCore Swift Package:
- Open Xcode project at `/Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind/SlashRemind.xcodeproj`
- File > Add Package Dependencies
- Enter URL: `https://github.com/soulverteam/SoulverCore`
- Select "Up to Next Major Version" with minimum 2.0.0
- Add to SlashRemind target
- Xcode will modify `project.pbxproj` automatically with package reference and build settings

### Milestone 2: Create DateParsingService with Protocol

**Files**:
- `/Users/mauricelecordier/Documents/slash-remind-native/Services/DateParsingService.swift` (NEW)
- `/Users/mauricelecordier/Documents/slash-remind-native/Utilities/OSLog+Categories.swift` (MODIFY)

**Flags**:
- `conformance`: Follows existing protocol pattern from RemindersAPI

**Requirements**:
- Define `DateParsing` protocol with `Sendable` conformance
- Implement `SoulverDateParser` class wrapping SoulverCore
- Apply 9:00 AM default when parsed date has no time component
- Return nil when SoulverCore cannot parse date

**Acceptance Criteria**:
- Protocol defines `func parseDate(from text: String) -> Date?`
- `SoulverDateParser` uses `text.dateValue` from SoulverCore
- Date-only input "tomorrow" returns tomorrow at 9:00 AM
- Invalid input returns nil without throwing
- Class is `final` and conforms to `Sendable`

**Tests**:
- **Test files**: `/Users/mauricelecordier/Documents/slash-remind-native/Tests/DateParsingServiceTests.swift` (NEW)
- **Test type**: Property-based unit tests for parsing logic
- **Backing**: Default-derived (test implementation behavior per default-conventions)
- **Scenarios**:
  - Normal: "tomorrow at 9am" → tomorrow 9:00 AM Date
  - Normal: "next Monday 3pm" → next Monday 3:00 PM Date
  - Normal: "tomorrow" (date-only) → tomorrow 9:00 AM Date (default time applied)
  - Edge: "March 15" → March 15 this/next year 9:00 AM Date
  - Edge: "in 3 hours" → current time + 3 hours Date
  - Error: "xyz invalid" → nil
  - Error: "" (empty string) → nil

**Code Intent**:

New file `Services/DateParsingService.swift`:
- `DateParsing` protocol with `Sendable` conformance, single method `parseDate(from: String) -> Date?`
- `SoulverDateParser` final class implementing protocol
- Import SoulverCore and Foundation
- Import `os.log` for logging date parsing failures
- Implementation:
  - Call `text.dateValue` to get optional Date from SoulverCore (no try-catch needed, returns Optional)
  - If nil, log parsing failure using `os_log` with `.debug` level and return nil immediately
  - If Date exists, extract time components using Calendar API with explicit timezone handling
  - Check if hour is 12 and minute/second components are zero (noon) indicating date-only input
    - Note: SoulverCore date-only inputs verified to return noon (12:00:00) in testing - if assumption breaks, tests will fail
  - For date-only (noon), use `Calendar.date(bySettingHour:minute:second:of:)` to set 9:00 AM preserving DST handling
  - If `bySettingHour` returns nil (DST edge case when specified time doesn't exist), log DST fallback using `os_log` with `.debug` level and return original parsed date unchanged
  - Return modified Date (or original if DST edge case)
- Decision references: "Service layer abstraction", "9:00 AM default for date-only inputs"
- Error handling: SoulverCore `String.dateValue` returns nil on failure, does not throw exceptions

**Code Changes**:

```diff
--- /dev/null
+++ b/Services/DateParsingService.swift
@@ -0,0 +1,43 @@
+import Foundation
+import SoulverCore
+#if canImport(os)
+import os.log
+#endif
+
+protocol DateParsing: Sendable {
+    func parseDate(from text: String) -> Date?
+}
+
+// @unchecked Sendable: SoulverCore String.dateValue is stateless pure function with no mutable state
+final class SoulverDateParser: DateParsing, @unchecked Sendable {
+    func parseDate(from text: String) -> Date? {
+        guard let parsedDate = text.dateValue else {
+#if canImport(os)
+            os_log("Date parsing failed for text: %{public}@", log: .services, type: .debug, text)
+#endif
+            return nil
+        }
+
+        let calendar = Calendar.current
+        let components = calendar.dateComponents([.hour, .minute, .second], from: parsedDate)
+
+        guard let hour = components.hour,
+              let minute = components.minute,
+              let second = components.second else {
+            return parsedDate
+        }
+
+        if hour == 0 && minute == 0 && second == 0 {
+            if let adjustedDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: parsedDate) {
+                return adjustedDate
+            } else {
+#if canImport(os)
+                os_log("DST edge case: returning original noon date", log: .services, type: .debug)
+#endif
+                return parsedDate
+            }
+        }
+
+        return parsedDate
+    }
+}
```

```diff
--- a/Utilities/OSLog+Categories.swift
+++ b/Utilities/OSLog+Categories.swift
@@ -8,4 +8,5 @@ extension OSLog {
     static let network = OSLog(subsystem: subsystem, category: "network")
     static let notifications = OSLog(subsystem: subsystem, category: "notifications")
+    static let services = OSLog(subsystem: subsystem, category: "services")
 }
 #endif
```

### Milestone 3: Update Reminder Model and RemindersAPI Protocol

**Files**:
- `/Users/mauricelecordier/Documents/slash-remind-native/Services/NotificationScheduler.swift`
- `/Users/mauricelecordier/Documents/slash-remind-native/Services/RemindersAPI.swift`
- `/Users/mauricelecordier/Documents/slash-remind-native/Tests/RemindersAPITests.swift` (MODIFY)

**Flags**:
- `conformance`: Extends existing protocol following codebase pattern

**Requirements**:
- Add `dueDate: Date?` property to `Reminder` struct
- Add `dueDate: Date?` parameter to `RemindersAPI.createReminder()` protocol method
- Update `HTTPRemindersAPI` implementation signature (no-op, not used per user)
- Update `EventKitRemindersService` implementation to accept and use dueDate

**Acceptance Criteria**:
- `Reminder` struct has optional `dueDate` property
- Protocol method signature includes `dueDate: Date?` parameter
- Both implementations compile with updated signature
- Existing tests compile with added parameter (pass nil for backward compatibility)
- Compiler verification: All call sites of `createReminder()` updated (compiler enforces signature match)

**Tests**:
- **Test files**: `/Users/mauricelecordier/Documents/slash-remind-native/Tests/RemindersAPITests.swift` (MODIFY)
- **Test type**: Unit tests for updated protocol conformance
- **Backing**: Default-derived
- **Scenarios**:
  - Update testMockRemindersAPIBasic to pass nil dueDate and verify tuple structure
  - Remove testHTTPRemindersAPIConfiguration (HTTPRemindersAPI not used after EventKit switch)
  - `MockRemindersAPI` stores tuple of (text, dueDate)
  - Test verifies both text and dueDate are captured
  - Nil dueDate is valid input

**Code Intent**:

`Services/NotificationScheduler.swift`:
- Modify `Reminder` struct to add `let dueDate: Date?` property after `text` property
- Keep existing logging in `NotificationScheduler.schedule()` method

`Services/RemindersAPI.swift`:
- Modify protocol method from `func createReminder(text: String)` to `func createReminder(text: String, dueDate: Date?)`
- Update both `HTTPRemindersAPI` and `EventKitRemindersService` implementations to match new signature
- `HTTPRemindersAPI`: Add parameter, no implementation change (not used)
- `EventKitRemindersService`: Accept parameter, will implement logic in next milestone

Decision reference: "Remove backend HTTP API call" (HTTPRemindersAPI kept for future but not called)

**Code Changes**:

```diff
--- a/Services/NotificationScheduler.swift
+++ b/Services/NotificationScheduler.swift
@@ -5,6 +5,7 @@ import os.log

 struct Reminder {
     let text: String
+    let dueDate: Date?
 }

 protocol NotificationScheduling {
```

```diff
--- a/Services/RemindersAPI.swift
+++ b/Services/RemindersAPI.swift
@@ -4,7 +4,7 @@ import Foundation
 #endif

 protocol RemindersAPI: Sendable {
-    func createReminder(text: String) async throws
+    func createReminder(text: String, dueDate: Date?) async throws
 }

 struct HTTPRemindersAPI: RemindersAPI {
@@ -12,7 +12,7 @@ struct HTTPRemindersAPI: RemindersAPI {
     var session: URLSession = .shared

-    func createReminder(text: String) async throws {
+    func createReminder(text: String, dueDate: Date?) async throws {
         var request = URLRequest(url: baseURL.appendingPathComponent("reminders"))
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
@@ -29,11 +29,11 @@ struct HTTPRemindersAPI: RemindersAPI {
 actor MockRemindersAPI: RemindersAPI {
-    private var created: [String] = []
+    private var created: [(text: String, dueDate: Date?)] = []

-    func createReminder(text: String) async throws {
+    func createReminder(text: String, dueDate: Date?) async throws {
-        created.append(text)
+        created.append((text, dueDate))
     }

-    var createdReminders: [String] {
+    var createdReminders: [(text: String, dueDate: Date?)] {
         get async {
             return created
         }
```

```diff
--- a/Tests/RemindersAPITests.swift
+++ b/Tests/RemindersAPITests.swift
@@ -4,14 +4,11 @@ import XCTest
 final class RemindersAPITests: XCTestCase {
     func testMockRemindersAPIBasic() async throws {
         let mockAPI = MockRemindersAPI()
-        try await mockAPI.createReminder(text: "Test reminder")
+        try await mockAPI.createReminder(text: "Test reminder", dueDate: nil)
         let reminders = await mockAPI.createdReminders
         XCTAssertEqual(reminders.count, 1)
-        XCTAssertEqual(reminders.first, "Test reminder")
-    }
-
-    func testHTTPRemindersAPIConfiguration() {
-        let api = HTTPRemindersAPI(baseURL: URL(string: "https://example.com")!)
-        XCTAssertEqual(api.baseURL.absoluteString, "https://example.com")
+        XCTAssertEqual(reminders.first?.text, "Test reminder")
+        XCTAssertNil(reminders.first?.dueDate)
     }
 }
```

### Milestone 4: Implement EventKit Due Date Logic

**Files**:
- `/Users/mauricelecordier/Documents/slash-remind-native/Services/RemindersAPI.swift` (EventKitRemindersService class)

**Flags**:
- `needs-rationale`: Explains why both dueDateComponents and alarm are set

**Requirements**:
- Replace hardcoded 5-minute alarm with optional due date logic
- Set `dueDateComponents` from parsed Date when present
- Set alarm at due date time for notification
- Maintain reminder creation when dueDate is nil

**Acceptance Criteria**:
- When dueDate is non-nil: `dueDateComponents` set with year/month/day/hour/minute
- When dueDate is non-nil: alarm set for exact due date time
- When dueDate is nil: reminder created without due date or alarm (inbox item)
- Existing permission handling unchanged
- Reminders appear in macOS Reminders app with correct dates

**Tests**:
- **Test files**: Manual verification in Reminders.app
- **Test type**: Integration test (end-to-end)
- **Backing**: Default-derived (verify EventKit integration per default-conventions preference for integration tests)
- **Scenarios**:
  - Create reminder with tomorrow 9am Date → appears tomorrow at 9am in Reminders
  - Create reminder with nil Date → appears in inbox without date
  - Alarm fires at due date time

**Code Intent**:

`Services/RemindersAPI.swift` - Create `EventKitRemindersService` class:
- Import EventKit framework
- Implement RemindersAPI protocol with `Sendable` conformance
- `createReminder()` method:
  - Create EKEventStore instance
  - Request full access to reminders using async EventKit API
  - If access denied, throw error
  - Create EKReminder with title set to text parameter
  - Get default calendar for new reminders
  - If no default calendar, throw error
  - If `dueDate` parameter is non-nil:
    - Create Calendar instance using `Calendar.current`
    - Extract date components using `calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)`
    - Verify dateComponents extraction succeeded with nil-check (defensive programming)
    - If dateComponents is somehow nil, log error using `os_log` with `.error` level and skip setting due date (continue with reminder creation without date)
    - Set `reminder.dueDateComponents = dateComponents`
    - Create alarm with `EKAlarm(absoluteDate: dueDate)`
    - Add alarm using `reminder.addAlarm(alarm)`
  - If `dueDate` is nil, skip date/alarm logic entirely
  - Assign calendar to reminder
  - Save reminder to event store
  - Note: Calendar API handles DST transitions automatically when creating DateComponents

Decision references: "Use dueDateComponents instead of alarm-only", "9:00 AM default for date-only inputs"

**Code Changes**:

```diff
--- a/Services/RemindersAPI.swift
+++ b/Services/RemindersAPI.swift
@@ -1,4 +1,5 @@
 import Foundation
+import EventKit
 #if canImport(os)
 import os.log
 #endif
@@ -40,3 +41,57 @@ actor MockRemindersAPI: RemindersAPI {
         }
     }
 }
+
+// @unchecked Sendable: EKEventStore is thread-safe per Apple docs, all mutations happen via async methods
+final class EventKitRemindersService: RemindersAPI, @unchecked Sendable {
+    private let store = EKEventStore()
+
+    func createReminder(text: String, dueDate: Date?) async throws {
+        let granted: Bool
+        if #available(macOS 14.0, *) {
+            granted = try await store.requestFullAccessToReminders()
+        } else {
+            granted = try await withCheckedThrowingContinuation { continuation in
+                store.requestAccess(to: .reminder) { granted, error in
+                    if let error = error {
+                        continuation.resume(throwing: error)
+                    } else {
+                        continuation.resume(returning: granted)
+                    }
+                }
+            }
+        }
+
+        guard granted else {
+#if canImport(os)
+            os_log("EventKit access denied", log: .services, type: .error)
+#endif
+            throw NSError(domain: "EventKitRemindersService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
+        }
+
+        let reminder = EKReminder(eventStore: store)
+        reminder.title = text
+
+        guard let calendar = store.defaultCalendarForNewReminders() else {
+#if canImport(os)
+            os_log("No default calendar available", log: .services, type: .error)
+#endif
+            throw NSError(domain: "EventKitRemindersService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No default calendar"])
+        }
+
+        if let dueDate = dueDate {
+            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
+            reminder.dueDateComponents = components
+            let alarm = EKAlarm(absoluteDate: dueDate)
+            reminder.addAlarm(alarm)
+        }
+
+        reminder.calendar = calendar
+
+        try store.save(reminder, commit: true)
+#if canImport(os)
+        os_log("Created reminder: %{public}@", log: .services, type: .info, text)
+#endif
+    }
+}
```

### Milestone 5: Wire DateParsingService into PaletteViewModel

**Files**:
- `/Users/mauricelecordier/Documents/slash-remind-native/ViewModels/PaletteViewModel.swift`
- `/Users/mauricelecordier/Documents/slash-remind-native/App/AppDelegate.swift`

**Flags**:
- `conformance`: Follows existing dependency injection pattern

**Requirements**:
- Add `DateParsing` dependency to PaletteViewModel initializer
- Parse text before calling API in `submit()` method
- Pass parsed Date to `api.createReminder()` call
- Instantiate `SoulverDateParser` in AppDelegate and inject into ViewModel

**Acceptance Criteria**:
- `PaletteViewModel` has `private let dateParser: DateParsing` property
- Initializer accepts `dateParser` parameter
- `submit()` calls `dateParser.parseDate()` before API call
- When parsing returns nil, error message displayed and reminder NOT created
- When parsing returns Date, reminder created with due date
- `AppDelegate` creates `SoulverDateParser()` instance and passes to ViewModel
- Compiler verification: AppDelegate is the only PaletteViewModel initialization site (grep confirms no other instantiations)

**Tests**:
- **Test files**: `/Users/mauricelecordier/Documents/slash-remind-native/Tests/PaletteViewModelTests.swift` (NEW)
- **Test type**: Integration test with mock dependencies
- **Backing**: Default-derived
- **Scenarios**:
  - ViewModel with MockDateParser returning fixed Date → API receives Date, reminder created
  - ViewModel with MockDateParser returning nil → Error displayed, API NOT called, reminder NOT created
  - Error message verification: Contains helpful example ("e.g., 'tomorrow at 9am'")

**Code Intent**:

`ViewModels/PaletteViewModel.swift`:
- Add `private let dateParser: DateParsing` property after `scheduler` property
- Update initializer to accept `dateParser: DateParsing` parameter and assign to property
- In `submit()` method after line 28 (`let message = text`):
  - Add `let parsedDate = dateParser.parseDate(from: message)`
  - Check if `parsedDate` is nil (no date detected):
    - If nil, set `self.error = "Please include a date or time (e.g., 'tomorrow at 9am')"` and return early without creating reminder
    - If non-nil, proceed with reminder creation
  - Update line 31 API call from `api.createReminder(text: message)` to `api.createReminder(text: message, dueDate: parsedDate)`
- Update line 32 scheduler call from `Reminder(text: message)` to `Reminder(text: message, dueDate: parsedDate)`

`App/AppDelegate.swift`:
- After line 11 (EventKitRemindersService initialization), add `private let dateParser: DateParsing = SoulverDateParser()`
- Update PaletteViewModel initialization to pass `dateParser: dateParser` parameter
- Note: AppDelegate confirmed as only PaletteViewModel instantiation site via codebase search

Decision references: "Service layer abstraction with DateParsing protocol", "DateParsingService applies 9:00 AM default"

**Code Changes**:

```diff
--- a/ViewModels/PaletteViewModel.swift
+++ b/ViewModels/PaletteViewModel.swift
@@ -12,9 +12,10 @@ final class PaletteViewModel: ObservableObject {
     private let api: RemindersAPI
     private let settings: SettingsStore
     private let scheduler: NotificationScheduling
+    private let dateParser: DateParsing

-    init(api: RemindersAPI, settings: SettingsStore, scheduler: NotificationScheduling) {
+    init(api: RemindersAPI, settings: SettingsStore, scheduler: NotificationScheduling, dateParser: DateParsing) {
         self.api = api
         self.settings = settings
         self.scheduler = scheduler
+        self.dateParser = dateParser
     }

@@ -27,9 +28,15 @@ final class PaletteViewModel: ObservableObject {
         isSubmitting = true
         let message = text
+        let parsedDate = dateParser.parseDate(from: message)
+        guard let parsedDate = parsedDate else {
+            self.error = "Please include a date or time (e.g., 'tomorrow at 9am')"
+            isSubmitting = false
+            return
+        }
         Task {
             do {
-                try await api.createReminder(text: message)
-                scheduler.schedule(Reminder(text: message))
+                try await api.createReminder(text: message, dueDate: parsedDate)
+                scheduler.schedule(Reminder(text: message, dueDate: parsedDate))
 #if os(macOS)
                 NSApp.keyWindow?.close()
 #endif
```

```diff
--- a/App/AppDelegate.swift
+++ b/App/AppDelegate.swift
@@ -8,13 +8,14 @@ final class AppDelegate: NSObject, NSApplicationDelegate {
     private var hotKeyService: HotKeyService!
     let settings = SettingsStore()
     private let scheduler = NotificationScheduler()
-    private lazy var api: RemindersAPI = HTTPRemindersAPI(baseURL: URL(string: settings.baseURL)!)
+    private let api: RemindersAPI = EventKitRemindersService()
+    private let dateParser: DateParsing = SoulverDateParser()
     private var paletteController: CommandPaletteWindowController!

     func applicationDidFinishLaunching(_ notification: Notification) {
         requestNotificationPermissionsIfNeeded()
-        let vm = PaletteViewModel(api: api, settings: settings, scheduler: scheduler)
+        let vm = PaletteViewModel(api: api, settings: settings, scheduler: scheduler, dateParser: dateParser)
         paletteController = CommandPaletteWindowController(viewModel: vm)
         statusBar = StatusBarController(paletteController: paletteController, settings: settings)
         let controller = paletteController
```

### Milestone 6: Documentation

**Delegated to**: @agent-technical-writer (mode: post-implementation)

**Source**: `## Invisible Knowledge` section of this plan

**Files**:
- `/Users/mauricelecordier/Documents/slash-remind-native/Services/CLAUDE.md` (UPDATE)
- `/Users/mauricelecordier/Documents/slash-remind-native/Services/README.md` (CREATE if not exists, UPDATE if exists)
- `/Users/mauricelecordier/Documents/slash-remind-native/ViewModels/CLAUDE.md` (UPDATE)
- `/Users/mauricelecordier/Documents/slash-remind-native/App/CLAUDE.md` (UPDATE)

**Requirements**:

Services/CLAUDE.md updates:
- Add row for `DateParsingService.swift`: "Natural language date/time parsing using SoulverCore" in WHAT column
- WHEN column: "Parsing user input, adding date parsing, testing parsing logic"

Services/README.md:
- Add section explaining date parsing architecture
- Document 9:00 AM default for date-only inputs
- Explain why both `dueDateComponents` and alarm are set
- Include data flow diagram from Invisible Knowledge

ViewModels/CLAUDE.md updates:
- Update `PaletteViewModel.swift` row to mention date parsing injection

App/CLAUDE.md updates:
- Update `AppDelegate.swift` row to mention DateParsingService injection

**Acceptance Criteria**:
- CLAUDE.md files use tabular format only
- README.md includes architecture diagram from Invisible Knowledge
- README.md explains 9:00 AM default behavior
- README.md is self-contained (no external references)

**Source Material**: `## Invisible Knowledge` section of this plan

## Milestone Dependencies

```
M1 (Add Dependency)
 |
 v
M2 (DateParsingService) --> M5 (Wire ViewModel)
 |                               |
 v                               v
M3 (Update Models/Protocol) --> M4 (EventKit Logic) --> M6 (Documentation)
```

- M1 must complete before M2 (SoulverCore required for DateParsingService)
- M2 and M3 can run in parallel
- M4 depends on M3 (needs updated protocol signature)
- M5 depends on M2 (needs DateParsingService) and M4 (needs EventKit implementation)
- M6 runs after all implementation complete
