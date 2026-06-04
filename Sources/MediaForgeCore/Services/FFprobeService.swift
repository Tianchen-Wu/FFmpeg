import Foundation

public struct FFprobeService: Sendable {
    private let ffprobeURL: URL
    private let runner: any ProcessRunning

    public init(ffprobeURL: URL, runner: any ProcessRunning = DefaultProcessRunner()) {
        self.ffprobeURL = ffprobeURL
        self.runner = runner
    }

    public func inspect(url: URL) async throws -> MediaInfo {
        let result = try await runner.run(
            executableURL: ffprobeURL,
            arguments: ["-v", "error", "-print_format", "json", "-show_format", "-show_streams", url.path]
        )
        guard result.exitCode == 0 else {
            throw FFprobeError.failed(result.standardError)
        }
        return try Self.parseMediaInfo(from: Data(result.standardOutput.utf8))
    }

    public static func parseMediaInfo(from data: Data) throws -> MediaInfo {
        let response = try JSONDecoder().decode(FFprobeResponse.self, from: data)
        let video = response.streams.first { $0.codecType == "video" }
        let audio = response.streams.first { $0.codecType == "audio" }
        let audioCount = response.streams.filter { $0.codecType == "audio" }.count
        let subtitleCount = response.streams.filter { $0.codecType == "subtitle" }.count

        let mediaType: MediaType
        if video != nil {
            mediaType = .video
        } else if audio != nil {
            mediaType = .audio
        } else {
            mediaType = .unknown
        }

        return MediaInfo(
            mediaType: mediaType,
            duration: response.format.duration.flatMap(Double.init),
            formatName: response.format.formatName,
            bitRate: response.format.bitRate.flatMap(Int64.init),
            size: response.format.size.flatMap(Int64.init),
            videoCodec: video?.codecName,
            audioCodec: audio?.codecName,
            width: video?.width,
            height: video?.height,
            frameRate: video?.frameRateValue,
            sampleRate: audio?.sampleRate.flatMap(Int.init),
            channels: audio?.channels,
            audioStreamCount: audioCount,
            subtitleStreamCount: subtitleCount
        )
    }
}

public enum FFprobeError: Error, Equatable {
    case failed(String)
}

private struct FFprobeResponse: Decodable {
    let streams: [FFprobeStream]
    let format: FFprobeFormat
}

private struct FFprobeFormat: Decodable {
    let duration: String?
    let formatName: String?
    let bitRate: String?
    let size: String?

    enum CodingKeys: String, CodingKey {
        case duration
        case formatName = "format_name"
        case bitRate = "bit_rate"
        case size
    }
}

private struct FFprobeStream: Decodable {
    let codecType: String?
    let codecName: String?
    let width: Int?
    let height: Int?
    let rFrameRate: String?
    let sampleRate: String?
    let channels: Int?

    var frameRateValue: Double? {
        guard let rFrameRate, rFrameRate != "0/0" else { return nil }
        let parts = rFrameRate.split(separator: "/")
        if parts.count == 2,
           let numerator = Double(parts[0]),
           let denominator = Double(parts[1]),
           denominator != 0 {
            return numerator / denominator
        }
        return Double(rFrameRate)
    }

    enum CodingKeys: String, CodingKey {
        case codecType = "codec_type"
        case codecName = "codec_name"
        case width
        case height
        case rFrameRate = "r_frame_rate"
        case sampleRate = "sample_rate"
        case channels
    }
}
