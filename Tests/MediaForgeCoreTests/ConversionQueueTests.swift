import Foundation
import XCTest
@testable import MediaForgeCore

final class ConversionQueueTests: XCTestCase {
    func testQueueContinuesAfterFailure() async {
        let runner = FakeConversionRunner(results: [.failure("bad file"), .success])
        let queue = ConversionQueue(runner: runner)
        let jobs = [
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/a.mp4"), outputURL: URL(fileURLWithPath: "/tmp/a.mp3"), preset: PresetCatalog.videoToAudio[0]),
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/b.mp4"), outputURL: URL(fileURLWithPath: "/tmp/b.mp3"), preset: PresetCatalog.videoToAudio[0])
        ]

        let results = await queue.run(jobs: jobs)

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results[0].isFailure)
        XCTAssertTrue(results[1].isSuccess)
    }
}

private actor FakeConversionRunner: ConversionRunning {
    enum FakeResult {
        case success
        case failure(String)
    }

    private var results: [FakeResult]

    init(results: [FakeResult]) {
        self.results = results
    }

    func run(job: ConversionJob, progress: @escaping @Sendable (Double?) -> Void) async -> ConversionResult {
        let result = results.removeFirst()
        switch result {
        case .success:
            progress(1.0)
            return .success(ConversionSuccess(outputURL: job.outputURL))
        case .failure(let message):
            return .failure(ConversionFailure(message: message, suggestion: "check file"))
        }
    }

    func cancelCurrent() {}
}
