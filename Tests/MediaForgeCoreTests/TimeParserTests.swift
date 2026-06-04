import XCTest
@testable import MediaForgeCore

final class TimeParserTests: XCTestCase {
    func testParsesFFmpegTimestamp() {
        XCTAssertEqual(TimeParser.seconds(from: "00:01:02.50") ?? -1, 62.5, accuracy: 0.001)
    }

    func testExtractsTimeFromStderrLine() {
        let line = "frame=100 fps=25 time=00:00:04.20 bitrate=1234.5kbits/s"
        XCTAssertEqual(TimeParser.progressTime(fromFFmpegLine: line) ?? -1, 4.2, accuracy: 0.001)
    }

    func testReturnsNilForInvalidTime() {
        XCTAssertNil(TimeParser.seconds(from: "not-a-time"))
    }
}
