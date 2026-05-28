import XCTest
@testable import SlashRemind

final class RemindersAPITests: XCTestCase {
    func testMockRemindersAPIBasic() async throws {
        let mockAPI = MockRemindersAPI()
        try await mockAPI.createReminder(title: "Test reminder", dueDate: nil, calendarIdentifier: nil)
        let reminders = await mockAPI.createdReminders
        XCTAssertEqual(reminders.count, 1)
        XCTAssertEqual(reminders.first?.title, "Test reminder")
        XCTAssertNil(reminders.first?.dueDate)
    }
}
