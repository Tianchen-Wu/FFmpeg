import MediaForgeCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(appState.text("settings"))
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Label(appState.text("close"), systemImage: "xmark")
                }
                .labelStyle(.titleAndIcon)
            }

            Form {
                Picker(appState.text("language"), selection: $appState.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppMetadata.displayName)
                        .font(.headline)
                    Text(appState.ffmpegPathSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .padding()
        .frame(width: 440)
    }
}
