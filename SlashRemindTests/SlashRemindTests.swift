import XCTest
@testable import SlashRemind

final class QuickAddInputParserTests: XCTestCase {
    private let dueDate = Date(timeIntervalSince1970: 1_704_110_400)
    private let defaultTime = DateComponents(hour: 9, minute: 0, second: 0)

    func testStripsDateAndTimeFromTitle() {
        let parser = QuickAddInputParser(dateParser: ControlledDateParser(matches: [
            "buy milk tomorrow at 9am": dueDate,
            "tomorrow at 9am": dueDate
        ]))

        let result = parser.parse("buy milk tomorrow at 9am", defaultTime: defaultTime)

        XCTAssertEqual(result?.title, "buy milk")
        XCTAssertEqual(result?.dueDate, dueDate)
    }

    func testStripsDateOnlySuffixFromTitle() {
        let parser = QuickAddInputParser(dateParser: ControlledDateParser(matches: [
            "file taxes tomorrow": dueDate,
            "tomorrow": dueDate
        ]))

        let result = parser.parse("file taxes tomorrow", defaultTime: defaultTime)

        XCTAssertEqual(result?.title, "file taxes")
        XCTAssertEqual(result?.dueDate, dueDate)
    }

    func testStripsTimeOnlySuffixFromTitle() {
        let parser = QuickAddInputParser(dateParser: ControlledDateParser(matches: [
            "call mom at 9am": dueDate,
            "at 9am": dueDate
        ]))

        let result = parser.parse("call mom at 9am", defaultTime: defaultTime)

        XCTAssertEqual(result?.title, "call mom")
        XCTAssertEqual(result?.dueDate, dueDate)
    }

    func testDateOnlyInputFallsBackToGenericTitle() {
        let parser = QuickAddInputParser(dateParser: ControlledDateParser(matches: [
            "tomorrow": dueDate
        ]))

        let result = parser.parse("tomorrow", defaultTime: defaultTime)

        XCTAssertEqual(result?.title, "Reminder")
        XCTAssertEqual(result?.dueDate, dueDate)
    }

    func testStripsPrepositionBeforeDate() {
        let parser = QuickAddInputParser(dateParser: ControlledDateParser(matches: [
            "book flights on March 15": dueDate,
            "on March 15": dueDate
        ]))

        let result = parser.parse("book flights on March 15", defaultTime: defaultTime)

        XCTAssertEqual(result?.title, "book flights")
        XCTAssertEqual(result?.dueDate, dueDate)
    }
}

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testMigratesLegacySyncEnabledPreference() {
        let defaults = isolatedDefaults()
        defaults.set(false, forKey: "syncEnabled")

        let settings = SettingsStore(defaults: defaults)

        XCTAssertFalse(settings.notificationsEnabled)
        XCTAssertFalse(defaults.bool(forKey: "notificationsEnabled"))
    }

    func testPersistsDefaultReminderListAndDefaultTime() {
        let defaults = isolatedDefaults()
        let settings = SettingsStore(defaults: defaults)

        settings.defaultReminderListIdentifier = "list-id"
        settings.defaultTime = Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: 16, minute: 45))!

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.defaultReminderListIdentifier, "list-id")
        XCTAssertEqual(reloaded.defaultTimeComponents.hour, 16)
        XCTAssertEqual(reloaded.defaultTimeComponents.minute, 45)
    }

    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "SlashRemindTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class ControlledDateParser: DateParsing, @unchecked Sendable {
    private let matches: [String: Date]

    init(matches: [String: Date]) {
        self.matches = matches
    }

    func parseDate(from text: String, defaultTime: DateComponents) -> Date? {
        matches[text.trimmingCharacters(in: .whitespacesAndNewlines)]
    }
}
