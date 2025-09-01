import Foundation

final class SettingsStore: ObservableObject {
    private enum Keys: String {
        case baseURL, syncEnabled
    }

    @Published var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: Keys.baseURL.rawValue) }
    }

    @Published var syncEnabled: Bool {
        didSet { UserDefaults.standard.set(syncEnabled, forKey: Keys.syncEnabled.rawValue) }
    }

    init() {
        baseURL = UserDefaults.standard.string(forKey: Keys.baseURL.rawValue) ?? "https://example.com"
        syncEnabled = UserDefaults.standard.object(forKey: Keys.syncEnabled.rawValue) as? Bool ?? true
    }
}
