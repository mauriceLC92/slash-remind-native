import Foundation

final class SettingsStore: ObservableObject {
    private enum Keys: String {
        case syncEnabled
    }

    @Published var syncEnabled: Bool {
        didSet { UserDefaults.standard.set(syncEnabled, forKey: Keys.syncEnabled.rawValue) }
    }

    init() {
        syncEnabled = UserDefaults.standard.object(forKey: Keys.syncEnabled.rawValue) as? Bool ?? true
    }
}
