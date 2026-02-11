#if os(macOS)
import Cocoa
import Carbon
import os.log

final class HotKeyService {
    private var hotKeyId: EventHotKeyID
    private var hotKeyRef: EventHotKeyRef?
    private let callback: @Sendable () -> Void

    init(callback: @escaping @Sendable () -> Void) {
        self.callback = callback
        self.hotKeyId = EventHotKeyID(signature: FourCharCode(0x68746b31), id: 1) // 'htk1'
        start()
    }

    private func start() {
        var gMyHotKeyRef: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            UInt32(44),                  // "/" key (key code 44)
            UInt32(cmdKey),              // Command modifier
            hotKeyId,
            GetApplicationEventTarget(),
            0,
            &gMyHotKeyRef
        )
        
        if status == noErr {
            hotKeyRef = gMyHotKeyRef
            installEventHandler()
            os_log("Hotkey Cmd+/ registered successfully", log: .hotkey, type: .info)
        } else {
            os_log("Failed to register hotkey: %d", log: .hotkey, type: .error, status)
        }
    }
    
    private func installEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                let service = Unmanaged<HotKeyService>.fromOpaque(userData!).takeUnretainedValue()
                let callback = service.callback
                DispatchQueue.main.async { callback() }
                return noErr
            },
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            nil
        )
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }
}
#endif
