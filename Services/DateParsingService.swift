import Foundation
import SoulverCore
#if canImport(os)
import os.log
#endif

protocol DateParsing: Sendable {
    func parseDate(from text: String, defaultTime: DateComponents) -> Date?
}

struct ParsedReminderInput: Equatable {
    let title: String
    let dueDate: Date
}

protocol ReminderInputParsing: Sendable {
    func parse(_ text: String, defaultTime: DateComponents) -> ParsedReminderInput?
}

// @unchecked Sendable: SoulverCore String.dateValue is stateless pure function with no mutable state
final class SoulverDateParser: DateParsing, @unchecked Sendable {
    func parseDate(from text: String, defaultTime: DateComponents) -> Date? {
        guard let parsedDate = text.dateValue else {
#if canImport(os)
            os_log("Date parsing failed", log: .services, type: .debug)
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

        if hour == 12 && minute == 0 && second == 0 && !text.localizedCaseInsensitiveContains("noon") {
            let defaultHour = defaultTime.hour ?? 9
            let defaultMinute = defaultTime.minute ?? 0
            if let adjustedDate = calendar.date(bySettingHour: defaultHour, minute: defaultMinute, second: 0, of: parsedDate) {
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

final class QuickAddInputParser: ReminderInputParsing, @unchecked Sendable {
    private let dateParser: DateParsing

    init(dateParser: DateParsing = SoulverDateParser()) {
        self.dateParser = dateParser
    }

    func parse(_ text: String, defaultTime: DateComponents) -> ParsedReminderInput? {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty,
              let dueDate = dateParser.parseDate(from: message, defaultTime: defaultTime) else {
            return nil
        }

        let title = cleanedTitle(from: message, dueDate: dueDate, defaultTime: defaultTime)
        return ParsedReminderInput(title: title, dueDate: dueDate)
    }

    private func cleanedTitle(from message: String, dueDate: Date, defaultTime: DateComponents) -> String {
        guard let range = dateSuffixRange(in: message, dueDate: dueDate, defaultTime: defaultTime) else {
            return message
        }

        var title = message
        title.removeSubrange(range)
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        title = title.trimmingCharacters(in: CharacterSet(charactersIn: ",.;:-"))
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)

        return title.isEmpty ? "Reminder" : title
    }

    private func dateSuffixRange(in message: String, dueDate: Date, defaultTime: DateComponents) -> Range<String.Index>? {
        let tokens = tokens(in: message)
        let candidates = candidateSuffixRanges(from: tokens, in: message)

        for range in candidates {
            let candidate = String(message[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !candidate.isEmpty,
                  let candidateDate = dateParser.parseDate(from: candidate, defaultTime: defaultTime),
                  datesMatch(candidateDate, dueDate) else {
                continue
            }
            return range
        }

        return nil
    }

    private struct Token {
        let text: String
        let range: Range<String.Index>
    }

    private func tokens(in text: String) -> [Token] {
        let pattern = #"\b[\p{L}\p{N}:/.]+\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return Token(text: String(text[range]), range: range)
        }
    }

    private func candidateSuffixRanges(from tokens: [Token], in text: String) -> [Range<String.Index>] {
        guard !tokens.isEmpty else { return [] }

        var ranges: [Range<String.Index>] = []
        for index in tokens.indices where isDateCore(tokens[index].text, next: tokens[safe: index + 1]?.text) {
            let startIndex = candidateStartIndex(forCoreAt: index, tokens: tokens)
            let range = tokens[startIndex].range.lowerBound..<text.endIndex
            if !ranges.contains(where: { $0 == range }) {
                ranges.append(range)
            }
        }

        ranges.sort { lhs, rhs in
            lhs.lowerBound < rhs.lowerBound
        }
        return ranges
    }

    private func candidateStartIndex(forCoreAt index: Int, tokens: [Token]) -> Int {
        guard index > tokens.startIndex else { return index }

        let previous = tokens[index - 1].text.lowercased()
        let current = tokens[index].text.lowercased()

        if ["next", "this", "last"].contains(previous) {
            return index - 1
        }

        if ["at", "on", "by", "before", "after", "due"].contains(previous) {
            return index - 1
        }

        if previous == "in", isDurationQuantity(current, next: tokens[safe: index + 1]?.text) {
            return index - 1
        }

        return index
    }

    private func isDateCore(_ token: String, next: String?) -> Bool {
        let lowercased = token.lowercased()
        if relativeDateWords.contains(lowercased) || weekdays.contains(lowercased) || months.contains(lowercased) {
            return true
        }

        if isTime(lowercased) || isNumericDate(lowercased) || isDurationQuantity(lowercased, next: next) {
            return true
        }

        return false
    }

    private func isTime(_ token: String) -> Bool {
        token.range(of: #"^\d{1,2}(:\d{2})?\s?(am|pm)$"#, options: .regularExpression) != nil ||
            token == "noon" ||
            token == "midnight"
    }

    private func isNumericDate(_ token: String) -> Bool {
        token.range(of: #"^\d{1,2}[/.-]\d{1,2}([/.-]\d{2,4})?$"#, options: .regularExpression) != nil
    }

    private func isDurationQuantity(_ token: String, next: String?) -> Bool {
        guard Int(token) != nil, let next else { return false }
        return durationUnits.contains(next.lowercased())
    }

    private func datesMatch(_ lhs: Date, _ rhs: Date) -> Bool {
        abs(lhs.timeIntervalSince(rhs)) < 2
    }

    private let relativeDateWords: Set<String> = [
        "today", "tomorrow", "tonight", "yesterday", "morning", "afternoon", "evening", "weekend"
    ]

    private let weekdays: Set<String> = [
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
        "mon", "tue", "tues", "wed", "thu", "thur", "thurs", "fri", "sat", "sun"
    ]

    private let months: Set<String> = [
        "january", "february", "march", "april", "may", "june",
        "july", "august", "september", "october", "november", "december",
        "jan", "feb", "mar", "apr", "jun", "jul", "aug", "sep", "sept", "oct", "nov", "dec"
    ]

    private let durationUnits: Set<String> = [
        "minute", "minutes", "min", "mins", "hour", "hours", "hr", "hrs", "day", "days", "week", "weeks"
    ]
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
