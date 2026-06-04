import Foundation

public protocol ConversionRunning: Actor {
    func run(job: ConversionJob, progress: @escaping @Sendable (Double?) -> Void) async -> ConversionResult
    func cancelCurrent()
}

public actor ConversionQueue {
    private let runner: any ConversionRunning
    private var isCancelled = false

    public init(runner: any ConversionRunning) {
        self.runner = runner
    }

    public func cancelAll() async {
        isCancelled = true
        await runner.cancelCurrent()
    }

    public func run(
        jobs: [ConversionJob],
        progress: @escaping @Sendable (UUID, Double?) -> Void = { _, _ in }
    ) async -> [ConversionResult] {
        isCancelled = false
        var results: [ConversionResult] = []

        for job in jobs {
            if isCancelled {
                results.append(.cancelled(nil))
                continue
            }

            let result = await runner.run(job: job) { value in
                progress(job.id, value)
            }
            results.append(result)
        }

        return results
    }
}
