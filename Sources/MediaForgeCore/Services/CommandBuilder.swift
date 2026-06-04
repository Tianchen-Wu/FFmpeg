import Foundation

public struct CommandBuilder: Sendable {
    public init() {}

    public func build(
        inputURL: URL,
        outputURL: URL,
        preset: ConversionPreset,
        advancedOptions: AdvancedOptions,
        overwrite: Bool = true
    ) -> [String] {
        var arguments: [String] = []
        arguments.append(overwrite ? "-y" : "-n")
        arguments.append(contentsOf: ["-i", inputURL.path])
        arguments.append(contentsOf: preset.arguments)
        arguments.append(contentsOf: advancedArguments(for: preset.conversionType, options: advancedOptions))
        arguments.append(outputURL.path)
        return arguments
    }

    private func advancedArguments(for conversionType: ConversionType, options: AdvancedOptions) -> [String] {
        var arguments: [String] = []

        if let audioBitrate = options.audioBitrate, !audioBitrate.isEmpty {
            arguments.append(contentsOf: ["-b:a", audioBitrate])
        }
        if let sampleRate = options.sampleRate {
            arguments.append(contentsOf: ["-ar", String(sampleRate)])
        }
        if let channels = options.channels {
            arguments.append(contentsOf: ["-ac", String(channels)])
        }
        if conversionType == .videoToVideo {
            if let encoder = options.videoEncoder, !encoder.isEmpty {
                arguments.append(contentsOf: ["-codec:v", encoder])
            }
            if let crf = options.crf {
                arguments.append(contentsOf: ["-crf", String(crf)])
            }
            if let videoBitrate = options.videoBitrate, !videoBitrate.isEmpty {
                arguments.append(contentsOf: ["-b:v", videoBitrate])
            }
        }

        return arguments
    }
}
