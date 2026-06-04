import Foundation
import XCTest
@testable import MediaForgeCore

final class FFmpegLocatorTests: XCTestCase {
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
