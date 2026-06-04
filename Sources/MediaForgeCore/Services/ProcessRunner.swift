import Foundation

public protocol ProcessRunning: Sendable {
    func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult
}

public struct ProcessResult: Equatable, Sendable {
    public let exitCode: Int32
    public let standardOutput: String
    public let standardError: String

    public init(exitCode: Int32, standardOutput: String, standardError: String) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }
}

public struct DefaultProcessRunner: ProcessRunning {
    public init() {}

    public func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            try process.run()
            process.waitUntilExit()

            let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return ProcessResult(exitCode: process.terminationStatus, standardOutput: output, standardError: error)
        }.value
    }
}
