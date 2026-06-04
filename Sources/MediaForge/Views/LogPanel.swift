import SwiftUI

struct LogPanel: View {
    @EnvironmentObject private var appState: AppState
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(appState.text("log"))
                    .font(.caption.weight(.semibold))
                Spacer()
                Button(appState.text("copy")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
            }
            ScrollView {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
    }
}
