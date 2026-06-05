import MediaForgeCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HSplitView {
                VStack(spacing: 12) {
                    FileDropView()
                    FileListView()
                }
                .frame(minWidth: 620)

                OutputSettingsView()
                    .frame(minWidth: 320, idealWidth: 360, maxWidth: 430)
            }
            Divider()
            ProgressPanel()
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showRuntimeAssistant) {
            RuntimeAssistantView()
                .environmentObject(appState)
        }
        .onAppear {
            appState.presentRuntimeAssistantIfNeeded()
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(AppMetadata.displayName)
                    .font(.title2.weight(.semibold))
                Text(appState.ffmpegPathSummary)
                    .font(.caption)
                    .foregroundStyle(appState.ffmpeg == nil || appState.ffprobe == nil ? .red : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if !appState.failedFiles.isEmpty {
                Label("\(appState.failedFiles.count)", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            if appState.ffmpeg == nil || appState.ffprobe == nil {
                Button {
                    appState.showRuntimeAssistant = true
                } label: {
                    Label(appState.text("runtime_install"), systemImage: "arrow.down.circle")
                }
                .labelStyle(.titleAndIcon)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help(appState.text("runtime_install"))
            }

            Button {
                appState.toggleLanguage()
            } label: {
                Image(systemName: "globe")
            }
            .help(appState.text("switch_language"))

            Button {
                appState.showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .help(appState.text("settings"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
