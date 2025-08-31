#if os(macOS)
import AppKit
import SwiftUI

final class CommandPaletteWindowController: NSWindowController {
    private let viewModel: PaletteViewModel

    init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
        let content = CommandPaletteView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: content)
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 180),
                            styleMask: [.nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titleVisibility = .hidden
        panel.contentView = hosting
        super.init(window: panel)
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
        }
    }

    override func close() {
        super.close()
        viewModel.reset()
    }
}
#endif
