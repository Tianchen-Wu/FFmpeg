import Foundation

public enum FileNamingError: Error, Equatable {
    case skipped(URL)
}

public struct FileNamingService: Sendable {
    public init() {}

    public func outputURL(
        for inputURL: URL,
        preset: ConversionPreset,
        location: OutputLocationStrategy,
        conflictStrategy: ConflictStrategy
    ) throws -> URL {
        let directory: URL
        switch location {
        case .sourceDirectory:
            directory = inputURL.deletingLastPathComponent()
        case .unifiedDirectory(let url):
            directory = url
        }

        let baseName = inputURL.deletingPathExtension().lastPathComponent
        let candidate = directory
            .appendingPathComponent(baseName + suffixForPreset(id: preset.id))
            .appendingPathExtension(preset.outputFormat.rawValue)

        switch conflictStrategy {
        case .overwrite:
            return candidate
        case .skip:
            if FileManager.default.fileExists(atPath: candidate.path) {
                throw FileNamingError.skipped(candidate)
            }
            return candidate
        case .autoRename:
            return autoRenamed(candidate)
        }
    }

    private func suffixForPreset(id: String) -> String {
        if id.contains("whisper") { return "_whisper" }
        if id.contains("h264") { return "_h264" }
        if id.contains("h265") { return "_h265" }
        if id.contains("av1") { return "_av1" }
        if id.contains("webm") { return "_webm" }
        if id.contains("copy") { return "_copy" }
        if id.hasPrefix("vta") { return "_audio" }
        return "_converted"
    }

    private func autoRenamed(_ url: URL) -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else { return url }
        let directory = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var index = 1
        while true {
            let next = directory.appendingPathComponent("\(base)_\(index)").appendingPathExtension(ext)
            if !FileManager.default.fileExists(atPath: next.path) {
                return next
            }
            index += 1
        }
    }
}
