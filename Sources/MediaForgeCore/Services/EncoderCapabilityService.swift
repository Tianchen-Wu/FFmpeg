import Foundation

public struct EncoderCapabilityService: Sendable {
    private let runner: any ProcessRunning

    public init(runner: any ProcessRunning = DefaultProcessRunner()) {
        self.runner = runner
    }

    public func availableEncoders(ffmpegURL: URL) async -> Set<String> {
        do {
            let result = try await runner.run(executableURL: ffmpegURL, arguments: ["-hide_banner", "-encoders"])
            let text = result.standardOutput + "\n" + result.standardError
            return parseEncoders(from: text)
        } catch {
            return []
        }
    }

    public func parseEncoders(from text: String) -> Set<String> {
        var encoders = Set<String>()
        for line in text.split(separator: "\n") {
            let columns = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard columns.count >= 2 else { continue }
            let name = columns[1]
            if name != "=" && !name.contains("----") {
                encoders.insert(name)
            }
        }
        return encoders
    }
}
