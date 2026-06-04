import MediaForgeCore
import SwiftUI

struct FailedTasksView: View {
    @EnvironmentObject private var appState: AppState
    let files: [MediaFile]

    var failedFiles: [MediaFile] {
        files.filter {
            if case .failed = $0.status { return true }
            return false
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(appState.text("failed_tasks"))
                .font(.headline)
            List(failedFiles) { file in
                VStack(alignment: .leading) {
                    Text(file.fileName)
                    if case .failed(let message) = file.status {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}
