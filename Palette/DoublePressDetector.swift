import Foundation

public final class DoublePressDetector {
    private let keyCode: UInt16
    private let threshold: TimeInterval
    private var lastPress: DispatchTime?

    public init(keyCode: UInt16 = 0x2C, threshold: TimeInterval = 0.3) {
        self.keyCode = keyCode
        self.threshold = threshold
    }

    public func register(keyCode: UInt16, isRepeat: Bool = false) -> Bool {
        guard !isRepeat, keyCode == self.keyCode else { return false }
        let now = DispatchTime.now()
        defer { lastPress = now }
        if let last = lastPress,
           now.uptimeNanoseconds - last.uptimeNanoseconds < UInt64(threshold * 1_000_000_000) {
            lastPress = nil
            return true
        }
        return false
    }
}
