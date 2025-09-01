#if os(macOS)
import SwiftUI

struct CommandPaletteView: View {
    @ObservedObject var viewModel: PaletteViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search…", text: $viewModel.text, onCommit: viewModel.submit)
                    .textFieldStyle(.plain)
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
                CapsuleBadge("#")
                Text("to access projects,")
                CapsuleBadge(">")
                Text("for users, and")
                CapsuleBadge("?")
                Text("for help.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 480)
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
#endif
