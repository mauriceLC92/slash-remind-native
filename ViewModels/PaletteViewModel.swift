import Foundation

@MainActor
final class PaletteViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var didCreateReminder = false
    @Published var focusRequestID = 0

    private let api: RemindersAPI
    private let settings: SettingsStore
    private let scheduler: NotificationScheduling
    private let inputParser: ReminderInputParsing

    init(api: RemindersAPI, settings: SettingsStore, scheduler: NotificationScheduling, inputParser: ReminderInputParsing) {
        self.api = api
        self.settings = settings
        self.scheduler = scheduler
        self.inputParser = inputParser
    }

    func submit() async {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else {
            error = "Type a reminder with a date or time"
            return
        }

        isSubmitting = true
        didCreateReminder = false
        error = nil

        guard let parsed = inputParser.parse(message, defaultTime: settings.defaultTimeComponents) else {
            self.error = "Please include a date or time (e.g., 'tomorrow at 9am')"
            self.isSubmitting = false
            return
        }

        do {
            try await api.createReminder(
                title: parsed.title,
                dueDate: parsed.dueDate,
                calendarIdentifier: settings.defaultReminderListIdentifier
            )
            if settings.notificationsEnabled {
                scheduler.schedule(Reminder(title: parsed.title, dueDate: parsed.dueDate))
            }
            self.didCreateReminder = true
            self.isSubmitting = false
            self.error = nil
        } catch {
            self.error = "Couldn’t create reminder. Please try again."
            self.isSubmitting = false
            self.didCreateReminder = false
        }
    }

    func requestFocus() {
        focusRequestID += 1
    }

    func reset() {
        text = ""
        error = nil
        isSubmitting = false
        didCreateReminder = false
    }
}
