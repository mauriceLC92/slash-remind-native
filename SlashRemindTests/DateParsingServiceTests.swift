import XCTest
@testable import SlashRemind

final class DateParsingServiceTests: XCTestCase {
    var parser: DateParsing!
    let defaultTime = DateComponents(hour: 9, minute: 0, second: 0)

    override func setUp() {
        super.setUp()
        parser = SoulverDateParser()
    }

    func testParsesTomorrowAt9AM() {
        let result = parser.parseDate(from: "tomorrow at 9am", defaultTime: defaultTime)
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 0)
    }

    func testParsesNextMondayAt3PM() {
        let result = parser.parseDate(from: "next Monday 3pm", defaultTime: defaultTime)
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        XCTAssertEqual(components.hour, 15)
        XCTAssertEqual(components.minute, 0)
    }

    func testDateOnlyApplies9AMDefault() {
        let result = parser.parseDate(from: "tomorrow", defaultTime: defaultTime)
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testParsesMarch15WithDefault9AM() {
        let result = parser.parseDate(from: "March 15", defaultTime: defaultTime)
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .hour, .minute], from: date)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 0)
    }

    func testParsesRelativeTime() {
        let result = parser.parseDate(from: "in 3 hours", defaultTime: defaultTime)
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        XCTAssertGreaterThan(timeInterval, 3 * 3600 - 60)
        XCTAssertLessThan(timeInterval, 3 * 3600 + 60)
    }

    func testReturnsNilForInvalidInput() {
        let result = parser.parseDate(from: "xyz invalid", defaultTime: defaultTime)
        XCTAssertNil(result)
    }

    func testReturnsNilForEmptyString() {
        let result = parser.parseDate(from: "", defaultTime: defaultTime)
        XCTAssertNil(result)
    }

    func testDateOnlyUsesConfiguredDefaultTime() {
        let result = parser.parseDate(from: "tomorrow", defaultTime: DateComponents(hour: 14, minute: 30, second: 0))
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 0)
    }
}
