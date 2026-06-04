import SwiftUI
import UniformTypeIdentifiers

struct FileDropView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(appState.text("drop_prompt"))
                .font(.headline)
            HStack(spacing: 10) {
                Button(appState.text("add_files")) { selectFiles() }
                Button(appState.text("add_folder")) { selectFolder() }
                Button(appState.text("clear_list")) { appState.clearFiles() }
                    .disabled(appState.files.isEmpty || appState.isConverting)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(isTargeted ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isTargeted ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: 1)
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
        .padding([.top, .horizontal], 16)
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            appState.addFiles(urls: panel.urls)
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            appState.addFiles(urls: panel.urls)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    appState.addFiles(urls: [url])
                }
            }
        }
        return true
    }
}
