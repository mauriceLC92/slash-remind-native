import Foundation
#if canImport(os)
import os.log
#endif

struct Reminder {
    let title: String
    let dueDate: Date?
}

protocol NotificationScheduling {
    func schedule(_ reminder: Reminder)
}

final class NotificationScheduler: NotificationScheduling {
    func schedule(_ reminder: Reminder) {
#if canImport(os)
        os_log("Scheduled local notification due_date_present=%{public}@", log: .notifications, type: .info, reminder.dueDate == nil ? "false" : "true")
#else
        print("schedule")
#endif
    }
}
