import XCTest
@testable import MediaForgeCore

final class AppMetadataTests: XCTestCase {
    func testDisplayNameIsFFmpeg() {
        XCTAssertEqual(AppMetadata.displayName, "FFmpeg")
    }
}
