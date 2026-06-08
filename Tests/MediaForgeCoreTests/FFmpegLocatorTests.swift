import Foundation
import XCTest
@testable import MediaForgeCore

final class FFmpegLocatorTests: XCTestCase {
    func testLocatorChecksBundledRuntimeBeforeSystemPaths() throws {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let runtimeBin = temp.appendingPathComponent("Runtime/ffmpeg/bin")
        let systemBin = temp.appendingPathComponent("System/bin")
        try FileManager.default.createDirectory(at: runtimeBin, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: systemBin, withIntermediateDirectories: true)

        let bundledFFmpeg = runtimeBin.appendingPathComponent("ffmpeg")
        let systemFFmpeg = systemBin.appendingPathComponent("ffmpeg")
        try "#!/bin/sh\necho bundled\n".write(to: bundledFFmpeg, atomically: true, encoding: .utf8)
        try "#!/bin/sh\necho system\n".write(to: systemFFmpeg, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: bundledFFmpeg.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: systemFFmpeg.path)

        let locator = FFmpegLocator(
            bundledRuntimeRoot: temp.appendingPathComponent("Runtime/ffmpeg"),
            searchPaths: [systemBin.path],
            environmentPath: ""
        )

        XCTAssertEqual(locator.locate(named: "ffmpeg")?.path, bundledFFmpeg.path)
    }

    func testLocatorFindsExecutableInProvidedSearchPaths() throws {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        let ffmpeg = temp.appendingPathComponent("ffmpeg")
        try "#!/bin/sh\necho ffmpeg\n".write(to: ffmpeg, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ffmpeg.path)

        let result = FFmpegLocator(searchPaths: [temp.path], environmentPath: "").locate(named: "ffmpeg")

        XCTAssertEqual(result?.path, ffmpeg.path)
    }

    func testLocatorChecksHomebrewPathsBeforeSystemPaths() {
        let locator = FFmpegLocator(searchPaths: ["/opt/homebrew/bin", "/usr/local/bin"], environmentPath: "")

        XCTAssertEqual(Array(locator.defaultSearchPaths.prefix(2)), ["/opt/homebrew/bin", "/usr/local/bin"])
    }
}
