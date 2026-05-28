import Foundation

@MainActor
final class PaletteViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var didCreateReminder = false

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
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else {
            error = "Type a reminder with a date or time"
            return
        }

        isSubmitting = true
        didCreateReminder = false
        error = nil

        guard let parsedDate = dateParser.parseDate(from: message) else {
            self.error = "Please include a date or time (e.g., 'tomorrow at 9am')"
            self.isSubmitting = false
            return
        }

        Task {
            do {
                try await api.createReminder(text: message, dueDate: parsedDate)
                scheduler.schedule(Reminder(text: message, dueDate: parsedDate))
                self.didCreateReminder = true
                self.isSubmitting = false
                self.error = nil
            } catch {
                self.error = "Couldn’t create reminder. Please try again."
                self.isSubmitting = false
                self.didCreateReminder = false
            }
        }
    }

    func reset() {
        text = ""
        error = nil
        isSubmitting = false
        didCreateReminder = false
    }
}
