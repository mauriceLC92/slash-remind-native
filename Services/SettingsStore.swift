import Foundation

final class SettingsStore: ObservableObject {
    private enum Keys: String {
        case syncEnabled
        case notificationsEnabled
        case defaultReminderListIdentifier
        case defaultTimeHour
        case defaultTimeMinute
    }

    private let defaults: UserDefaults

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled.rawValue) }
    }

    @Published var defaultReminderListIdentifier: String? {
        didSet {
            if let defaultReminderListIdentifier {
                defaults.set(defaultReminderListIdentifier, forKey: Keys.defaultReminderListIdentifier.rawValue)
            } else {
                defaults.removeObject(forKey: Keys.defaultReminderListIdentifier.rawValue)
            }
        }
    }

    @Published var defaultTime: Date {
        didSet {
            let components = Calendar.current.dateComponents([.hour, .minute], from: defaultTime)
            defaults.set(components.hour ?? 9, forKey: Keys.defaultTimeHour.rawValue)
            defaults.set(components.minute ?? 0, forKey: Keys.defaultTimeMinute.rawValue)
        }
    }

    var defaultTimeComponents: DateComponents {
        let components = Calendar.current.dateComponents([.hour, .minute], from: defaultTime)
        return DateComponents(hour: components.hour ?? 9, minute: components.minute ?? 0, second: 0)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Keys.notificationsEnabled.rawValue) == nil,
           let legacyValue = defaults.object(forKey: Keys.syncEnabled.rawValue) as? Bool {
            defaults.set(legacyValue, forKey: Keys.notificationsEnabled.rawValue)
        }

        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled.rawValue) as? Bool ?? true
        defaultReminderListIdentifier = defaults.string(forKey: Keys.defaultReminderListIdentifier.rawValue)

        let hour = defaults.object(forKey: Keys.defaultTimeHour.rawValue) as? Int ?? 9
        let minute = defaults.object(forKey: Keys.defaultTimeMinute.rawValue) as? Int ?? 0
        defaultTime = SettingsStore.makeTime(hour: hour, minute: minute)
    }

    private static func makeTime(hour: Int, minute: Int) -> Date {
        let safeHour = min(max(hour, 0), 23)
        let safeMinute = min(max(minute, 0), 59)
        let components = DateComponents(year: 2001, month: 1, day: 1, hour: safeHour, minute: safeMinute)
        return Calendar.current.date(from: components) ?? Date(timeIntervalSinceReferenceDate: 0)
    }
}
