import XCTest
@testable import MediaForgeCore

final class ProgressPresentationTests: XCTestCase {
    func testHidesProgressWhenNotConverting() {
        let presentation = ProgressPresentation(
            isConverting: false,
            currentProgress: nil,
            overallProgress: 1
        )

        XCTAssertFalse(presentation.shouldShowProgress)
        XCTAssertEqual(presentation.currentPercentText, "")
        XCTAssertEqual(presentation.overallPercentText, "")
    }

    func testShowsPercentagesWhenConverting() {
        let presentation = ProgressPresentation(
            isConverting: true,
            currentProgress: 0.426,
            overallProgress: 0.9
        )

        XCTAssertTrue(presentation.shouldShowProgress)
        XCTAssertEqual(presentation.currentPercentText, "43%")
        XCTAssertEqual(presentation.overallPercentText, "90%")
    }

    func testUnknownConvertingProgressDoesNotCreateIndeterminateBar() {
        let presentation = ProgressPresentation(
            isConverting: true,
            currentProgress: nil,
            overallProgress: nil
        )

        XCTAssertTrue(presentation.shouldShowProgress)
        XCTAssertFalse(presentation.hasCurrentBar)
        XCTAssertFalse(presentation.hasOverallBar)
        XCTAssertEqual(presentation.currentPercentText, "--")
        XCTAssertEqual(presentation.overallPercentText, "--")
    }
}
