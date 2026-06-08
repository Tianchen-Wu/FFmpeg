import Foundation

public struct LocatedExecutable: Equatable, Sendable {
    public let name: String
    public let url: URL

    public var path: String { url.path }

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

public struct FFmpegLocator: Sendable {
    public let bundledRuntimeRoot: URL?
    public let defaultSearchPaths: [String]
    private let environmentPath: String

    public init(
        bundledRuntimeRoot: URL? = Bundle.main.resourceURL?.appendingPathComponent("Runtime/ffmpeg"),
        searchPaths: [String] = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"],
        environmentPath: String = ProcessInfo.processInfo.environment["PATH"] ?? ""
    ) {
        self.bundledRuntimeRoot = bundledRuntimeRoot
        self.defaultSearchPaths = searchPaths
        self.environmentPath = environmentPath
    }

    public func locate(named executableName: String) -> LocatedExecutable? {
        let pathSearchDirectories = environmentPath.split(separator: ":").map(String.init)
        let bundledBin = bundledRuntimeRoot?.appendingPathComponent("bin").path
        let searchDirectories = [bundledBin].compactMap { $0 } + pathSearchDirectories + defaultSearchPaths
        for directory in searchDirectories {
            let candidate = URL(fileURLWithPath: directory).appendingPathComponent(executableName)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return LocatedExecutable(name: executableName, url: candidate)
            }
        }
        return nil
    }

    public func locateFFmpegPair() -> (ffmpeg: LocatedExecutable?, ffprobe: LocatedExecutable?) {
        (locate(named: "ffmpeg"), locate(named: "ffprobe"))
    }
}
