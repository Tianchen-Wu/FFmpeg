import MediaForgeCore
import SwiftUI

struct ProgressPanel: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let presentation = ProgressPresentation(
            isConverting: appState.isConverting,
            currentProgress: appState.currentProgress,
            overallProgress: appState.overallProgress
        )

        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if presentation.shouldShowProgress {
                    progressGroup(
                        title: appState.text("current_file"),
                        percent: presentation.currentPercentText,
                        value: presentation.hasCurrentBar ? appState.currentProgress : nil
                    )
                    progressGroup(
                        title: appState.text("total_progress"),
                        percent: presentation.overallPercentText,
                        value: presentation.hasOverallBar ? appState.overallProgress : nil
                    )
                }

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

    private func progressGroup(title: String, percent: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(percent)
                    .font(.caption.monospacedDigit().weight(.medium))
            }
            if let value {
                ProgressView(value: value)
                    .frame(width: 160)
            }
        }
        .frame(width: 170, alignment: .leading)
    }
}
