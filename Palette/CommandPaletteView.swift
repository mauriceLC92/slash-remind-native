#if os(macOS)
import SwiftUI
import AppKit

struct CommandPaletteView: View {
    @ObservedObject var viewModel: PaletteViewModel
    var onDismiss: () -> Void = {}

    @FocusState private var isTextFieldFocused: Bool
    @State private var dismissWorkItem: DispatchWorkItem?
    @State private var exampleIndex = 0

    private let exampleTimer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()
    private let examples = [
        "buy milk tomorrow at 9am",
        "call Sam this afternoon",
        "submit expenses next Friday",
        "take out the bins tonight",
        "book dentist appointment Monday at 10am"
    ]

    private var canSubmit: Bool {
        !viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isSubmitting && !viewModel.didCreateReminder
    }

    private var currentExample: String {
        examples[exampleIndex % examples.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            inputRow
            feedbackRow
            footer
        }
        .padding(14)
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 6)
        )
        .background(KeyEventHandling(onEscape: onDismiss))
        .onAppear {
            focusTextField()
        }
        .onDisappear {
            dismissWorkItem?.cancel()
        }
        .onChange(of: viewModel.focusRequestID) { _ in
            focusTextField()
        }
        .onReceive(exampleTimer) { _ in
            guard viewModel.text.isEmpty else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                exampleIndex = (exampleIndex + 1) % examples.count
            }
        }
        .onChange(of: viewModel.didCreateReminder) { didCreateReminder in
            guard didCreateReminder else { return }
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)

            dismissWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                onDismiss()
            }
            dismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.56, execute: workItem)
        }
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.didCreateReminder ? "checkmark.circle.fill" : "calendar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(viewModel.didCreateReminder ? Color.green : Color.secondary)

            TextField(currentExample, text: $viewModel.text)
                .focused($isTextFieldFocused)
                .onSubmit {
                    guard canSubmit else { return }
                    Task {
                        await viewModel.submit()
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .regular))
                .disabled(viewModel.isSubmitting || viewModel.didCreateReminder)
                .accessibilityIdentifier("quickAddTextField")

            if viewModel.isSubmitting {
                ProgressView()
                    .controlSize(.small)
            } else if !viewModel.didCreateReminder {
                KeyBadge(text: "↩")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.8)
                )
        )
    }

    @ViewBuilder
    private var feedbackRow: some View {
        if viewModel.didCreateReminder {
            HStack(spacing: 7) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.green)
                Text("Reminder created")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .transition(.opacity)
        } else if let error = viewModel.error {
            HStack(spacing: 7) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .transition(.opacity)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            KeyBadge(text: "⎋")
            Text("close")
                .foregroundStyle(.secondary)

            Text("•")
                .foregroundStyle(.tertiary)

            Text("Include a date or time")
                .foregroundStyle(.secondary)

            Spacer()

            KeyBadge(text: "⌘")
            KeyBadge(text: "/")
        }
        .font(.system(size: 11, weight: .medium))
    }

    private func focusTextField() {
        isTextFieldFocused = false
        DispatchQueue.main.async {
            isTextFieldFocused = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            isTextFieldFocused = true
        }
    }
}

struct KeyBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 0.7)
            )
    }
}

struct KeyEventHandling: NSViewRepresentable {
    let onEscape: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlingView()
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let keyView = nsView as? KeyHandlingView {
            keyView.onEscape = onEscape
        }
    }
}

class KeyHandlingView: NSView {
    var onEscape: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
        } else {
            self.nextResponder?.keyDown(with: event)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            onEscape?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
#endif
