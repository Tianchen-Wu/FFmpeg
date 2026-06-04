import MediaForgeCore
import SwiftUI

struct FileListView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appState.text("files"))
                    .font(.headline)
                Spacer()
                Text("\(appState.files.count) \(appState.text("tasks_count"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Table(appState.files) {
                TableColumn(appState.text("file_name")) { file in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.fileName)
                            .lineLimit(1)
                        Text(file.inputURL.deletingLastPathComponent().path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                TableColumn(appState.text("type")) { file in
                    Text(typeText(file.mediaInfo?.mediaType))
                }
                TableColumn(appState.text("duration")) { file in
                    Text(durationText(file.mediaInfo?.duration))
                }
                TableColumn(appState.text("size")) { file in
                    Text(FileSizeFormatter.string(from: file.fileSize))
                }
                TableColumn(appState.text("status")) { file in
                    Text(statusText(file.status))
                        .foregroundStyle(statusColor(file.status))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func typeText(_ type: MediaType?) -> String {
        switch type {
        case .video: appState.text("video")
        case .audio: appState.text("audio")
        case .unknown: appState.text("unknown")
        case nil: appState.text("analyzing")
        }
    }

    private func durationText(_ duration: Double?) -> String {
        guard let duration else { return "-" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func statusText(_ status: ConversionStatus) -> String {
        switch status {
        case .analyzing: appState.text("analyzing")
        case .queued: appState.text("queued")
        case .converting(let progress):
            if let progress {
                "\(appState.text("converting")) \(Int(progress * 100))%"
            } else {
                appState.text("converting")
            }
        case .completed: appState.text("completed")
        case .failed(let message): "\(appState.text("failed")): \(message)"
        case .cancelled: appState.text("cancelled")
        }
    }

    private func statusColor(_ status: ConversionStatus) -> Color {
        switch status {
        case .completed: .green
        case .failed: .red
        case .cancelled: .orange
        case .converting: .accentColor
        default: .primary
        }
    }
}
