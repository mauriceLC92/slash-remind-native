#if os(macOS)
import SwiftUI

struct CommandPaletteView: View {
    @ObservedObject var viewModel: PaletteViewModel
    var onDismiss: () -> Void = {}
    @FocusState private var isTextFieldFocused: Bool
    
    // Force focus coordinator
    private class FocusCoordinator: ObservableObject {
        @Published var shouldFocus: Bool = false
        
        func triggerFocus() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.shouldFocus = true
            }
        }
    }
    
    @StateObject private var focusCoordinator = FocusCoordinator()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search…", text: $viewModel.text)
                    .focused($isTextFieldFocused)
                    .onSubmit(viewModel.submit)
                    .textFieldStyle(.plain)
                    .onReceive(focusCoordinator.$shouldFocus) { shouldFocus in
                        if shouldFocus {
                            isTextFieldFocused = true
                            focusCoordinator.shouldFocus = false
                        }
                    }
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(12)
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            HStack(spacing: 4) {
                Text("Type")
                CapsuleBadge(text: "#")
                Text("to access projects,")
                CapsuleBadge(text: ">")
                Text("for users, and")
                CapsuleBadge(text: "?")
                Text("for help.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 480)
        .background(KeyEventHandling(onEscape: onDismiss))
        .onAppear {
            // Use coordinator for more reliable focus
            focusCoordinator.triggerFocus()
            
            // Fallback direct focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isTextFieldFocused = true
            }
        }
    }
}

struct CapsuleBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.thinMaterial)
            .cornerRadius(4)
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
        if event.keyCode == 53 { // Escape key
            onEscape?()
        } else {
            // Pass the event to the next responder
            self.nextResponder?.keyDown(with: event)
        }
    }
    
    // Override to handle key events without stealing first responder from TextField
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 53 { // Escape key
            onEscape?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
#endif
