import XCTest
@testable import SlashRemind
#if os(macOS)
import AppKit
#endif

final class PaletteViewModelTests: XCTestCase {
    override class func setUp() {
        super.setUp()
#if os(macOS)
        Task { @MainActor in
            _ = NSApplication.shared
        }
#endif
    }
    func testSubmitWithValidDateCreatesReminder() async throws {
        let mockAPI = MockRemindersAPI()
        let mockScheduler = MockNotificationScheduler()
        let fixedDate = Date(timeIntervalSince1970: 1704110400)
        let mockInputParser = MockInputParser(parsed: ParsedReminderInput(title: "Buy milk", dueDate: fixedDate))
        let settings = SettingsStore(defaults: isolatedDefaults())

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            inputParser: mockInputParser
        )

        await vm.setText("Buy milk tomorrow")
        await vm.submit()

        let reminders = await mockAPI.createdReminders
        XCTAssertEqual(reminders.count, 1)
        XCTAssertEqual(reminders.first?.title, "Buy milk")
        XCTAssertEqual(reminders.first?.dueDate, fixedDate)
        XCTAssertNil(reminders.first?.calendarIdentifier)

        let scheduled = await mockScheduler.scheduledReminders
        XCTAssertEqual(scheduled.count, 1)
        XCTAssertEqual(scheduled.first?.title, "Buy milk")
        XCTAssertEqual(scheduled.first?.dueDate, fixedDate)
    }

    func testSubmitWithNilDateShowsErrorAndDoesNotCreateReminder() async throws {
        let mockAPI = MockRemindersAPI()
        let mockScheduler = MockNotificationScheduler()
        let mockInputParser = MockInputParser(parsed: nil)
        let settings = SettingsStore(defaults: isolatedDefaults())

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            inputParser: mockInputParser
        )

        await vm.setText("Buy milk")
        await vm.submit()

        let error = await vm.getError()
        XCTAssertNotNil(error)
        XCTAssertTrue(error?.contains("Please include a date or time") ?? false)
        XCTAssertTrue(error?.contains("e.g., 'tomorrow at 9am'") ?? false)

        let reminders = await mockAPI.createdReminders
        XCTAssertEqual(reminders.count, 0)

        let scheduled = await mockScheduler.scheduledReminders
        XCTAssertEqual(scheduled.count, 0)
    }

    func testSubmitUsesSelectedReminderListAndSkipsNotificationsWhenDisabled() async throws {
        let mockAPI = MockRemindersAPI()
        let mockScheduler = MockNotificationScheduler()
        let fixedDate = Date(timeIntervalSince1970: 1704110400)
        let settings = SettingsStore(defaults: isolatedDefaults())
        await MainActor.run {
            settings.defaultReminderListIdentifier = "calendar-id"
            settings.notificationsEnabled = false
        }

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            inputParser: MockInputParser(parsed: ParsedReminderInput(title: "Pay rent", dueDate: fixedDate))
        )

        await vm.setText("Pay rent tomorrow")
        await vm.submit()

        let reminders = await mockAPI.createdReminders
        XCTAssertEqual(reminders.first?.calendarIdentifier, "calendar-id")

        let scheduled = await mockScheduler.scheduledReminders
        XCTAssertTrue(scheduled.isEmpty)
    }

    func testEmptyDoubleReturnLoadsUpcomingRemindersSortedByDueDate() async throws {
        let later = UpcomingReminder(
            id: "later",
            title: "Later reminder",
            dueDate: Date(timeIntervalSinceReferenceDate: 2_000)
        )
        let sooner = UpcomingReminder(
            id: "sooner",
            title: "Sooner reminder",
            dueDate: Date(timeIntervalSinceReferenceDate: 1_000)
        )
        let mockAPI = MockRemindersAPI(upcoming: [later, sooner])
        let mockScheduler = MockNotificationScheduler()
        let settings = SettingsStore(defaults: isolatedDefaults())

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            inputParser: MockInputParser(parsed: nil),
            doubleReturnThreshold: 0.3
        )

        let firstReturn = Date(timeIntervalSinceReferenceDate: 10_000)
        await vm.setText("   \n")
        await vm.handleReturn(now: firstReturn)

        let firstState = await vm.getUpcomingRemindersState()
        XCTAssertEqual(firstState, .hidden)
        let firstError = await vm.getError()
        XCTAssertNil(firstError)

        await vm.handleReturn(now: firstReturn.addingTimeInterval(0.2))

        guard case .loaded(let reminders) = await vm.getUpcomingRemindersState() else {
            XCTFail("Expected loaded upcoming reminders")
            return
        }

        XCTAssertEqual(reminders.map(\.id), ["sooner", "later"])

        let created = await mockAPI.createdReminders
        XCTAssertTrue(created.isEmpty)
    }

    func testEmptyReturnOutsideDoublePressThresholdDoesNotRevealOrError() async throws {
        let mockAPI = MockRemindersAPI(upcoming: [
            UpcomingReminder(id: "upcoming", title: "Upcoming", dueDate: Date(timeIntervalSinceReferenceDate: 1_000))
        ])
        let mockScheduler = MockNotificationScheduler()
        let settings = SettingsStore(defaults: isolatedDefaults())

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            inputParser: MockInputParser(parsed: nil),
            doubleReturnThreshold: 0.3
        )

        let firstReturn = Date(timeIntervalSinceReferenceDate: 10_000)
        await vm.handleReturn(now: firstReturn)
        await vm.handleReturn(now: firstReturn.addingTimeInterval(0.5))

        let state = await vm.getUpcomingRemindersState()
        let error = await vm.getError()
        XCTAssertEqual(state, .hidden)
        XCTAssertNil(error)
    }

    func testEmptyDoubleReturnHandlesPermissionDenied() async throws {
        let mockAPI = MockRemindersAPI(upcomingError: EventKitError.accessDenied)
        let mockScheduler = MockNotificationScheduler()
        let settings = SettingsStore(defaults: isolatedDefaults())

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            inputParser: MockInputParser(parsed: nil),
            doubleReturnThreshold: 0.3
        )

        let firstReturn = Date(timeIntervalSinceReferenceDate: 10_000)
        await vm.handleReturn(now: firstReturn)
        await vm.handleReturn(now: firstReturn.addingTimeInterval(0.2))

        let state = await vm.getUpcomingRemindersState()
        let error = await vm.getError()
        XCTAssertEqual(state, .permissionDenied)
        XCTAssertNil(error)
    }

    func testEmptyReturnClosesVisibleUpcomingReminders() async throws {
        let mockAPI = MockRemindersAPI(upcoming: [
            UpcomingReminder(id: "upcoming", title: "Upcoming", dueDate: Date(timeIntervalSinceReferenceDate: 1_000))
        ])
        let mockScheduler = MockNotificationScheduler()
        let settings = SettingsStore(defaults: isolatedDefaults())

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            inputParser: MockInputParser(parsed: nil),
            doubleReturnThreshold: 0.3
        )

        let firstReturn = Date(timeIntervalSinceReferenceDate: 10_000)
        await vm.handleReturn(now: firstReturn)
        await vm.handleReturn(now: firstReturn.addingTimeInterval(0.2))

        guard case .loaded = await vm.getUpcomingRemindersState() else {
            XCTFail("Expected loaded upcoming reminders")
            return
        }

        await vm.handleReturn(now: firstReturn.addingTimeInterval(0.4))

        let state = await vm.getUpcomingRemindersState()
        XCTAssertEqual(state, .hidden)
    }

    func testHandleReturnWithTextStillCreatesReminder() async throws {
        let mockAPI = MockRemindersAPI()
        let mockScheduler = MockNotificationScheduler()
        let fixedDate = Date(timeIntervalSince1970: 1704110400)
        let settings = SettingsStore(defaults: isolatedDefaults())

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            inputParser: MockInputParser(parsed: ParsedReminderInput(title: "Call Sam", dueDate: fixedDate))
        )

        await vm.setText("Call Sam tomorrow")
        await vm.handleReturn()

        let reminders = await mockAPI.createdReminders
        let state = await vm.getUpcomingRemindersState()
        XCTAssertEqual(reminders.count, 1)
        XCTAssertEqual(reminders.first?.title, "Call Sam")
        XCTAssertEqual(state, .hidden)
    }

    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "PaletteViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

@MainActor
extension PaletteViewModel {
    func setText(_ text: String) {
        self.text = text
    }

    func getError() -> String? {
        return self.error
    }

    func getUpcomingRemindersState() -> UpcomingRemindersState {
        return self.upcomingRemindersState
    }
}

final class MockInputParser: ReminderInputParsing, @unchecked Sendable {
    private let parsed: ParsedReminderInput?

    init(parsed: ParsedReminderInput?) {
        self.parsed = parsed
    }

    func parse(_ text: String, defaultTime: DateComponents) -> ParsedReminderInput? {
        parsed
    }
}

final class MockNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private var scheduled: [Reminder] = []

    func schedule(_ reminder: Reminder) {
        scheduled.append(reminder)
    }

    var scheduledReminders: [Reminder] {
        get async {
            return scheduled
        }
    }
}
