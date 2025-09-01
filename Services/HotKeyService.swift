#if os(macOS)
import Cocoa
import os.log

final class HotKeyService {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let detector: DoublePressDetector
    private let callback: @Sendable () -> Void

    init(detector: DoublePressDetector = DoublePressDetector(), callback: @escaping @Sendable () -> Void) {
        self.detector = detector
        self.callback = callback
        start()
    }

    private func start() {
        let mask = (1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                     place: .headInsertEventTap,
                                     options: .listenOnly,
                                     eventsOfInterest: CGEventMask(mask),
                                     callback: { proxy, type, event, refcon in
            let service = Unmanaged<HotKeyService>.fromOpaque(refcon!).takeUnretainedValue()
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            if service.detector.register(keyCode: keyCode, isRepeat: isRepeat) {
                let callback = service.callback
                DispatchQueue.main.async { callback() }
            }
            return Unmanaged.passUnretained(event)
        }, userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        if let eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            os_log("Failed to create event tap", log: .hotkey, type: .error)
        }
    }

    func stop() {
        if let eventTap { CFMachPortInvalidate(eventTap) }
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes) }
    }
}
#endif
