import Foundation
import XCTest
@testable import MediaForgeCore

final class FileNamingServiceTests: XCTestCase {
    func testCreatesAudioNameInSourceDirectory() throws {
        let input = URL(fileURLWithPath: "/tmp/race 2024.mp4")
        let preset = try XCTUnwrap(PresetCatalog.videoToAudio.first { $0.id == "vta_mp3_high" })

        let output = try FileNamingService().outputURL(for: input, preset: preset, location: .sourceDirectory, conflictStrategy: .autoRename)

        XCTAssertEqual(output.lastPathComponent, "race 2024_audio.mp3")
    }

    func testAutoRenamesExistingFile() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let input = directory.appendingPathComponent("lecture.mov")
        FileManager.default.createFile(atPath: input.path, contents: Data())
        FileManager.default.createFile(atPath: directory.appendingPathComponent("lecture_h264.mp4").path, contents: Data())
        let preset = try XCTUnwrap(PresetCatalog.videoToVideo.first { $0.id == "vtv_mp4_h264_general" })

        let output = try FileNamingService().outputURL(for: input, preset: preset, location: .sourceDirectory, conflictStrategy: .autoRename)

        XCTAssertEqual(output.lastPathComponent, "lecture_h264_1.mp4")
    }
}
