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
        let mockDateParser = MockDateParser(fixedDate: fixedDate)
        let settings = SettingsStore()

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            dateParser: mockDateParser
        )

        await vm.setText("Buy milk tomorrow")
        await vm.submit()

        try await Task.sleep(nanoseconds: 100_000_000)

        let reminders = await mockAPI.createdReminders
        XCTAssertEqual(reminders.count, 1)
        XCTAssertEqual(reminders.first?.text, "Buy milk tomorrow")
        XCTAssertEqual(reminders.first?.dueDate, fixedDate)

        let scheduled = await mockScheduler.scheduledReminders
        XCTAssertEqual(scheduled.count, 1)
        XCTAssertEqual(scheduled.first?.text, "Buy milk tomorrow")
        XCTAssertEqual(scheduled.first?.dueDate, fixedDate)
    }

    func testSubmitWithNilDateShowsErrorAndDoesNotCreateReminder() async throws {
        let mockAPI = MockRemindersAPI()
        let mockScheduler = MockNotificationScheduler()
        let mockDateParser = MockDateParser(fixedDate: nil)
        let settings = SettingsStore()

        let vm = await PaletteViewModel(
            api: mockAPI,
            settings: settings,
            scheduler: mockScheduler,
            dateParser: mockDateParser
        )

        await vm.setText("Buy milk")
        await vm.submit()

        try await Task.sleep(nanoseconds: 100_000_000)

        let error = await vm.getError()
        XCTAssertNotNil(error)
        XCTAssertTrue(error?.contains("Please include a date or time") ?? false)
        XCTAssertTrue(error?.contains("e.g., 'tomorrow at 9am'") ?? false)

        let reminders = await mockAPI.createdReminders
        XCTAssertEqual(reminders.count, 0)

        let scheduled = await mockScheduler.scheduledReminders
        XCTAssertEqual(scheduled.count, 0)
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
}

final class MockDateParser: DateParsing, @unchecked Sendable {
    private let fixedDate: Date?

    init(fixedDate: Date?) {
        self.fixedDate = fixedDate
    }

    func parseDate(from text: String) -> Date? {
        return fixedDate
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
