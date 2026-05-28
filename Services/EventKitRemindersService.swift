import Foundation
import EventKit
#if canImport(os)
import os.log
#endif

final class EventKitRemindersService: RemindersAPI, ReminderListProviding, @unchecked Sendable {
    private let store: EKEventStore

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    func reminderLists() async throws -> [ReminderList] {
        guard try await requestRemindersAccess() else {
#if canImport(os)
            os_log("EventKit access denied while loading reminder lists", log: .services, type: .error)
#endif
            throw EventKitError.accessDenied
        }

        return store.calendars(for: .reminder)
            .map { ReminderList(id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func createReminder(title: String, dueDate: Date?, calendarIdentifier: String?) async throws {
        guard try await requestRemindersAccess() else {
#if canImport(os)
            os_log("EventKit access denied", log: .services, type: .error)
#endif
            throw EventKitError.accessDenied
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title

        guard let calendar = reminderCalendar(matching: calendarIdentifier) else {
#if canImport(os)
            os_log("No default calendar available", log: .services, type: .error)
#endif
            throw EventKitError.noDefaultCalendar
        }

        if let dueDate = dueDate {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            guard components.year != nil, components.month != nil, components.day != nil else {
#if canImport(os)
                os_log("Failed to extract date components from due date", log: .services, type: .error)
#endif
                throw NSError(domain: "EventKitRemindersService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid date format"])
            }
            reminder.dueDateComponents = components
            let alarm = EKAlarm(absoluteDate: dueDate)
            reminder.addAlarm(alarm)
        }

        reminder.calendar = calendar

        try store.save(reminder, commit: true)
#if canImport(os)
        os_log("Created reminder due_date_present=%{public}@", log: .services, type: .info, dueDate == nil ? "false" : "true")
#endif
    }

    private func requestRemindersAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await store.requestFullAccessToReminders()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    private func reminderCalendar(matching identifier: String?) -> EKCalendar? {
        if let identifier,
           let calendar = store.calendar(withIdentifier: identifier),
           calendar.allowedEntityTypes.contains(.reminder) {
            return calendar
        }
        return store.defaultCalendarForNewReminders()
    }
}

enum EventKitError: LocalizedError {
    case accessDenied
    case noDefaultCalendar

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Reminders access was denied. Please enable access in System Preferences > Privacy & Security > Reminders."
        case .noDefaultCalendar:
            return "No default reminders calendar found. Please check your Reminders app."
        }
    }
}
