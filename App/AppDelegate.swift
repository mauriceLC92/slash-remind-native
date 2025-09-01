#if os(macOS)
import AppKit
import UserNotifications
import os.log

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController!
    private var hotKeyService: HotKeyService!
    let settings = SettingsStore()
    private let scheduler = NotificationScheduler()
    private lazy var api: RemindersAPI = HTTPRemindersAPI(baseURL: URL(string: settings.baseURL)!)
    private var paletteController: CommandPaletteWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermissionsIfNeeded()
        let vm = PaletteViewModel(api: api, settings: settings, scheduler: scheduler)
        paletteController = CommandPaletteWindowController(viewModel: vm)
        statusBar = StatusBarController(paletteController: paletteController, settings: settings)
        hotKeyService = HotKeyService { [weak self] in
            self?.paletteController.toggle()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyService.stop()
    }

    private func requestNotificationPermissionsIfNeeded() {
        guard settings.syncEnabled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            os_log("notification permission %{public}@", log: .notifications, type: .info, granted ? "granted" : "denied")
        }
    }

    @objc func openPreferences(_ sender: Any?) {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
#endif
