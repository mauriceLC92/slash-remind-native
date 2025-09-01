#if os(macOS)
import AppKit

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let paletteController: CommandPaletteWindowController
    private let settings: SettingsStore

    init(paletteController: CommandPaletteWindowController, settings: SettingsStore) {
        self.paletteController = paletteController
        self.settings = settings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        constructMenu()
    }

    private func constructMenu() {
        if let button = statusItem.button {
            let symbol = settings.syncEnabled ? "bolt.horizontal.circle" : "bolt.slash.circle"
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Command Palette", action: #selector(openPalette), keyEquivalent: ""))
        let syncTitle = settings.syncEnabled ? "Pause Sync" : "Resume Sync"
        menu.addItem(NSMenuItem(title: syncTitle, action: #selector(toggleSync), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.keyEquivalentModifierMask = [.command]
        menu.addItem(prefsItem)
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    @objc private func openPalette() {
        paletteController.toggle()
    }

    @objc private func openPreferences() {
        NSApp.sendAction(#selector(AppDelegate.openPreferences(_:)), to: nil, from: nil)
    }

    @objc private func toggleSync() {
        settings.syncEnabled.toggle()
        constructMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
#endif
