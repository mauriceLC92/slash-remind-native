import XCTest
@testable import SlashRemind

final class RemindersAPITests: XCTestCase {
    func testMockRemindersAPIBasic() async throws {
        let mockAPI = MockRemindersAPI()
        try await mockAPI.createReminder(text: "Test reminder")
        let reminders = await mockAPI.createdReminders
        XCTAssertEqual(reminders.count, 1)
        XCTAssertEqual(reminders.first, "Test reminder")
    }
    
    func testHTTPRemindersAPIConfiguration() {
        let api = HTTPRemindersAPI(baseURL: URL(string: "https://example.com")!)
        XCTAssertEqual(api.baseURL.absoluteString, "https://example.com")
    }
}
