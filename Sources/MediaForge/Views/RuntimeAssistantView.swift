import MediaForgeCore
import SwiftUI

struct RuntimeAssistantView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            statusBlock
            installBlock
            if !appState.runtimeInstallerMessage.isEmpty {
                Text(appState.runtimeInstallerMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            buttons
        }
        .padding(20)
        .frame(width: 560)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: appState.ffmpeg == nil || appState.ffprobe == nil ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(appState.ffmpeg == nil || appState.ffprobe == nil ? .orange : .green)
                .font(.title3)
            Text(appState.text("runtime_title"))
                .font(.headline)
            Spacer()
            Button {
                dismiss()
            } label: {
                Label(appState.text("close"), systemImage: "xmark")
            }
            .labelStyle(.titleAndIcon)
        }
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appState.text("runtime_status"))
                .font(.subheadline.weight(.semibold))
            Text(appState.runtimeStatusSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Text("\(appState.text("homebrew")): \(appState.homebrewPathSummary)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    private var installBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.text("runtime_missing_hint"))
                .font(.subheadline)
            Text(appState.text("runtime_space_hint"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button {
                appState.installRuntimeWithHomebrew()
            } label: {
                Label(appState.text("runtime_install_homebrew"), systemImage: "terminal")
            }
            .buttonStyle(.borderedProminent)

            Button {
                appState.openHomebrewWebsite()
            } label: {
                Label(appState.text("runtime_open_homebrew"), systemImage: "safari")
            }

            Spacer()

            Button {
                appState.recheckRuntime()
            } label: {
                Label(appState.text("runtime_recheck"), systemImage: "arrow.clockwise")
            }
        }
    }
}
