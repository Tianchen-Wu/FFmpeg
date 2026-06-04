import Foundation

public struct ConversionPreset: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let nameKey: String
    public let displayName: String
    public let detail: String
    public let conversionType: ConversionType
    public let outputFormat: OutputFormat
    public let arguments: [String]
    public let requiredEncoders: [String]
    public let isAdvanced: Bool

    public init(
        id: String,
        nameKey: String,
        displayName: String,
        detail: String,
        conversionType: ConversionType,
        outputFormat: OutputFormat,
        arguments: [String],
        requiredEncoders: [String] = [],
        isAdvanced: Bool = false
    ) {
        self.id = id
        self.nameKey = nameKey
        self.displayName = displayName
        self.detail = detail
        self.conversionType = conversionType
        self.outputFormat = outputFormat
        self.arguments = arguments
        self.requiredEncoders = requiredEncoders
        self.isAdvanced = isAdvanced
    }
}

public enum PresetCatalog {
    public static let all: [ConversionPreset] = videoToAudio + audioToAudio + videoToVideo

    public static func presets(for conversionType: ConversionType) -> [ConversionPreset] {
        switch conversionType {
        case .auto:
            return all
        case .videoToAudio:
            return videoToAudio
        case .videoToVideo:
            return videoToVideo
        case .audioToAudio:
            return audioToAudio
        }
    }

    public static let videoToAudio: [ConversionPreset] = [
        .init(id: "vta_mp3_high", nameKey: "preset.vta.mp3High.name", displayName: "MP3 通用高质量", detail: "libmp3lame · q:a 2", conversionType: .videoToAudio, outputFormat: .mp3, arguments: ["-vn", "-codec:a", "libmp3lame", "-q:a", "2"], requiredEncoders: ["libmp3lame"]),
        .init(id: "vta_m4a_general", nameKey: "preset.vta.m4a.name", displayName: "M4A 通用", detail: "AAC · 192k", conversionType: .videoToAudio, outputFormat: .m4a, arguments: ["-vn", "-codec:a", "aac", "-b:a", "192k"], requiredEncoders: ["aac"]),
        .init(id: "vta_wav_pcm", nameKey: "preset.vta.wav.name", displayName: "WAV 无压缩", detail: "pcm_s16le", conversionType: .videoToAudio, outputFormat: .wav, arguments: ["-vn", "-codec:a", "pcm_s16le"], requiredEncoders: ["pcm_s16le"]),
        .init(id: "vta_flac", nameKey: "preset.vta.flac.name", displayName: "FLAC 无损压缩", detail: "FLAC", conversionType: .videoToAudio, outputFormat: .flac, arguments: ["-vn", "-codec:a", "flac"], requiredEncoders: ["flac"]),
        .init(id: "vta_whisper_wav", nameKey: "preset.vta.whisper.name", displayName: "Whisper WAV", detail: "16kHz · 单声道 · pcm_s16le", conversionType: .videoToAudio, outputFormat: .wav, arguments: ["-vn", "-ac", "1", "-ar", "16000", "-codec:a", "pcm_s16le"], requiredEncoders: ["pcm_s16le"]),
        .init(id: "vta_copy_audio", nameKey: "preset.vta.copy.name", displayName: "无损复制音轨", detail: "-c:a copy · 仅兼容时使用", conversionType: .videoToAudio, outputFormat: .m4a, arguments: ["-vn", "-c:a", "copy"], isAdvanced: true)
    ]

    public static let audioToAudio: [ConversionPreset] = [
        .init(id: "ata_mp3_high", nameKey: "preset.ata.mp3High.name", displayName: "MP3 通用高质量", detail: "libmp3lame · q:a 2", conversionType: .audioToAudio, outputFormat: .mp3, arguments: ["-codec:a", "libmp3lame", "-q:a", "2"], requiredEncoders: ["libmp3lame"]),
        .init(id: "ata_m4a_general", nameKey: "preset.ata.m4a.name", displayName: "M4A 通用", detail: "AAC · 192k", conversionType: .audioToAudio, outputFormat: .m4a, arguments: ["-codec:a", "aac", "-b:a", "192k"], requiredEncoders: ["aac"]),
        .init(id: "ata_wav_pcm", nameKey: "preset.ata.wav.name", displayName: "WAV 无压缩", detail: "pcm_s16le", conversionType: .audioToAudio, outputFormat: .wav, arguments: ["-codec:a", "pcm_s16le"], requiredEncoders: ["pcm_s16le"]),
        .init(id: "ata_flac", nameKey: "preset.ata.flac.name", displayName: "FLAC 无损压缩", detail: "FLAC", conversionType: .audioToAudio, outputFormat: .flac, arguments: ["-codec:a", "flac"], requiredEncoders: ["flac"]),
        .init(id: "ata_opus_small", nameKey: "preset.ata.opus.name", displayName: "Opus 小体积", detail: "libopus · 96k", conversionType: .audioToAudio, outputFormat: .opus, arguments: ["-codec:a", "libopus", "-b:a", "96k"], requiredEncoders: ["libopus"]),
        .init(id: "ata_whisper_wav", nameKey: "preset.ata.whisper.name", displayName: "Whisper WAV", detail: "16kHz · 单声道 · pcm_s16le", conversionType: .audioToAudio, outputFormat: .wav, arguments: ["-ac", "1", "-ar", "16000", "-codec:a", "pcm_s16le"], requiredEncoders: ["pcm_s16le"])
    ]

    public static let videoToVideo: [ConversionPreset] = [
        .init(id: "vtv_mp4_h264_general", nameKey: "preset.vtv.h264General.name", displayName: "MP4 通用兼容", detail: "H.264 · CRF 23 · AAC 192k", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec:v", "libx264", "-preset", "medium", "-crf", "23", "-codec:a", "aac", "-b:a", "192k"], requiredEncoders: ["libx264", "aac"]),
        .init(id: "vtv_mp4_h264_high", nameKey: "preset.vtv.h264High.name", displayName: "MP4 高质量", detail: "H.264 · CRF 18 · AAC 256k", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec:v", "libx264", "-preset", "slow", "-crf", "18", "-codec:a", "aac", "-b:a", "256k"], requiredEncoders: ["libx264", "aac"]),
        .init(id: "vtv_mp4_h265_small", nameKey: "preset.vtv.h265Small.name", displayName: "MP4 小体积", detail: "H.265 · CRF 28 · AAC 128k", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec:v", "libx265", "-crf", "28", "-codec:a", "aac", "-b:a", "128k"], requiredEncoders: ["libx265", "aac"]),
        .init(id: "vtv_webm_vp9", nameKey: "preset.vtv.webm.name", displayName: "WebM 网页格式", detail: "VP9 · CRF 32 · Opus 96k", conversionType: .videoToVideo, outputFormat: .webm, arguments: ["-codec:v", "libvpx-vp9", "-crf", "32", "-b:v", "0", "-codec:a", "libopus", "-b:a", "96k"], requiredEncoders: ["libvpx-vp9", "libopus"]),
        .init(id: "vtv_mp4_av1", nameKey: "preset.vtv.av1.name", displayName: "AV1 小体积/高级", detail: "libsvtav1 · CRF 35 · 较慢", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec:v", "libsvtav1", "-crf", "35", "-codec:a", "aac", "-b:a", "128k"], requiredEncoders: ["libsvtav1", "aac"], isAdvanced: true),
        .init(id: "vtv_copy_container", nameKey: "preset.vtv.copy.name", displayName: "仅更换封装", detail: "-codec copy · 仅兼容时使用", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec", "copy"], isAdvanced: true)
    ]
}
