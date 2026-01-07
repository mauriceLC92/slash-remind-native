import XCTest
@testable import SlashRemind

final class RemindersAPITests: XCTestCase {
    func testMockRemindersAPIBasic() async throws {
        let mockAPI = MockRemindersAPI()
        try await mockAPI.createReminder(text: "Test reminder", dueDate: nil)
        let reminders = await mockAPI.createdReminders
        XCTAssertEqual(reminders.count, 1)
        XCTAssertEqual(reminders.first?.text, "Test reminder")
        XCTAssertNil(reminders.first?.dueDate)
    }
}
