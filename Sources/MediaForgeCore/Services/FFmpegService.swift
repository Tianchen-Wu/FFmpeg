import Foundation

public actor FFmpegService: ConversionRunning {
    private let ffmpegURL: URL
    private let commandBuilder: CommandBuilder
    private let errorMapper: ErrorMapper
    private let logService: LogService
    private var currentProcess: Process?

    public init(
        ffmpegURL: URL,
        commandBuilder: CommandBuilder = CommandBuilder(),
        errorMapper: ErrorMapper = ErrorMapper(),
        logService: LogService = LogService()
    ) {
        self.ffmpegURL = ffmpegURL
        self.commandBuilder = commandBuilder
        self.errorMapper = errorMapper
        self.logService = logService
    }

    public func cancelCurrent() {
        currentProcess?.terminate()
    }

    public func run(job: ConversionJob, progress: @escaping @Sendable (Double?) -> Void) async -> ConversionResult {
        let arguments = commandBuilder.build(
            inputURL: job.inputURL,
            outputURL: job.outputURL,
            preset: job.preset,
            advancedOptions: job.advancedOptions
        )
        let startedAt = Date()
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = arguments

        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = Pipe()
        currentProcess = process

        let logBox = LockedString()
        let duration = job.duration
        stderr.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            logBox.append(chunk)
            if let seconds = TimeParser.progressTime(fromFFmpegLine: chunk) {
                if let duration, duration > 0 {
                    progress(min(max(seconds / duration, 0), 1))
                } else {
                    progress(nil)
                }
            }
        }

        do {
            try process.run()
            process.waitUntilExit()
            stderr.fileHandleForReading.readabilityHandler = nil
            currentProcess = nil

            let rawLog = logBox.value
            let endedAt = Date()
            let logURL = try? logService.save(
                ConversionLog(
                    taskID: job.id,
                    inputPath: job.inputURL.path,
                    outputPath: job.outputURL.path,
                    commandArguments: arguments,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    exitCode: process.terminationStatus,
                    rawLog: rawLog
                )
            )

            if process.terminationStatus == 0 {
                progress(1.0)
                return .success(ConversionSuccess(outputURL: job.outputURL, logURL: logURL))
            }

            if process.terminationReason == .uncaughtSignal {
                let mapped = UserFacingErrorMessage(title: "转换已取消", suggestion: "用户取消了当前转换任务。")
                return .cancelled(ConversionFailure(message: mapped.title, suggestion: mapped.suggestion, rawLog: rawLog, logURL: logURL))
            }

            let mapped = errorMapper.map(rawLog: rawLog)
            return .failure(ConversionFailure(message: mapped.title, suggestion: mapped.suggestion, rawLog: rawLog, logURL: logURL))
        } catch {
            stderr.fileHandleForReading.readabilityHandler = nil
            currentProcess = nil
            return .failure(ConversionFailure(message: "无法启动 FFmpeg", suggestion: error.localizedDescription))
        }
    }
}

private final class LockedString: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = ""

    var value: String {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ string: String) {
        lock.lock()
        storage += string
        lock.unlock()
    }
}
