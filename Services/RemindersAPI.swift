import Foundation

struct ReminderList: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
}

protocol RemindersAPI: Sendable {
    func createReminder(title: String, dueDate: Date?, calendarIdentifier: String?) async throws
}

protocol ReminderListProviding: Sendable {
    func reminderLists() async throws -> [ReminderList]
}

actor MockRemindersAPI: RemindersAPI {
    private var created: [(title: String, dueDate: Date?, calendarIdentifier: String?)] = []

    func createReminder(title: String, dueDate: Date?, calendarIdentifier: String?) async throws {
        created.append((title: title, dueDate: dueDate, calendarIdentifier: calendarIdentifier))
    }

    var createdReminders: [(title: String, dueDate: Date?, calendarIdentifier: String?)] {
        get async {
            return created
        }
    }
}
