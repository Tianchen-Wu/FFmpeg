import XCTest
@testable import MediaForgeCore

final class ErrorMapperTests: XCTestCase {
    func testMapsUnknownEncoder() {
        let message = ErrorMapper().map(rawLog: "Unknown encoder 'libmp3lame'")

        XCTAssertTrue(message.title.contains("编码器"))
        XCTAssertTrue(message.suggestion.contains("FFmpeg"))
    }

    func testMapsPermissionError() {
        let message = ErrorMapper().map(rawLog: "Permission denied")

        XCTAssertTrue(message.title.contains("权限"))
    }
}
