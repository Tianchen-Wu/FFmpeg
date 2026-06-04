import Foundation

public enum MediaType: String, Codable, Sendable {
    case video
    case audio
    case unknown
}

public enum ConversionType: String, Codable, CaseIterable, Sendable {
    case auto
    case videoToAudio
    case videoToVideo
    case audioToAudio
}

public enum OutputFormat: String, Codable, CaseIterable, Sendable {
    case mp3
    case m4a
    case aac
    case wav
    case flac
    case ogg
    case opus
    case aiff
    case mp4
    case mov
    case mkv
    case webm
    case avi
    case m4v
}

public enum ConflictStrategy: String, Codable, CaseIterable, Sendable {
    case autoRename
    case skip
    case overwrite
}

public enum OutputLocationStrategy: Equatable, Sendable {
    case sourceDirectory
    case unifiedDirectory(URL)
}

public enum ConversionStatus: Equatable, Sendable {
    case analyzing
    case queued
    case converting(progress: Double?)
    case completed(outputURL: URL)
    case failed(message: String)
    case cancelled
}

public struct MediaInfo: Equatable, Sendable {
    public var mediaType: MediaType
    public var duration: Double?
    public var formatName: String?
    public var bitRate: Int64?
    public var size: Int64?
    public var videoCodec: String?
    public var audioCodec: String?
    public var width: Int?
    public var height: Int?
    public var frameRate: Double?
    public var sampleRate: Int?
    public var channels: Int?
    public var audioStreamCount: Int
    public var subtitleStreamCount: Int

    public init(
        mediaType: MediaType,
        duration: Double? = nil,
        formatName: String? = nil,
        bitRate: Int64? = nil,
        size: Int64? = nil,
        videoCodec: String? = nil,
        audioCodec: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        frameRate: Double? = nil,
        sampleRate: Int? = nil,
        channels: Int? = nil,
        audioStreamCount: Int = 0,
        subtitleStreamCount: Int = 0
    ) {
        self.mediaType = mediaType
        self.duration = duration
        self.formatName = formatName
        self.bitRate = bitRate
        self.size = size
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.sampleRate = sampleRate
        self.channels = channels
        self.audioStreamCount = audioStreamCount
        self.subtitleStreamCount = subtitleStreamCount
    }
}

public struct MediaFile: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let inputURL: URL
    public var fileName: String
    public var fileSize: Int64
    public var mediaInfo: MediaInfo?
    public var status: ConversionStatus
    public var outputURL: URL?
    public var logURL: URL?

    public init(
        id: UUID = UUID(),
        inputURL: URL,
        fileSize: Int64,
        mediaInfo: MediaInfo? = nil,
        status: ConversionStatus = .analyzing,
        outputURL: URL? = nil,
        logURL: URL? = nil
    ) {
        self.id = id
        self.inputURL = inputURL
        self.fileName = inputURL.lastPathComponent
        self.fileSize = fileSize
        self.mediaInfo = mediaInfo
        self.status = status
        self.outputURL = outputURL
        self.logURL = logURL
    }
}

public struct AdvancedOptions: Equatable, Sendable {
    public var audioBitrate: String?
    public var sampleRate: Int?
    public var channels: Int?
    public var videoEncoder: String?
    public var crf: Int?
    public var videoBitrate: String?

    public init(
        audioBitrate: String? = nil,
        sampleRate: Int? = nil,
        channels: Int? = nil,
        videoEncoder: String? = nil,
        crf: Int? = nil,
        videoBitrate: String? = nil
    ) {
        self.audioBitrate = audioBitrate
        self.sampleRate = sampleRate
        self.channels = channels
        self.videoEncoder = videoEncoder
        self.crf = crf
        self.videoBitrate = videoBitrate
    }
}

public struct ConversionJob: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let inputURL: URL
    public let outputURL: URL
    public let preset: ConversionPreset
    public let advancedOptions: AdvancedOptions
    public let duration: Double?

    public init(
        id: UUID = UUID(),
        inputURL: URL,
        outputURL: URL,
        preset: ConversionPreset,
        advancedOptions: AdvancedOptions = AdvancedOptions(),
        duration: Double? = nil
    ) {
        self.id = id
        self.inputURL = inputURL
        self.outputURL = outputURL
        self.preset = preset
        self.advancedOptions = advancedOptions
        self.duration = duration
    }
}

public enum ConversionResult: Equatable, Sendable {
    case success(ConversionSuccess)
    case failure(ConversionFailure)
    case cancelled(ConversionFailure?)

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    public var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

public struct ConversionSuccess: Equatable, Sendable {
    public let outputURL: URL
    public let logURL: URL?

    public init(outputURL: URL, logURL: URL? = nil) {
        self.outputURL = outputURL
        self.logURL = logURL
    }
}

public struct ConversionFailure: Equatable, Sendable {
    public let message: String
    public let suggestion: String
    public let rawLog: String
    public let logURL: URL?

    public init(message: String, suggestion: String, rawLog: String = "", logURL: URL? = nil) {
        self.message = message
        self.suggestion = suggestion
        self.rawLog = rawLog
        self.logURL = logURL
    }
}
