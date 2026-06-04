import SwiftUI

struct ProgressPanel: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ProgressView(value: appState.currentProgress)
                    .frame(width: 220)
                ProgressView(value: appState.overallProgress)
                    .frame(width: 220)
                Text(appState.statusMessage)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if appState.totalCount > 0 {
                    Text("\(appState.currentIndex)/\(appState.totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button(appState.text("open_output")) {
                    appState.openOutputDirectory()
                }
                .disabled(appState.files.compactMap(\.outputURL).isEmpty)
            }

            if !appState.currentLogText.isEmpty {
                LogPanel(text: appState.currentLogText)
                    .frame(maxHeight: 130)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
