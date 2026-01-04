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
        
        let paletteItem = NSMenuItem(title: "Open Command Palette", action: #selector(openPalette), keyEquivalent: "")
        paletteItem.target = self
        menu.addItem(paletteItem)
        
        let syncTitle = settings.syncEnabled ? "Pause Sync" : "Resume Sync"
        let syncItem = NSMenuItem(title: syncTitle, action: #selector(toggleSync), keyEquivalent: "")
        syncItem.target = self
        menu.addItem(syncItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.keyEquivalentModifierMask = [.command]
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
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
