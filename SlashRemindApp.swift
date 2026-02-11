import SwiftUI

@main
struct SlashRemindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            PreferencesWindow(settings: appDelegate.settings)
        }
    }
}