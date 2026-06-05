import XCTest
@testable import MediaForgeCore

final class RuntimeInstallerTests: XCTestCase {
    func testHomebrewInstallScriptInstallsFFmpegWithoutSudo() {
        let script = RuntimeInstaller.homebrewInstallScript()

        XCTAssertTrue(script.contains("brew install ffmpeg"))
        XCTAssertTrue(script.contains("command -v brew"))
        XCTAssertFalse(script.contains("sudo "))
    }

    func testDiskSpaceEstimateLeavesRoomForHomebrewDependencies() {
        XCTAssertGreaterThanOrEqual(RuntimeInstaller.recommendedFreeSpaceMegabytes, 1_024)
        XCTAssertGreaterThanOrEqual(RuntimeInstaller.linkedRuntimeEstimateMegabytes, 350)
    }
}
