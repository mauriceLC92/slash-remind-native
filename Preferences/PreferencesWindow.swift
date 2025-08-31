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
                    Text("Double '/' ")
                    Button("Change…") {}
                        .disabled(true)
                }
            }
            Section(header: Text("Backend")) {
                TextField("Base URL", text: $settings.baseURL)
                    .textFieldStyle(.roundedBorder)
            }
            Section(header: Text("Sync")) {
                Toggle("Enable cloud sync & local notifications", isOn: $settings.syncEnabled)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
#endif
