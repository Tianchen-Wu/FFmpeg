import Foundation

public struct ConversionLog: Equatable, Sendable {
    public let taskID: UUID
    public let inputPath: String
    public let outputPath: String
    public let commandArguments: [String]
    public let startedAt: Date
    public let endedAt: Date
    public let exitCode: Int32
    public let rawLog: String

    public init(
        taskID: UUID,
        inputPath: String,
        outputPath: String,
        commandArguments: [String],
        startedAt: Date,
        endedAt: Date,
        exitCode: Int32,
        rawLog: String
    ) {
        self.taskID = taskID
        self.inputPath = inputPath
        self.outputPath = outputPath
        self.commandArguments = commandArguments
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.exitCode = exitCode
        self.rawLog = rawLog
    }
}

public struct LogService: Sendable {
    private let directory: URL

    public init(directory: URL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Logs/MediaForge", isDirectory: true)) {
        self.directory = directory
    }

    public func save(_ log: ConversionLog) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = ISO8601DateFormatter()
            .string(from: log.startedAt)
            .replacingOccurrences(of: ":", with: "-") + "_\(log.taskID.uuidString).log"
        let url = directory.appendingPathComponent(filename)
        let text = """
        MediaForge Conversion Log
        Started: \(log.startedAt)
        Ended: \(log.endedAt)
        Exit Code: \(log.exitCode)
        Input: \(log.inputPath)
        Output: \(log.outputPath)
        Arguments: \(log.commandArguments.joined(separator: " "))

        \(log.rawLog)
        """
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
