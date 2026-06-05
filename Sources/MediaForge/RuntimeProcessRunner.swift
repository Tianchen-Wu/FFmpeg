import Foundation

enum RuntimeProcessRunner {
    static func run(
        scriptURL: URL,
        onLine: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [scriptURL.path]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()

        for try await line in outputPipe.fileHandleForReading.bytes.lines {
            onLine(line)
        }

        process.waitUntilExit()
        return process.terminationStatus
    }
}
