import Foundation
import EventKit
#if canImport(os)
import os.log
#endif

final class EventKitRemindersService: RemindersAPI, @unchecked Sendable {
    private let store = EKEventStore()

    func createReminder(text: String, dueDate: Date?) async throws {
        let granted: Bool
        if #available(macOS 14.0, *) {
            granted = try await store.requestFullAccessToReminders()
        } else {
            granted = try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }

        guard granted else {
#if canImport(os)
            os_log("EventKit access denied", log: .services, type: .error)
#endif
            throw NSError(domain: "EventKitRemindersService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = text

        guard let calendar = store.defaultCalendarForNewReminders() else {
#if canImport(os)
            os_log("No default calendar available", log: .services, type: .error)
#endif
            throw NSError(domain: "EventKitRemindersService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No default calendar"])
        }

        if let dueDate = dueDate {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            guard components.year != nil, components.month != nil, components.day != nil else {
#if canImport(os)
                os_log("Failed to extract date components from dueDate", log: .services, type: .error)
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
        os_log("Created reminder: %{public}@", log: .services, type: .info, text)
#endif
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