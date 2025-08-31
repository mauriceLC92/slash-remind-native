#if os(macOS)
import SwiftUI

@main
struct SpotlightRemindersApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            PreferencesWindow(settings: appDelegate.settings)
        }
    }
}
#endif
