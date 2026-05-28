#if os(macOS)
import AppKit
import UserNotifications
import os.log

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController!
    private var hotKeyService: HotKeyService!
    let settings = SettingsStore()
    let remindersService = EventKitRemindersService()
    private let scheduler = NotificationScheduler()
    private let inputParser: ReminderInputParsing = QuickAddInputParser()
    private var paletteController: CommandPaletteWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermissionsIfNeeded()
        let vm = PaletteViewModel(api: remindersService, settings: settings, scheduler: scheduler, inputParser: inputParser)
        paletteController = CommandPaletteWindowController(viewModel: vm)
        statusBar = StatusBarController(paletteController: paletteController, settings: settings)
        let controller = paletteController
        hotKeyService = HotKeyService { @Sendable [weak controller] in
            Task { @MainActor in
                controller?.toggle()
            }
        }

        if ProcessInfo.processInfo.environment["SLASH_REMIND_SHOW_PALETTE_ON_LAUNCH"] == "1" {
            DispatchQueue.main.async { [weak self] in
                self?.paletteController.show()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyService.stop()
    }

    private func requestNotificationPermissionsIfNeeded() {
        guard settings.notificationsEnabled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            os_log("notification permission %{public}@", log: .notifications, type: .info, granted ? "granted" : "denied")
        }
    }

    @MainActor @objc func openPreferences(_ sender: Any?) {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
#endif
