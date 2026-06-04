import AppKit
import Foundation
import MediaForgeCore

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHans
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "跟随系统"
        case .zhHans: "中文"
        case .en: "English"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var files: [MediaFile] = []
    @Published var selectedConversionType: ConversionType = .videoToVideo {
        didSet {
            let presets = availablePresets
            if !presets.contains(where: { $0.id == selectedPreset.id }), let first = presets.first {
                selectedPreset = first
            }
        }
    }
    @Published var selectedPreset: ConversionPreset = PresetCatalog.videoToVideo[0]
    @Published var outputLocation: OutputLocationStrategy = .sourceDirectory
    @Published var unifiedOutputDirectory: URL?
    @Published var conflictStrategy: ConflictStrategy = .autoRename
    @Published var advancedOptions = AdvancedOptions()
    @Published var currentProgress: Double?
    @Published var overallProgress: Double?
    @Published var currentIndex = 0
    @Published var totalCount = 0
    @Published var isConverting = false
    @Published var statusMessage = "等待任务"
    @Published var currentLogText = ""
    @Published var language: AppLanguage = .system
    @Published var showSettings = false
    @Published var openOutputDirectoryWhenDone = false

    let locator = FFmpegLocator()
    private let namingService = FileNamingService()
    private let errorMapper = ErrorMapper()
    private var activeService: FFmpegService?
    private var activeQueue: ConversionQueue?

    var ffmpeg: LocatedExecutable? {
        locator.locate(named: "ffmpeg")
    }

    var ffprobe: LocatedExecutable? {
        locator.locate(named: "ffprobe")
    }

    var ffmpegPathSummary: String {
        guard let ffmpeg else { return "未检测到 FFmpeg" }
        return ffmpeg.path
    }

    var availablePresets: [ConversionPreset] {
        PresetCatalog.presets(for: selectedConversionType)
    }

    var failedFiles: [MediaFile] {
        files.filter {
            if case .failed = $0.status { return true }
            return false
        }
    }

    func toggleLanguage() {
        language = language == .zhHans ? .en : .zhHans
    }

    func text(_ key: String) -> String {
        let useEnglish: Bool
        switch language {
        case .system:
            useEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true
        case .zhHans:
            useEnglish = false
        case .en:
            useEnglish = true
        }
        return useEnglish ? Self.englishStrings[key, default: key] : Self.chineseStrings[key, default: key]
    }

    func addFiles(urls: [URL]) {
        let expanded = expandDirectories(urls)
        let existing = Set(files.map(\.inputURL))
        let newFiles = expanded
            .filter { !$0.hasDirectoryPath }
            .filter { !existing.contains($0) }
            .map { url in
                let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
                return MediaFile(inputURL: url, fileSize: size, mediaInfo: nil, status: .analyzing)
            }

        files.append(contentsOf: newFiles)
        analyzeFiles(newFiles.map(\.id))
    }

    func clearFiles() {
        files.removeAll()
        currentProgress = nil
        overallProgress = nil
        currentIndex = 0
        totalCount = 0
        currentLogText = ""
        statusMessage = "等待任务"
    }

    func chooseUnifiedOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "选择输出目录"
        if panel.runModal() == .OK, let url = panel.url {
            unifiedOutputDirectory = url
            outputLocation = .unifiedDirectory(url)
        }
    }

    func useSourceDirectoryOutput() {
        outputLocation = .sourceDirectory
    }

    func openOutputDirectory() {
        guard let url = files.compactMap(\.outputURL).last else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func cancelAll() {
        Task {
            await activeQueue?.cancelAll()
        }
        isConverting = false
        statusMessage = "正在取消"
    }

    func startConversion() {
        guard !files.isEmpty, !isConverting else { return }
        guard let ffmpeg else {
            statusMessage = "未检测到 FFmpeg。请安装 FFmpeg 或检查 Homebrew 路径。"
            return
        }

        let location = effectiveOutputLocation()
        var jobs: [ConversionJob] = []
        var filesByJobID: [UUID: UUID] = [:]

        for file in files {
            guard !isCompleted(file.status) else { continue }
            do {
                let output = try namingService.outputURL(
                    for: file.inputURL,
                    preset: selectedPreset,
                    location: location,
                    conflictStrategy: conflictStrategy
                )
                let job = ConversionJob(
                    inputURL: file.inputURL,
                    outputURL: output,
                    preset: selectedPreset,
                    advancedOptions: advancedOptions,
                    duration: file.mediaInfo?.duration
                )
                jobs.append(job)
                filesByJobID[job.id] = file.id
                updateFile(file.id) {
                    $0.status = .queued
                    $0.outputURL = output
                }
            } catch FileNamingError.skipped(let url) {
                updateFile(file.id) {
                    $0.status = .failed(message: "目标文件已存在，已按设置跳过：\(url.lastPathComponent)")
                }
            } catch {
                updateFile(file.id) {
                    $0.status = .failed(message: "无法生成输出文件名：\(error.localizedDescription)")
                }
            }
        }

        guard !jobs.isEmpty else {
            statusMessage = "没有可转换的任务"
            return
        }

        isConverting = true
        currentProgress = 0
        overallProgress = 0
        currentIndex = 0
        totalCount = jobs.count
        statusMessage = "准备转换"
        currentLogText = ""

        let service = FFmpegService(ffmpegURL: ffmpeg.url)
        let queue = ConversionQueue(runner: service)
        activeService = service
        activeQueue = queue
        let jobOrder = Dictionary(uniqueKeysWithValues: jobs.enumerated().map { ($0.element.id, $0.offset) })
        let fileIDMap = filesByJobID
        let jobCount = jobs.count

        Task {
            let results = await queue.run(jobs: jobs) { [weak self] jobID, progress in
                guard let fileID = fileIDMap[jobID] else { return }
                let completedBefore = jobOrder[jobID] ?? 0
                let currentIndex = completedBefore + 1
                let overall = (Double(completedBefore) + (progress ?? 0)) / Double(max(jobCount, 1))
                Task { @MainActor [weak self, fileID, progress, currentIndex, overall, jobCount] in
                    guard let self else { return }
                    self.currentProgress = progress
                    self.updateFile(fileID) { $0.status = .converting(progress: progress) }
                    self.currentIndex = currentIndex
                    self.overallProgress = overall
                    self.statusMessage = "正在转换 \(currentIndex)/\(jobCount)"
                }
            }

            await MainActor.run {
                self.apply(results: results, jobs: jobs, filesByJobID: filesByJobID)
            }
        }
    }

    private func apply(results: [ConversionResult], jobs: [ConversionJob], filesByJobID: [UUID: UUID]) {
        for (index, result) in results.enumerated() {
            let job = jobs[index]
            guard let fileID = filesByJobID[job.id] else { continue }
            switch result {
            case .success(let success):
                updateFile(fileID) {
                    $0.status = .completed(outputURL: success.outputURL)
                    $0.outputURL = success.outputURL
                    $0.logURL = success.logURL
                }
            case .failure(let failure):
                updateFile(fileID) {
                    $0.status = .failed(message: failure.message)
                    $0.logURL = failure.logURL
                }
                currentLogText = failure.rawLog
            case .cancelled(let failure):
                updateFile(fileID) {
                    $0.status = .cancelled
                    $0.logURL = failure?.logURL
                }
            }
        }

        isConverting = false
        activeService = nil
        activeQueue = nil
        currentProgress = nil
        overallProgress = 1
        let successCount = results.filter(\.isSuccess).count
        let failureCount = results.filter(\.isFailure).count
        statusMessage = "转换完成：成功 \(successCount) 个，失败 \(failureCount) 个"

        if openOutputDirectoryWhenDone {
            openOutputDirectory()
        }
    }

    private func analyzeFiles(_ ids: [UUID]) {
        guard let ffprobe else {
            for id in ids {
                updateFile(id) { $0.status = .queued }
            }
            statusMessage = "未检测到 FFprobe，已跳过媒体分析"
            return
        }

        Task {
            let service = FFprobeService(ffprobeURL: ffprobe.url)
            for id in ids {
                guard let file = files.first(where: { $0.id == id }) else { continue }
                do {
                    let info = try await service.inspect(url: file.inputURL)
                    await MainActor.run {
                        self.updateFile(id) {
                            $0.mediaInfo = info
                            $0.status = .queued
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.updateFile(id) {
                            $0.mediaInfo = self.fallbackMediaInfo(for: file.inputURL)
                            $0.status = .queued
                        }
                    }
                }
            }
        }
    }

    private func fallbackMediaInfo(for url: URL) -> MediaInfo {
        let ext = url.pathExtension.lowercased()
        let video = ["mp4", "mov", "mkv", "avi", "webm", "m4v", "flv", "wmv", "mpg", "mpeg", "ts", "m2ts", "3gp"]
        let audio = ["mp3", "m4a", "aac", "wav", "flac", "ogg", "opus", "wma", "aiff", "alac", "caf"]
        if video.contains(ext) { return MediaInfo(mediaType: .video, formatName: ext) }
        if audio.contains(ext) { return MediaInfo(mediaType: .audio, formatName: ext) }
        return MediaInfo(mediaType: .unknown, formatName: ext)
    }

    private func effectiveOutputLocation() -> OutputLocationStrategy {
        if case .unifiedDirectory = outputLocation, let unifiedOutputDirectory {
            return .unifiedDirectory(unifiedOutputDirectory)
        }
        return .sourceDirectory
    }

    private func expandDirectories(_ urls: [URL]) -> [URL] {
        urls.flatMap { url -> [URL] in
            guard url.hasDirectoryPath else { return [url] }
            let children = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
            return children.filter { !$0.hasDirectoryPath }
        }
    }

    private func updateFile(_ id: UUID, mutate: (inout MediaFile) -> Void) {
        guard let index = files.firstIndex(where: { $0.id == id }) else { return }
        mutate(&files[index])
    }

    private func isCompleted(_ status: ConversionStatus) -> Bool {
        if case .completed = status { return true }
        return false
    }

    private static let chineseStrings: [String: String] = [
        "switch_language": "切换语言",
        "settings": "设置",
        "files": "文件",
        "tasks_count": "个任务",
        "drop_prompt": "拖拽视频或音频文件到这里，或点击选择文件",
        "add_files": "添加文件",
        "add_folder": "添加文件夹",
        "clear_list": "清空列表",
        "file_name": "文件名",
        "type": "类型",
        "duration": "时长",
        "size": "大小",
        "status": "状态",
        "video": "视频",
        "audio": "音频",
        "unknown": "未知",
        "analyzing": "分析中",
        "queued": "等待转换",
        "converting": "转换中",
        "completed": "已完成",
        "failed": "失败",
        "cancelled": "已取消",
        "output_settings": "输出设置",
        "conversion_type": "转换类型",
        "video_to_audio": "视频转音频",
        "video_to_video": "视频转视频",
        "audio_to_audio": "音频转音频",
        "preset": "预设",
        "output_location": "输出位置",
        "source_directory": "原文件同目录",
        "unified_directory": "统一输出目录",
        "no_directory": "未选择目录",
        "choose": "选择",
        "conflict_strategy": "冲突处理",
        "auto_rename": "自动重命名",
        "skip": "跳过",
        "overwrite": "覆盖",
        "open_when_done": "转换完成后打开输出目录",
        "advanced_options": "高级参数",
        "audio_bitrate": "音频码率，例如 192k",
        "sample_rate": "采样率",
        "channels": "声道",
        "video_encoder": "视频编码器，例如 libx264",
        "video_bitrate": "视频码率，例如 4M",
        "cancel": "取消",
        "start": "开始转换",
        "working": "转换中",
        "open_output": "打开输出目录",
        "waiting": "等待任务",
        "log": "日志",
        "copy": "复制",
        "failed_tasks": "失败任务",
        "language": "语言",
        "follow_system": "跟随系统"
    ]

    private static let englishStrings: [String: String] = [
        "switch_language": "Switch Language",
        "settings": "Settings",
        "files": "Files",
        "tasks_count": "tasks",
        "drop_prompt": "Drop video or audio files here, or click to choose files",
        "add_files": "Add Files",
        "add_folder": "Add Folder",
        "clear_list": "Clear List",
        "file_name": "File Name",
        "type": "Type",
        "duration": "Duration",
        "size": "Size",
        "status": "Status",
        "video": "Video",
        "audio": "Audio",
        "unknown": "Unknown",
        "analyzing": "Analyzing",
        "queued": "Queued",
        "converting": "Converting",
        "completed": "Completed",
        "failed": "Failed",
        "cancelled": "Cancelled",
        "output_settings": "Output Settings",
        "conversion_type": "Conversion Type",
        "video_to_audio": "Video to Audio",
        "video_to_video": "Video to Video",
        "audio_to_audio": "Audio to Audio",
        "preset": "Preset",
        "output_location": "Output Location",
        "source_directory": "Source Folder",
        "unified_directory": "Single Folder",
        "no_directory": "No folder selected",
        "choose": "Choose",
        "conflict_strategy": "Name Conflicts",
        "auto_rename": "Auto Rename",
        "skip": "Skip",
        "overwrite": "Overwrite",
        "open_when_done": "Open output folder when done",
        "advanced_options": "Advanced Options",
        "audio_bitrate": "Audio bitrate, e.g. 192k",
        "sample_rate": "Sample Rate",
        "channels": "Channels",
        "video_encoder": "Video encoder, e.g. libx264",
        "video_bitrate": "Video bitrate, e.g. 4M",
        "cancel": "Cancel",
        "start": "Start",
        "working": "Converting",
        "open_output": "Open Output",
        "waiting": "Waiting",
        "log": "Log",
        "copy": "Copy",
        "failed_tasks": "Failed Tasks",
        "language": "Language",
        "follow_system": "Follow System"
    ]
}
