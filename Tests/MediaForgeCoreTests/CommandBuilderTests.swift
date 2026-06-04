import Foundation
import XCTest
@testable import MediaForgeCore

final class CommandBuilderTests: XCTestCase {
    func testPresetCatalogContainsRequiredGroups() {
        XCTAssertEqual(PresetCatalog.videoToAudio.count, 6)
        XCTAssertEqual(PresetCatalog.audioToAudio.count, 6)
        XCTAssertEqual(PresetCatalog.videoToVideo.count, 6)
        XCTAssertTrue(PresetCatalog.videoToVideo.contains { $0.id == "vtv_mp4_h264_general" })
    }

    func testBuildsVideoToAudioMP3ArgumentsWithoutShellString() throws {
        let input = URL(fileURLWithPath: "/tmp/中文 path/input video.mp4")
        let output = URL(fileURLWithPath: "/tmp/中文 path/input_audio.mp3")
        let preset = try XCTUnwrap(PresetCatalog.videoToAudio.first { $0.id == "vta_mp3_high" })

        let args = CommandBuilder().build(inputURL: input, outputURL: output, preset: preset, advancedOptions: AdvancedOptions())

        XCTAssertEqual(args, ["-y", "-i", input.path, "-vn", "-codec:a", "libmp3lame", "-q:a", "2", output.path])
        XCTAssertFalse(args.joined(separator: " ").contains("ffmpeg -i"))
    }

    func testAppliesAdvancedAudioOptionsAfterPresetArguments() throws {
        let input = URL(fileURLWithPath: "/tmp/in.m4a")
        let output = URL(fileURLWithPath: "/tmp/out.wav")
        let preset = try XCTUnwrap(PresetCatalog.audioToAudio.first { $0.id == "ata_wav_pcm" })

        let args = CommandBuilder().build(inputURL: input, outputURL: output, preset: preset, advancedOptions: AdvancedOptions(sampleRate: 16000, channels: 1))

        XCTAssertTrue(args.contains("-ar"))
        XCTAssertTrue(args.contains("16000"))
        XCTAssertTrue(args.contains("-ac"))
        XCTAssertTrue(args.contains("1"))
    }
}
