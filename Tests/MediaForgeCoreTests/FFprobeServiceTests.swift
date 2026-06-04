import Foundation
import XCTest
@testable import MediaForgeCore

final class FFprobeServiceTests: XCTestCase {
    func testParsesVideoMediaInfo() throws {
        let json = """
        {
          "streams": [
            {"codec_type": "video", "codec_name": "h264", "width": 1920, "height": 1080, "r_frame_rate": "30000/1001"},
            {"codec_type": "audio", "codec_name": "aac", "sample_rate": "48000", "channels": 2},
            {"codec_type": "subtitle", "codec_name": "mov_text"}
          ],
          "format": {"duration": "12.5", "format_name": "mov,mp4,m4a,3gp,3g2,mj2", "bit_rate": "1000000", "size": "1500000"}
        }
        """

        let info = try FFprobeService.parseMediaInfo(from: Data(json.utf8))

        XCTAssertEqual(info.mediaType, .video)
        XCTAssertEqual(info.duration, 12.5)
        XCTAssertEqual(info.videoCodec, "h264")
        XCTAssertEqual(info.audioCodec, "aac")
        XCTAssertEqual(info.width, 1920)
        XCTAssertEqual(info.height, 1080)
        XCTAssertEqual(info.sampleRate, 48000)
        XCTAssertEqual(info.channels, 2)
        XCTAssertEqual(info.audioStreamCount, 1)
        XCTAssertEqual(info.subtitleStreamCount, 1)
    }
}
