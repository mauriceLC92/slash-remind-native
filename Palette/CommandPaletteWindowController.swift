#if os(macOS)
import AppKit
import SwiftUI
import QuartzCore

final class KeyablePanel: NSPanel {
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
            return
        }
        super.keyDown(with: event)
    }
}

@MainActor
final class CommandPaletteWindowController: NSWindowController {
    private let viewModel: PaletteViewModel
    private var hostingView: NSHostingView<CommandPaletteView>!
    private var isAnimatingHide = false
    private var observers: [NSObjectProtocol] = []

    private let paletteSize = NSSize(width: 520, height: 110)

    init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel

        let panel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: paletteSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titleVisibility = .hidden
        panel.acceptsMouseMovedEvents = true
        panel.hasShadow = true

        super.init(window: panel)

        panel.onCancel = { [weak self] in
            self?.hide()
        }

        let content = CommandPaletteView(viewModel: viewModel, onDismiss: { [weak self] in
            self?.hide()
        })
        self.hostingView = NSHostingView(rootView: content)
        self.hostingView.canDrawConcurrently = false
        panel.contentView = self.hostingView
        panel.initialFirstResponder = self.hostingView

        observers = [
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: panel,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.hide(animated: false)
                }
            },
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: NSApp,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.hide(animated: false)
                }
            }
        ]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let window = window, !window.isVisible else { return }

        viewModel.reset()
        viewModel.requestFocus()
        window.setFrame(centeredFrame(for: paletteSize), display: false)

        let finalFrame = window.frame
        var startFrame = finalFrame
        startFrame.origin.y -= 12

        window.alphaValue = 0
        window.setFrame(startFrame, display: false)

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(hostingView)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(finalFrame, display: true)
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, let window = self.window else { return }
                window.makeKeyAndOrderFront(nil)
                window.makeFirstResponder(self.hostingView)
                self.viewModel.requestFocus()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func hide(animated: Bool = true) {
        guard let window = window, window.isVisible, !isAnimatingHide else { return }

        let finishHide: () -> Void = { [weak self] in
            guard let self = self else { return }
            window.orderOut(nil)
            window.alphaValue = 1
            self.isAnimatingHide = false
            self.viewModel.reset()
        }

        guard animated else {
            finishHide()
            return
        }

        isAnimatingHide = true
        let currentFrame = window.frame
        var endFrame = currentFrame
        endFrame.origin.y -= 8

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            window.animator().setFrame(endFrame, display: true)
        } completionHandler: {
            finishHide()
        }
    }

    private func centeredFrame(for size: NSSize) -> NSRect {
        guard let screenFrame = targetScreen()?.visibleFrame else {
            return NSRect(origin: .zero, size: size)
        }

        let x = screenFrame.midX - (size.width / 2)
        let y = screenFrame.midY - (size.height / 2)
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    private func targetScreen() -> NSScreen? {
        if let keyWindowScreen = NSApp.keyWindow?.screen {
            return keyWindowScreen
        }

        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main
    }
}
#endif
