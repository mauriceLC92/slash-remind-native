import Foundation
#if canImport(os)
import os.log
#endif

struct Reminder {
    let text: String
    let dueDate: Date?
}

protocol NotificationScheduling {
    func schedule(_ reminder: Reminder)
}

final class NotificationScheduler: NotificationScheduling {
    func schedule(_ reminder: Reminder) {
#if canImport(os)
        os_log("schedule %{public}@", log: .notifications, type: .info, reminder.text)
#else
        print("schedule \(reminder.text)")
#endif
    }
}
