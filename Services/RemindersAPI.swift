import Foundation

struct ReminderList: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
}

struct UpcomingReminder: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let dueDate: Date
}

protocol RemindersAPI: Sendable {
    func createReminder(title: String, dueDate: Date?, calendarIdentifier: String?) async throws
    func upcomingReminders(limit: Int) async throws -> [UpcomingReminder]
}

protocol ReminderListProviding: Sendable {
    func reminderLists() async throws -> [ReminderList]
}

actor MockRemindersAPI: RemindersAPI {
    private var created: [(title: String, dueDate: Date?, calendarIdentifier: String?)] = []
    private var upcoming: [UpcomingReminder]
    private var upcomingError: Error?

    init(upcoming: [UpcomingReminder] = [], upcomingError: Error? = nil) {
        self.upcoming = upcoming
        self.upcomingError = upcomingError
    }

    func createReminder(title: String, dueDate: Date?, calendarIdentifier: String?) async throws {
        created.append((title: title, dueDate: dueDate, calendarIdentifier: calendarIdentifier))
    }

    func upcomingReminders(limit: Int) async throws -> [UpcomingReminder] {
        if let upcomingError {
            throw upcomingError
        }

        return Array(upcoming.sorted { $0.dueDate < $1.dueDate }.prefix(max(limit, 0)))
    }

    var createdReminders: [(title: String, dueDate: Date?, calendarIdentifier: String?)] {
        get async {
            return created
        }
    }
}
