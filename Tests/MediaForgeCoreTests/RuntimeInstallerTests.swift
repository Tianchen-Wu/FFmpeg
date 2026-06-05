import XCTest
@testable import MediaForgeCore

final class RuntimeInstallerTests: XCTestCase {
    func testHomebrewInstallScriptInstallsFFmpegWithoutSudo() {
        let script = RuntimeInstaller.homebrewInstallScript()

        XCTAssertTrue(script.contains("raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"))
        XCTAssertTrue(script.contains("brew install ffmpeg"))
        XCTAssertTrue(script.contains("command -v brew"))
        XCTAssertFalse(script.contains("sudo "))
    }

    func testParsesRuntimeProgressMarker() {
        let progress = RuntimeInstaller.parseProgressLine(
            "__MEDIAFORGE_RUNTIME_PROGRESS__|0.55|正在安装 Homebrew"
        )

        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.fraction ?? -1, 0.55, accuracy: 0.001)
        XCTAssertEqual(progress?.message, "正在安装 Homebrew")
    }

    func testIgnoresRegularInstallerOutputAsProgressMarker() {
        XCTAssertNil(RuntimeInstaller.parseProgressLine("==> Installing ffmpeg"))
    }

    func testGeneratedInstallScriptHasValidZshSyntax() throws {
        let scriptURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mediaforge-runtime-\(UUID().uuidString).zsh")
        try RuntimeInstaller.homebrewInstallScript().write(to: scriptURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-n", scriptURL.path]
        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)
    }

    func testDiskSpaceEstimateLeavesRoomForHomebrewDependencies() {
        XCTAssertGreaterThanOrEqual(RuntimeInstaller.recommendedFreeSpaceMegabytes, 1_024)
        XCTAssertGreaterThanOrEqual(RuntimeInstaller.linkedRuntimeEstimateMegabytes, 350)
    }
}
