#if os(macOS)
import AppKit
import SwiftUI

// Custom panel that can become key window for text input
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class CommandPaletteWindowController: NSWindowController {
    private let viewModel: PaletteViewModel
    private var hostingView: NSHostingView<CommandPaletteView>!

    init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
        let panel = KeyablePanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 180),
                                 styleMask: [.borderless],
                                 backing: .buffered,
                                 defer: false)
        
        // Critical panel configuration for text input
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titleVisibility = .hidden
        panel.acceptsMouseMovedEvents = true
        
        super.init(window: panel)
        
        // Now we can safely use self
        let content = CommandPaletteView(viewModel: viewModel, onDismiss: { [weak self] in
            self?.close()
        })
        self.hostingView = NSHostingView(rootView: content)
        
        // Configure hosting view for proper text input
        self.hostingView.canDrawConcurrently = false
        
        panel.contentView = self.hostingView
        
        // Set up responder chain
        panel.initialFirstResponder = self.hostingView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func toggle() {
        if window?.isVisible == true {
            close()
        } else {
            show()
        }
    }

    func show() {
        guard let window = window else { return }
        window.alphaValue = 0
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window.animator().alphaValue = 1
        } completionHandler: {
            // Critical: Force window to become key AFTER animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                // Force the hosting view to accept first responder
                if let hostingView = window.contentView {
                    _ = hostingView.becomeFirstResponder()
                }
            }
        }
    }

    override func close() {
        super.close()
        viewModel.reset()
    }
}
#endif
