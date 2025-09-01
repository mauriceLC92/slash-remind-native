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

    init(api: RemindersAPI, settings: SettingsStore, scheduler: NotificationScheduling) {
        self.api = api
        self.settings = settings
        self.scheduler = scheduler
    }

    func submit() {
        guard !text.isEmpty, URL(string: settings.baseURL) != nil else {
            error = "Invalid configuration"
            return
        }
        isSubmitting = true
        let message = text
        Task {
            do {
                try await api.createReminder(text: message)
                scheduler.schedule(Reminder(text: message))
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
