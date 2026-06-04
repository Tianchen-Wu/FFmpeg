import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Picker(appState.text("language"), selection: $appState.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("FFmpeg")
                    .font(.headline)
                Text(appState.ffmpegPathSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .frame(width: 440)
    }
}
