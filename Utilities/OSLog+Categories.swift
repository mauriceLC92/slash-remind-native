#if canImport(os)
import os.log

extension OSLog {
    private static let subsystem = "dev.slashremind.native"
    static let hotkey = OSLog(subsystem: subsystem, category: "hotkey")
    static let palette = OSLog(subsystem: subsystem, category: "palette")
    static let network = OSLog(subsystem: subsystem, category: "network")
    static let notifications = OSLog(subsystem: subsystem, category: "notifications")
}
#endif
