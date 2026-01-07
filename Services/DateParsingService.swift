import Foundation
import SoulverCore
#if canImport(os)
import os.log
#endif

protocol DateParsing: Sendable {
    func parseDate(from text: String) -> Date?
}

// @unchecked Sendable: SoulverCore String.dateValue is stateless pure function with no mutable state
final class SoulverDateParser: DateParsing, @unchecked Sendable {
    func parseDate(from text: String) -> Date? {
        guard let parsedDate = text.dateValue else {
#if canImport(os)
            os_log("Date parsing failed for text: %{public}@", log: .services, type: .debug, text)
#endif
            return nil
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: parsedDate)

        guard let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return parsedDate
        }

        if hour == 12 && minute == 0 && second == 0 {
            if let adjustedDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: parsedDate) {
                return adjustedDate
            } else {
#if canImport(os)
                os_log("DST edge case: returning original noon date", log: .services, type: .debug)
#endif
                return parsedDate
            }
        }

        return parsedDate
    }
}
