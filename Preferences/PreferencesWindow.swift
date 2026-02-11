#if os(macOS)
import SwiftUI

struct PreferencesWindow: View {
    @ObservedObject var settings: SettingsStore
    var body: some View {
        Form {
            Section(header: Text("Hotkey")) {
                HStack {
                    Text("Trigger")
                    Spacer()
                    Text("⌘ + /")
                    Button("Change…") {}
                        .disabled(true)
                }
            }
            Section(header: Text("Notifications")) {
                Toggle("Enable local notifications", isOn: $settings.syncEnabled)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
#endif
