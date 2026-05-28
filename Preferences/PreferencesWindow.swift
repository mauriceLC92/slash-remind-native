#if os(macOS)
import SwiftUI

struct PreferencesWindow: View {
    @ObservedObject var settings: SettingsStore
    let listProvider: any ReminderListProviding

    @State private var reminderLists: [ReminderList] = []
    @State private var isLoadingLists = false
    @State private var listError: String?

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
            Section(header: Text("Reminders")) {
                Picker("Default List", selection: $settings.defaultReminderListIdentifier) {
                    Text("Reminders Default").tag(Optional<String>.none)
                    ForEach(reminderLists) { list in
                        Text(list.title).tag(Optional(list.id))
                    }
                }
                .disabled(isLoadingLists)

                DatePicker("Default Time", selection: $settings.defaultTime, displayedComponents: .hourAndMinute)

                if let listError {
                    Text(listError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if selectedListIsMissing {
                    Text("The selected list is unavailable. New reminders will use the Reminders default list.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section(header: Text("Notifications")) {
                Toggle("Enable local notifications", isOn: $settings.notificationsEnabled)
            }
        }
        .padding(20)
        .frame(width: 440)
        .task {
            await loadReminderLists()
        }
    }

    private var selectedListIsMissing: Bool {
        guard let selectedID = settings.defaultReminderListIdentifier, !reminderLists.isEmpty else {
            return false
        }
        return !reminderLists.contains { $0.id == selectedID }
    }

    private func loadReminderLists() async {
        isLoadingLists = true
        listError = nil
        do {
            reminderLists = try await listProvider.reminderLists()
        } catch {
            listError = "Reminder lists could not be loaded. The default Reminders list will be used."
        }
        isLoadingLists = false
    }
}
#endif
