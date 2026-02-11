import Foundation

protocol RemindersAPI: Sendable {
    func createReminder(text: String, dueDate: Date?) async throws
}

actor MockRemindersAPI: RemindersAPI {
    private var created: [(text: String, dueDate: Date?)] = []

    func createReminder(text: String, dueDate: Date?) async throws {
        created.append((text: text, dueDate: dueDate))
    }

    var createdReminders: [(text: String, dueDate: Date?)] {
        get async {
            return created
        }
    }
}
