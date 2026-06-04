import SwiftUI

@main
struct MediaForgeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1040, minHeight: 680)
        }
        .windowStyle(.titleBar)
    }
}
