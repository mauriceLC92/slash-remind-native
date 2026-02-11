import XCTest
@testable import SlashRemind

final class DateParsingServiceTests: XCTestCase {
    var parser: DateParsing!

    override func setUp() {
        super.setUp()
        parser = SoulverDateParser()
    }

    func testParsesTomorrowAt9AM() {
        let result = parser.parseDate(from: "tomorrow at 9am")
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 0)
    }

    func testParsesNextMondayAt3PM() {
        let result = parser.parseDate(from: "next Monday 3pm")
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        XCTAssertEqual(components.hour, 15)
        XCTAssertEqual(components.minute, 0)
    }

    func testDateOnlyApplies9AMDefault() {
        let result = parser.parseDate(from: "tomorrow")
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testParsesMarch15WithDefault9AM() {
        let result = parser.parseDate(from: "March 15")
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
        let result = parser.parseDate(from: "in 3 hours")
        XCTAssertNotNil(result)

        guard let date = result else { return }
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        XCTAssertGreaterThan(timeInterval, 3 * 3600 - 60)
        XCTAssertLessThan(timeInterval, 3 * 3600 + 60)
    }

    func testReturnsNilForInvalidInput() {
        let result = parser.parseDate(from: "xyz invalid")
        XCTAssertNil(result)
    }

    func testReturnsNilForEmptyString() {
        let result = parser.parseDate(from: "")
        XCTAssertNil(result)
    }
}
