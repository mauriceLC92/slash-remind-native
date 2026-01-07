import Foundation
#if os(macOS)
import AppKit
#endif

@MainActor
final class PaletteViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isSubmitting = false
    @Published var error: String?

    private let api: RemindersAPI
    private let settings: SettingsStore
    private let scheduler: NotificationScheduling
    private let dateParser: DateParsing

    init(api: RemindersAPI, settings: SettingsStore, scheduler: NotificationScheduling, dateParser: DateParsing) {
        self.api = api
        self.settings = settings
        self.scheduler = scheduler
        self.dateParser = dateParser
    }

    func submit() {
        guard !text.isEmpty, URL(string: settings.baseURL) != nil else {
            error = "Invalid configuration"
            return
        }
        isSubmitting = true
        let message = text
        let parsedDate = dateParser.parseDate(from: message)
        guard let parsedDate = parsedDate else {
            self.error = "Please include a date or time (e.g., 'tomorrow at 9am')"
            self.isSubmitting = false
            return
        }
        Task {
            do {
                try await api.createReminder(text: message, dueDate: parsedDate)
                scheduler.schedule(Reminder(text: message, dueDate: parsedDate))
#if os(macOS)
                NSApp.keyWindow?.close()
#endif
                reset()
            } catch {
                self.error = "Network error"
                self.isSubmitting = false
            }
        }
    }

    func reset() {
        text = ""
        error = nil
        isSubmitting = false
    }
}
