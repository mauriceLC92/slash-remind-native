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
            footer
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.24))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 8)
        )
        .background(KeyEventHandling(onEscape: onDismiss))
        .preferredColorScheme(.dark)
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
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 0.7)
                    )

                Image(systemName: viewModel.didCreateReminder ? "checkmark.circle.fill" : "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(viewModel.didCreateReminder ? Color.green : Color.white.opacity(0.84))
            }
            .frame(width: 32, height: 32)

            TextField(currentExample, text: $viewModel.text)
                .focused($isTextFieldFocused)
                .onSubmit {
                    guard canSubmit else { return }
                    Task {
                        await viewModel.submit()
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(.white)
                .disabled(viewModel.isSubmitting || viewModel.didCreateReminder)
                .accessibilityIdentifier("quickAddTextField")
                .frame(height: 34)

            if viewModel.isSubmitting {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 34, height: 34)
            } else if !viewModel.didCreateReminder {
                Button {
                    guard canSubmit else { return }
                    Task {
                        await viewModel.submit()
                    }
                } label: {
                    Image(systemName: "arrow.turn.down.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(canSubmit ? Color.blue : Color.blue.opacity(0.45))
                                .shadow(color: Color.blue.opacity(canSubmit ? 0.28 : 0), radius: 8, x: 0, y: 3)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .accessibilityLabel("Create reminder")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(.white.opacity(0.13), lineWidth: 0.8)
                )
        )
    }

    private var footer: some View {
        HStack(spacing: 6) {
            let detectedDueDate = viewModel.detectedDueDateDescription

            FooterPill(icon: "xmark.circle", text: "Close")

            if viewModel.didCreateReminder {
                FooterPill(icon: "checkmark.circle.fill", text: "Reminder created", tint: .green)
            } else if let error = viewModel.error {
                FooterPill(icon: "exclamationmark.triangle.fill", text: error, tint: .red)
            } else {
                FooterPill(
                    icon: detectedDueDate == nil ? "circle" : "circle.fill",
                    text: detectedDueDate.map { "Detected: \($0)" } ?? "Detected: none",
                    tint: detectedDueDate == nil ? .secondary : .green
                )
            }

            FooterPill(icon: "calendar", text: "Add date/time")

            Spacer(minLength: 6)

            FooterPill(text: "⌘", trailingText: "Return")
            FooterPill(text: "esc")
        }
        .frame(height: 24)
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

struct FooterPill: View {
    var icon: String?
    let text: String
    var trailingText: String?
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: icon == "circle.fill" ? 6 : 10, weight: .semibold))
                    .foregroundStyle(tint)
            }

            Text(text)
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.76))

            if let trailingText {
                Text(trailingText)
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.7)
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
