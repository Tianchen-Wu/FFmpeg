# MediaForge macOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a stable SwiftUI macOS GUI app for local FFmpeg media conversion with drag-and-drop import, serial batch conversion, presets, progress, localized UI, readable errors, and saved logs.

**Architecture:** Use a Swift Package with a Foundation-only `MediaForgeCore` library and a SwiftUI `MediaForge` executable target. Core services own FFmpeg discovery, FFprobe parsing, command generation, file naming, error mapping, logging, and serial queue behavior; SwiftUI views bind to an app view model and do not construct FFmpeg commands directly.

**Tech Stack:** Swift 6, SwiftUI, Swift Concurrency, Foundation `Process`, Swift Testing/XCTest via Swift Package tests, Homebrew FFmpeg/FFprobe.

---

## 0. Current Build Environment Constraint

The current machine has Command Line Tools selected, not full Xcode:

```bash
xcode-select -p
# /Library/Developer/CommandLineTools
```

`xcodebuild` currently reports that full Xcode is required, and `swift -e 'import SwiftUI'` currently fails with a Swift SDK/compiler mismatch. The implementation can still create the project and source files. Final local compile and `.app` verification may require installing full Xcode or selecting a matching Xcode toolchain:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Do not block source creation on this. Record any build failure output in the final verification notes.

---

## 1. File Structure

Create these files:

```text
Package.swift
scripts/build_app.sh
Resources/Info.plist
Sources/MediaForge/MediaForgeApp.swift
Sources/MediaForge/AppState.swift
Sources/MediaForge/Views/ContentView.swift
Sources/MediaForge/Views/FileDropView.swift
Sources/MediaForge/Views/FileListView.swift
Sources/MediaForge/Views/OutputSettingsView.swift
Sources/MediaForge/Views/ProgressPanel.swift
Sources/MediaForge/Views/LogPanel.swift
Sources/MediaForge/Views/FailedTasksView.swift
Sources/MediaForge/Views/SettingsView.swift
Sources/MediaForge/Resources/Localizable.xcstrings
Sources/MediaForgeCore/Models/MediaModels.swift
Sources/MediaForgeCore/Models/ConversionPreset.swift
Sources/MediaForgeCore/Services/FFmpegLocator.swift
Sources/MediaForgeCore/Services/EncoderCapabilityService.swift
Sources/MediaForgeCore/Services/FFprobeService.swift
Sources/MediaForgeCore/Services/CommandBuilder.swift
Sources/MediaForgeCore/Services/FFmpegService.swift
Sources/MediaForgeCore/Services/ConversionQueue.swift
Sources/MediaForgeCore/Services/FileNamingService.swift
Sources/MediaForgeCore/Services/LogService.swift
Sources/MediaForgeCore/Utilities/TimeParser.swift
Sources/MediaForgeCore/Utilities/FileSizeFormatter.swift
Sources/MediaForgeCore/Utilities/ErrorMapper.swift
Tests/MediaForgeCoreTests/FFmpegLocatorTests.swift
Tests/MediaForgeCoreTests/TimeParserTests.swift
Tests/MediaForgeCoreTests/FFprobeServiceTests.swift
Tests/MediaForgeCoreTests/CommandBuilderTests.swift
Tests/MediaForgeCoreTests/FileNamingServiceTests.swift
Tests/MediaForgeCoreTests/ErrorMapperTests.swift
Tests/MediaForgeCoreTests/ConversionQueueTests.swift
```

Responsibilities:

- `MediaForgeCore` contains code that can be tested without SwiftUI.
- `MediaForge` contains app entry, view model, and views.
- `scripts/build_app.sh` creates `build/MediaForge.app` from a release executable.
- `Resources/Info.plist` describes the `.app` bundle.

---

## Task 1: Scaffold Swift Package and App Bundle Script

**Files:**
- Create: `Package.swift`
- Create: `scripts/build_app.sh`
- Create: `Resources/Info.plist`
- Create: `Sources/MediaForge/MediaForgeApp.swift`
- Create: `Sources/MediaForge/Views/ContentView.swift`

- [ ] **Step 1: Create `Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MediaForge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MediaForgeCore", targets: ["MediaForgeCore"]),
        .executable(name: "MediaForge", targets: ["MediaForge"])
    ],
    targets: [
        .target(name: "MediaForgeCore"),
        .executableTarget(
            name: "MediaForge",
            dependencies: ["MediaForgeCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MediaForgeCoreTests",
            dependencies: ["MediaForgeCore"]
        )
    ]
)
```

- [ ] **Step 2: Create a minimal SwiftUI app entry**

```swift
import SwiftUI

@main
struct MediaForgeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1040, minHeight: 680)
        }
        .windowStyle(.titleBar)
    }
}
```

- [ ] **Step 3: Create a temporary `ContentView` smoke screen**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("MediaForge")
            .font(.largeTitle)
            .padding()
    }
}
```

- [ ] **Step 4: Create `Resources/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MediaForge</string>
    <key>CFBundleIdentifier</key>
    <string>local.mediaforge.mac</string>
    <key>CFBundleName</key>
    <string>MediaForge</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 5: Create `scripts/build_app.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/MediaForge.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c release --product MediaForge

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp ".build/release/MediaForge" "$MACOS_DIR/MediaForge"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/MediaForge"

echo "Built $APP_DIR"
```

- [ ] **Step 6: Make the script executable**

Run:

```bash
chmod +x scripts/build_app.sh
```

- [ ] **Step 7: Verify package description**

Run:

```bash
swift package describe
```

Expected: package graph lists `MediaForgeCore`, `MediaForge`, and `MediaForgeCoreTests`. If the Swift toolchain mismatch appears, record the exact output and continue with source tasks.

- [ ] **Step 8: Commit scaffold**

```bash
git add Package.swift Resources/Info.plist scripts/build_app.sh Sources/MediaForge
git commit -m "Create MediaForge SwiftUI package scaffold"
```

---

## Task 2: Core Models and Presets

**Files:**
- Create: `Sources/MediaForgeCore/Models/MediaModels.swift`
- Create: `Sources/MediaForgeCore/Models/ConversionPreset.swift`
- Create: `Tests/MediaForgeCoreTests/CommandBuilderTests.swift`

- [ ] **Step 1: Create model definitions**

```swift
import Foundation

public enum MediaType: String, Codable, Sendable {
    case video
    case audio
    case unknown
}

public enum ConversionType: String, Codable, CaseIterable, Sendable {
    case auto
    case videoToAudio
    case videoToVideo
    case audioToAudio
}

public enum OutputFormat: String, Codable, CaseIterable, Sendable {
    case mp3, m4a, aac, wav, flac, ogg, opus, aiff
    case mp4, mov, mkv, webm, avi, m4v
}

public enum ConflictStrategy: String, Codable, CaseIterable, Sendable {
    case autoRename
    case skip
    case overwrite
}

public enum OutputLocationStrategy: Equatable, Sendable {
    case sourceDirectory
    case unifiedDirectory(URL)
}

public enum ConversionStatus: Equatable, Sendable {
    case analyzing
    case queued
    case converting(progress: Double?)
    case completed(outputURL: URL)
    case failed(message: String)
    case cancelled
}

public struct MediaInfo: Equatable, Sendable {
    public var mediaType: MediaType
    public var duration: Double?
    public var formatName: String?
    public var bitRate: Int64?
    public var size: Int64?
    public var videoCodec: String?
    public var audioCodec: String?
    public var width: Int?
    public var height: Int?
    public var frameRate: Double?
    public var sampleRate: Int?
    public var channels: Int?
    public var audioStreamCount: Int
    public var subtitleStreamCount: Int

    public init(
        mediaType: MediaType,
        duration: Double? = nil,
        formatName: String? = nil,
        bitRate: Int64? = nil,
        size: Int64? = nil,
        videoCodec: String? = nil,
        audioCodec: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        frameRate: Double? = nil,
        sampleRate: Int? = nil,
        channels: Int? = nil,
        audioStreamCount: Int = 0,
        subtitleStreamCount: Int = 0
    ) {
        self.mediaType = mediaType
        self.duration = duration
        self.formatName = formatName
        self.bitRate = bitRate
        self.size = size
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.sampleRate = sampleRate
        self.channels = channels
        self.audioStreamCount = audioStreamCount
        self.subtitleStreamCount = subtitleStreamCount
    }
}

public struct MediaFile: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let inputURL: URL
    public var fileName: String
    public var fileSize: Int64
    public var mediaInfo: MediaInfo?
    public var status: ConversionStatus

    public init(id: UUID = UUID(), inputURL: URL, fileSize: Int64, mediaInfo: MediaInfo? = nil, status: ConversionStatus = .analyzing) {
        self.id = id
        self.inputURL = inputURL
        self.fileName = inputURL.lastPathComponent
        self.fileSize = fileSize
        self.mediaInfo = mediaInfo
        self.status = status
    }
}

public struct AdvancedOptions: Equatable, Sendable {
    public var audioBitrate: String?
    public var sampleRate: Int?
    public var channels: Int?
    public var videoEncoder: String?
    public var crf: Int?
    public var videoBitrate: String?

    public init(audioBitrate: String? = nil, sampleRate: Int? = nil, channels: Int? = nil, videoEncoder: String? = nil, crf: Int? = nil, videoBitrate: String? = nil) {
        self.audioBitrate = audioBitrate
        self.sampleRate = sampleRate
        self.channels = channels
        self.videoEncoder = videoEncoder
        self.crf = crf
        self.videoBitrate = videoBitrate
    }
}
```

- [ ] **Step 2: Create preset definitions**

```swift
import Foundation

public struct ConversionPreset: Identifiable, Equatable, Sendable {
    public let id: String
    public let nameKey: String
    public let detailKey: String
    public let conversionType: ConversionType
    public let outputFormat: OutputFormat
    public let arguments: [String]
    public let requiredEncoders: [String]
    public let isAdvanced: Bool

    public init(id: String, nameKey: String, detailKey: String, conversionType: ConversionType, outputFormat: OutputFormat, arguments: [String], requiredEncoders: [String] = [], isAdvanced: Bool = false) {
        self.id = id
        self.nameKey = nameKey
        self.detailKey = detailKey
        self.conversionType = conversionType
        self.outputFormat = outputFormat
        self.arguments = arguments
        self.requiredEncoders = requiredEncoders
        self.isAdvanced = isAdvanced
    }
}

public enum PresetCatalog {
    public static let all: [ConversionPreset] = videoToAudio + audioToAudio + videoToVideo

    public static let videoToAudio: [ConversionPreset] = [
        .init(id: "vta_mp3_high", nameKey: "preset.vta.mp3High.name", detailKey: "preset.vta.mp3High.detail", conversionType: .videoToAudio, outputFormat: .mp3, arguments: ["-vn", "-codec:a", "libmp3lame", "-q:a", "2"], requiredEncoders: ["libmp3lame"]),
        .init(id: "vta_m4a_general", nameKey: "preset.vta.m4a.name", detailKey: "preset.vta.m4a.detail", conversionType: .videoToAudio, outputFormat: .m4a, arguments: ["-vn", "-codec:a", "aac", "-b:a", "192k"]),
        .init(id: "vta_wav_pcm", nameKey: "preset.vta.wav.name", detailKey: "preset.vta.wav.detail", conversionType: .videoToAudio, outputFormat: .wav, arguments: ["-vn", "-codec:a", "pcm_s16le"]),
        .init(id: "vta_flac", nameKey: "preset.vta.flac.name", detailKey: "preset.vta.flac.detail", conversionType: .videoToAudio, outputFormat: .flac, arguments: ["-vn", "-codec:a", "flac"]),
        .init(id: "vta_whisper_wav", nameKey: "preset.vta.whisper.name", detailKey: "preset.vta.whisper.detail", conversionType: .videoToAudio, outputFormat: .wav, arguments: ["-vn", "-ac", "1", "-ar", "16000", "-codec:a", "pcm_s16le"]),
        .init(id: "vta_copy_audio", nameKey: "preset.vta.copy.name", detailKey: "preset.vta.copy.detail", conversionType: .videoToAudio, outputFormat: .m4a, arguments: ["-vn", "-c:a", "copy"], isAdvanced: true)
    ]

    public static let audioToAudio: [ConversionPreset] = [
        .init(id: "ata_mp3_high", nameKey: "preset.ata.mp3High.name", detailKey: "preset.ata.mp3High.detail", conversionType: .audioToAudio, outputFormat: .mp3, arguments: ["-codec:a", "libmp3lame", "-q:a", "2"], requiredEncoders: ["libmp3lame"]),
        .init(id: "ata_m4a_general", nameKey: "preset.ata.m4a.name", detailKey: "preset.ata.m4a.detail", conversionType: .audioToAudio, outputFormat: .m4a, arguments: ["-codec:a", "aac", "-b:a", "192k"]),
        .init(id: "ata_wav_pcm", nameKey: "preset.ata.wav.name", detailKey: "preset.ata.wav.detail", conversionType: .audioToAudio, outputFormat: .wav, arguments: ["-codec:a", "pcm_s16le"]),
        .init(id: "ata_flac", nameKey: "preset.ata.flac.name", detailKey: "preset.ata.flac.detail", conversionType: .audioToAudio, outputFormat: .flac, arguments: ["-codec:a", "flac"]),
        .init(id: "ata_opus_small", nameKey: "preset.ata.opus.name", detailKey: "preset.ata.opus.detail", conversionType: .audioToAudio, outputFormat: .opus, arguments: ["-codec:a", "libopus", "-b:a", "96k"], requiredEncoders: ["libopus"]),
        .init(id: "ata_whisper_wav", nameKey: "preset.ata.whisper.name", detailKey: "preset.ata.whisper.detail", conversionType: .audioToAudio, outputFormat: .wav, arguments: ["-ac", "1", "-ar", "16000", "-codec:a", "pcm_s16le"])
    ]

    public static let videoToVideo: [ConversionPreset] = [
        .init(id: "vtv_mp4_h264_general", nameKey: "preset.vtv.h264General.name", detailKey: "preset.vtv.h264General.detail", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec:v", "libx264", "-preset", "medium", "-crf", "23", "-codec:a", "aac", "-b:a", "192k"], requiredEncoders: ["libx264"]),
        .init(id: "vtv_mp4_h264_high", nameKey: "preset.vtv.h264High.name", detailKey: "preset.vtv.h264High.detail", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec:v", "libx264", "-preset", "slow", "-crf", "18", "-codec:a", "aac", "-b:a", "256k"], requiredEncoders: ["libx264"]),
        .init(id: "vtv_mp4_h265_small", nameKey: "preset.vtv.h265Small.name", detailKey: "preset.vtv.h265Small.detail", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec:v", "libx265", "-crf", "28", "-codec:a", "aac", "-b:a", "128k"], requiredEncoders: ["libx265"]),
        .init(id: "vtv_webm_vp9", nameKey: "preset.vtv.webm.name", detailKey: "preset.vtv.webm.detail", conversionType: .videoToVideo, outputFormat: .webm, arguments: ["-codec:v", "libvpx-vp9", "-crf", "32", "-b:v", "0", "-codec:a", "libopus", "-b:a", "96k"], requiredEncoders: ["libvpx-vp9", "libopus"]),
        .init(id: "vtv_mp4_av1", nameKey: "preset.vtv.av1.name", detailKey: "preset.vtv.av1.detail", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec:v", "libsvtav1", "-crf", "35", "-codec:a", "aac", "-b:a", "128k"], requiredEncoders: ["libsvtav1"], isAdvanced: true),
        .init(id: "vtv_copy_container", nameKey: "preset.vtv.copy.name", detailKey: "preset.vtv.copy.detail", conversionType: .videoToVideo, outputFormat: .mp4, arguments: ["-codec", "copy"], isAdvanced: true)
    ]
}
```

- [ ] **Step 3: Add a preset smoke test**

```swift
import XCTest
@testable import MediaForgeCore

final class CommandBuilderTests: XCTestCase {
    func testPresetCatalogContainsRequiredGroups() {
        XCTAssertEqual(PresetCatalog.videoToAudio.count, 6)
        XCTAssertEqual(PresetCatalog.audioToAudio.count, 6)
        XCTAssertEqual(PresetCatalog.videoToVideo.count, 6)
        XCTAssertTrue(PresetCatalog.videoToVideo.contains { $0.id == "vtv_mp4_h264_general" })
    }
}
```

- [ ] **Step 4: Run the preset smoke test**

Run:

```bash
swift test --filter CommandBuilderTests/testPresetCatalogContainsRequiredGroups
```

Expected: PASS when Swift toolchain is healthy; otherwise record the local toolchain mismatch.

- [ ] **Step 5: Commit models and presets**

```bash
git add Sources/MediaForgeCore Tests/MediaForgeCoreTests/CommandBuilderTests.swift
git commit -m "Add core models and conversion presets"
```

---

## Task 3: FFmpeg Discovery and Encoder Capability Detection

**Files:**
- Create: `Sources/MediaForgeCore/Services/FFmpegLocator.swift`
- Create: `Sources/MediaForgeCore/Services/EncoderCapabilityService.swift`
- Create: `Tests/MediaForgeCoreTests/FFmpegLocatorTests.swift`

- [ ] **Step 1: Write locator tests**

```swift
import XCTest
@testable import MediaForgeCore

final class FFmpegLocatorTests: XCTestCase {
    func testLocatorFindsExecutableInProvidedSearchPaths() throws {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        let ffmpeg = temp.appendingPathComponent("ffmpeg")
        try "#!/bin/sh\necho ffmpeg\n".write(to: ffmpeg, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ffmpeg.path)

        let result = FFmpegLocator(searchPaths: [temp.path], environmentPath: "").locate(named: "ffmpeg")

        XCTAssertEqual(result?.path, ffmpeg.path)
    }

    func testLocatorChecksHomebrewPathsAfterEnvironmentPath() {
        let locator = FFmpegLocator(searchPaths: ["/opt/homebrew/bin", "/usr/local/bin"], environmentPath: "")

        XCTAssertEqual(locator.defaultSearchPaths.prefix(2), ["/opt/homebrew/bin", "/usr/local/bin"])
    }
}
```

- [ ] **Step 2: Implement `FFmpegLocator`**

```swift
import Foundation

public struct LocatedExecutable: Equatable, Sendable {
    public let name: String
    public let url: URL

    public var path: String { url.path }
}

public struct FFmpegLocator: Sendable {
    public let defaultSearchPaths: [String]
    private let environmentPath: String

    public init(searchPaths: [String] = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"], environmentPath: String = ProcessInfo.processInfo.environment["PATH"] ?? "") {
        self.defaultSearchPaths = searchPaths
        self.environmentPath = environmentPath
    }

    public func locate(named executableName: String) -> LocatedExecutable? {
        for directory in environmentPath.split(separator: ":").map(String.init) + defaultSearchPaths {
            let candidate = URL(fileURLWithPath: directory).appendingPathComponent(executableName)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return LocatedExecutable(name: executableName, url: candidate)
            }
        }
        return nil
    }

    public func locateFFmpegPair() -> (ffmpeg: LocatedExecutable?, ffprobe: LocatedExecutable?) {
        (locate(named: "ffmpeg"), locate(named: "ffprobe"))
    }
}
```

- [ ] **Step 3: Implement `EncoderCapabilityService`**

```swift
import Foundation

public protocol ProcessRunning: Sendable {
    func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult
}

public struct ProcessResult: Equatable, Sendable {
    public let exitCode: Int32
    public let standardOutput: String
    public let standardError: String
}

public struct DefaultProcessRunner: ProcessRunning {
    public init() {}

    public func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ProcessResult(exitCode: process.terminationStatus, standardOutput: output, standardError: error)
    }
}

public struct EncoderCapabilityService: Sendable {
    private let runner: ProcessRunning

    public init(runner: ProcessRunning = DefaultProcessRunner()) {
        self.runner = runner
    }

    public func availableEncoders(ffmpegURL: URL) async -> Set<String> {
        do {
            let result = try await runner.run(executableURL: ffmpegURL, arguments: ["-hide_banner", "-encoders"])
            let text = result.standardOutput + "\n" + result.standardError
            return Set(text.split(whereSeparator: \.isWhitespace).map(String.init).filter { $0.hasPrefix("lib") || $0 == "aac" || $0 == "flac" || $0 == "pcm_s16le" })
        } catch {
            return []
        }
    }
}
```

- [ ] **Step 4: Run locator tests**

```bash
swift test --filter FFmpegLocatorTests
```

Expected: PASS when Swift toolchain is healthy.

- [ ] **Step 5: Commit discovery services**

```bash
git add Sources/MediaForgeCore/Services/FFmpegLocator.swift Sources/MediaForgeCore/Services/EncoderCapabilityService.swift Tests/MediaForgeCoreTests/FFmpegLocatorTests.swift
git commit -m "Add FFmpeg discovery services"
```

---

## Task 4: Time Parsing and FFprobe JSON Parsing

**Files:**
- Create: `Sources/MediaForgeCore/Utilities/TimeParser.swift`
- Create: `Sources/MediaForgeCore/Services/FFprobeService.swift`
- Create: `Tests/MediaForgeCoreTests/TimeParserTests.swift`
- Create: `Tests/MediaForgeCoreTests/FFprobeServiceTests.swift`

- [ ] **Step 1: Write time parser tests**

```swift
import XCTest
@testable import MediaForgeCore

final class TimeParserTests: XCTestCase {
    func testParsesFFmpegTimestamp() {
        XCTAssertEqual(TimeParser.seconds(from: "00:01:02.50"), 62.5, accuracy: 0.001)
    }

    func testExtractsTimeFromStderrLine() {
        let line = "frame=100 fps=25 time=00:00:04.20 bitrate=1234.5kbits/s"
        XCTAssertEqual(TimeParser.progressTime(fromFFmpegLine: line), 4.2, accuracy: 0.001)
    }

    func testReturnsNilForInvalidTime() {
        XCTAssertNil(TimeParser.seconds(from: "not-a-time"))
    }
}
```

- [ ] **Step 2: Implement `TimeParser`**

```swift
import Foundation

public enum TimeParser {
    public static func seconds(from timestamp: String) -> Double? {
        let parts = timestamp.split(separator: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2]) else {
            return nil
        }
        return hours * 3600 + minutes * 60 + seconds
    }

    public static func progressTime(fromFFmpegLine line: String) -> Double? {
        guard let range = line.range(of: #"time=\d{2}:\d{2}:\d{2}(?:\.\d+)?"#, options: .regularExpression) else {
            return nil
        }
        let token = String(line[range]).replacingOccurrences(of: "time=", with: "")
        return seconds(from: token)
    }
}
```

- [ ] **Step 3: Write FFprobe parsing tests**

```swift
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
```

- [ ] **Step 4: Implement `FFprobeService` parsing**

```swift
import Foundation

public struct FFprobeService: Sendable {
    private let ffprobeURL: URL
    private let runner: ProcessRunning

    public init(ffprobeURL: URL, runner: ProcessRunning = DefaultProcessRunner()) {
        self.ffprobeURL = ffprobeURL
        self.runner = runner
    }

    public func inspect(url: URL) async throws -> MediaInfo {
        let result = try await runner.run(executableURL: ffprobeURL, arguments: ["-v", "error", "-print_format", "json", "-show_format", "-show_streams", url.path])
        guard result.exitCode == 0 else {
            throw FFprobeError.failed(result.standardError)
        }
        return try Self.parseMediaInfo(from: Data(result.standardOutput.utf8))
    }

    public static func parseMediaInfo(from data: Data) throws -> MediaInfo {
        let response = try JSONDecoder().decode(FFprobeResponse.self, from: data)
        let video = response.streams.first { $0.codecType == "video" }
        let audio = response.streams.first { $0.codecType == "audio" }
        let audioCount = response.streams.filter { $0.codecType == "audio" }.count
        let subtitleCount = response.streams.filter { $0.codecType == "subtitle" }.count

        let mediaType: MediaType
        if video != nil {
            mediaType = .video
        } else if audio != nil {
            mediaType = .audio
        } else {
            mediaType = .unknown
        }

        return MediaInfo(
            mediaType: mediaType,
            duration: response.format.duration.flatMap(Double.init),
            formatName: response.format.formatName,
            bitRate: response.format.bitRate.flatMap(Int64.init),
            size: response.format.size.flatMap(Int64.init),
            videoCodec: video?.codecName,
            audioCodec: audio?.codecName,
            width: video?.width,
            height: video?.height,
            frameRate: video?.frameRateValue,
            sampleRate: audio?.sampleRate.flatMap(Int.init),
            channels: audio?.channels,
            audioStreamCount: audioCount,
            subtitleStreamCount: subtitleCount
        )
    }
}

public enum FFprobeError: Error, Equatable {
    case failed(String)
}

private struct FFprobeResponse: Decodable {
    let streams: [FFprobeStream]
    let format: FFprobeFormat
}

private struct FFprobeFormat: Decodable {
    let duration: String?
    let formatName: String?
    let bitRate: String?
    let size: String?

    enum CodingKeys: String, CodingKey {
        case duration
        case formatName = "format_name"
        case bitRate = "bit_rate"
        case size
    }
}

private struct FFprobeStream: Decodable {
    let codecType: String?
    let codecName: String?
    let width: Int?
    let height: Int?
    let rFrameRate: String?
    let sampleRate: String?
    let channels: Int?

    var frameRateValue: Double? {
        guard let rFrameRate, rFrameRate != "0/0" else { return nil }
        let parts = rFrameRate.split(separator: "/")
        if parts.count == 2, let numerator = Double(parts[0]), let denominator = Double(parts[1]), denominator != 0 {
            return numerator / denominator
        }
        return Double(rFrameRate)
    }

    enum CodingKeys: String, CodingKey {
        case codecType = "codec_type"
        case codecName = "codec_name"
        case width
        case height
        case rFrameRate = "r_frame_rate"
        case sampleRate = "sample_rate"
        case channels
    }
}
```

- [ ] **Step 5: Run parser tests**

```bash
swift test --filter TimeParserTests
swift test --filter FFprobeServiceTests
```

Expected: both test classes pass when Swift toolchain is healthy.

- [ ] **Step 6: Commit parsers**

```bash
git add Sources/MediaForgeCore/Utilities/TimeParser.swift Sources/MediaForgeCore/Services/FFprobeService.swift Tests/MediaForgeCoreTests/TimeParserTests.swift Tests/MediaForgeCoreTests/FFprobeServiceTests.swift
git commit -m "Add media info and progress parsers"
```

---

## Task 5: Command Builder

**Files:**
- Create: `Sources/MediaForgeCore/Services/CommandBuilder.swift`
- Modify: `Tests/MediaForgeCoreTests/CommandBuilderTests.swift`

- [ ] **Step 1: Extend command builder tests**

```swift
func testBuildsVideoToAudioMP3ArgumentsWithoutShellString() throws {
    let input = URL(fileURLWithPath: "/tmp/中文 path/input video.mp4")
    let output = URL(fileURLWithPath: "/tmp/中文 path/input_audio.mp3")
    let preset = try XCTUnwrap(PresetCatalog.videoToAudio.first { $0.id == "vta_mp3_high" })

    let args = CommandBuilder().build(inputURL: input, outputURL: output, preset: preset, advancedOptions: AdvancedOptions())

    XCTAssertEqual(args, ["-y", "-i", input.path, "-vn", "-codec:a", "libmp3lame", "-q:a", "2", output.path])
    XCTAssertFalse(args.joined(separator: " ").contains("ffmpeg -i"))
}

func testAppliesAdvancedAudioOptionsAfterPresetArguments() throws {
    let input = URL(fileURLWithPath: "/tmp/in.m4a")
    let output = URL(fileURLWithPath: "/tmp/out.wav")
    let preset = try XCTUnwrap(PresetCatalog.audioToAudio.first { $0.id == "ata_wav_pcm" })

    let args = CommandBuilder().build(inputURL: input, outputURL: output, preset: preset, advancedOptions: AdvancedOptions(sampleRate: 16000, channels: 1))

    XCTAssertTrue(args.contains("-ar"))
    XCTAssertTrue(args.contains("16000"))
    XCTAssertTrue(args.contains("-ac"))
    XCTAssertTrue(args.contains("1"))
}
```

- [ ] **Step 2: Implement `CommandBuilder`**

```swift
import Foundation

public struct CommandBuilder: Sendable {
    public init() {}

    public func build(inputURL: URL, outputURL: URL, preset: ConversionPreset, advancedOptions: AdvancedOptions, overwrite: Bool = true) -> [String] {
        var arguments: [String] = []
        arguments.append(overwrite ? "-y" : "-n")
        arguments.append(contentsOf: ["-i", inputURL.path])
        arguments.append(contentsOf: preset.arguments)
        arguments.append(contentsOf: advancedArguments(for: preset.conversionType, options: advancedOptions))
        arguments.append(outputURL.path)
        return arguments
    }

    private func advancedArguments(for conversionType: ConversionType, options: AdvancedOptions) -> [String] {
        var arguments: [String] = []

        if let audioBitrate = options.audioBitrate {
            arguments.append(contentsOf: ["-b:a", audioBitrate])
        }
        if let sampleRate = options.sampleRate {
            arguments.append(contentsOf: ["-ar", String(sampleRate)])
        }
        if let channels = options.channels {
            arguments.append(contentsOf: ["-ac", String(channels)])
        }
        if conversionType == .videoToVideo {
            if let encoder = options.videoEncoder {
                arguments.append(contentsOf: ["-codec:v", encoder])
            }
            if let crf = options.crf {
                arguments.append(contentsOf: ["-crf", String(crf)])
            }
            if let videoBitrate = options.videoBitrate {
                arguments.append(contentsOf: ["-b:v", videoBitrate])
            }
        }

        return arguments
    }
}
```

- [ ] **Step 3: Run command tests**

```bash
swift test --filter CommandBuilderTests
```

Expected: all command builder tests pass when Swift toolchain is healthy.

- [ ] **Step 4: Commit command builder**

```bash
git add Sources/MediaForgeCore/Services/CommandBuilder.swift Tests/MediaForgeCoreTests/CommandBuilderTests.swift
git commit -m "Add FFmpeg command builder"
```

---

## Task 6: File Naming and Size Formatting

**Files:**
- Create: `Sources/MediaForgeCore/Services/FileNamingService.swift`
- Create: `Sources/MediaForgeCore/Utilities/FileSizeFormatter.swift`
- Create: `Tests/MediaForgeCoreTests/FileNamingServiceTests.swift`

- [ ] **Step 1: Write file naming tests**

```swift
import XCTest
@testable import MediaForgeCore

final class FileNamingServiceTests: XCTestCase {
    func testCreatesAudioNameInSourceDirectory() throws {
        let input = URL(fileURLWithPath: "/tmp/race 2024.mp4")
        let preset = try XCTUnwrap(PresetCatalog.videoToAudio.first { $0.id == "vta_mp3_high" })

        let output = try FileNamingService().outputURL(for: input, preset: preset, location: .sourceDirectory, conflictStrategy: .autoRename)

        XCTAssertEqual(output.lastPathComponent, "race 2024_audio.mp3")
    }

    func testAutoRenamesExistingFile() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let input = directory.appendingPathComponent("lecture.mov")
        FileManager.default.createFile(atPath: input.path, contents: Data())
        FileManager.default.createFile(atPath: directory.appendingPathComponent("lecture_h264.mp4").path, contents: Data())
        let preset = try XCTUnwrap(PresetCatalog.videoToVideo.first { $0.id == "vtv_mp4_h264_general" })

        let output = try FileNamingService().outputURL(for: input, preset: preset, location: .sourceDirectory, conflictStrategy: .autoRename)

        XCTAssertEqual(output.lastPathComponent, "lecture_h264_1.mp4")
    }
}
```

- [ ] **Step 2: Implement file naming**

```swift
import Foundation

public enum FileNamingError: Error, Equatable {
    case outputExists(URL)
    case skipped(URL)
}

public struct FileNamingService: Sendable {
    public init() {}

    public func outputURL(for inputURL: URL, preset: ConversionPreset, location: OutputLocationStrategy, conflictStrategy: ConflictStrategy) throws -> URL {
        let directory: URL
        switch location {
        case .sourceDirectory:
            directory = inputURL.deletingLastPathComponent()
        case .unifiedDirectory(let url):
            directory = url
        }

        let baseName = inputURL.deletingPathExtension().lastPathComponent
        let suffix = suffixForPreset(id: preset.id)
        let candidate = directory.appendingPathComponent(baseName + suffix).appendingPathExtension(preset.outputFormat.rawValue)

        switch conflictStrategy {
        case .overwrite:
            return candidate
        case .skip:
            if FileManager.default.fileExists(atPath: candidate.path) {
                throw FileNamingError.skipped(candidate)
            }
            return candidate
        case .autoRename:
            return autoRenamed(candidate)
        }
    }

    private func suffixForPreset(id: String) -> String {
        if id.contains("whisper") { return "_whisper" }
        if id.contains("h264") { return "_h264" }
        if id.contains("h265") { return "_h265" }
        if id.contains("av1") { return "_av1" }
        if id.contains("webm") { return "_webm" }
        if id.contains("copy") { return "_copy" }
        if id.hasPrefix("vta") { return "_audio" }
        return "_converted"
    }

    private func autoRenamed(_ url: URL) -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else { return url }
        let directory = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var index = 1
        while true {
            let next = directory.appendingPathComponent("\(base)_\(index)").appendingPathExtension(ext)
            if !FileManager.default.fileExists(atPath: next.path) {
                return next
            }
            index += 1
        }
    }
}
```

- [ ] **Step 3: Implement file size formatting**

```swift
import Foundation

public enum FileSizeFormatter {
    public static func string(from bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
```

- [ ] **Step 4: Run naming tests**

```bash
swift test --filter FileNamingServiceTests
```

Expected: PASS when Swift toolchain is healthy.

- [ ] **Step 5: Commit naming utilities**

```bash
git add Sources/MediaForgeCore/Services/FileNamingService.swift Sources/MediaForgeCore/Utilities/FileSizeFormatter.swift Tests/MediaForgeCoreTests/FileNamingServiceTests.swift
git commit -m "Add output naming service"
```

---

## Task 7: Error Mapping and Log Service

**Files:**
- Create: `Sources/MediaForgeCore/Utilities/ErrorMapper.swift`
- Create: `Sources/MediaForgeCore/Services/LogService.swift`
- Create: `Tests/MediaForgeCoreTests/ErrorMapperTests.swift`

- [ ] **Step 1: Write error mapper tests**

```swift
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
```

- [ ] **Step 2: Implement error mapper**

```swift
import Foundation

public struct UserFacingErrorMessage: Equatable, Sendable {
    public let title: String
    public let suggestion: String
}

public struct ErrorMapper: Sendable {
    public init() {}

    public func map(rawLog: String) -> UserFacingErrorMessage {
        let lower = rawLog.lowercased()

        if lower.contains("unknown encoder") {
            return UserFacingErrorMessage(title: "当前 FFmpeg 不支持所选编码器", suggestion: "请检查 FFmpeg 安装版本，或改用其它转换预设。完整错误日志已保存。")
        }
        if lower.contains("permission denied") {
            return UserFacingErrorMessage(title: "输出目录没有写入权限", suggestion: "请选择其它输出目录，或检查当前目录的文件权限。")
        }
        if lower.contains("no such file or directory") {
            return UserFacingErrorMessage(title: "输入文件或输出目录不存在", suggestion: "请确认文件没有被移动或删除，并重新添加任务。")
        }
        if lower.contains("invalid data found") || lower.contains("moov atom not found") {
            return UserFacingErrorMessage(title: "文件可能损坏或格式无法读取", suggestion: "请尝试用播放器打开源文件，或改用其它输入文件。")
        }
        if lower.contains("not enough space") || lower.contains("no space left") {
            return UserFacingErrorMessage(title: "磁盘空间不足", suggestion: "请清理磁盘空间，或选择容量更充足的输出位置。")
        }
        if lower.contains("could not write header") && lower.contains("invalid argument") {
            return UserFacingErrorMessage(title: "当前封装或编码组合不兼容", suggestion: "请改用转码预设，不要使用仅更换封装。")
        }

        return UserFacingErrorMessage(title: "转换失败", suggestion: "请查看完整 FFmpeg 日志，或尝试更换预设后重新转换。")
    }
}
```

- [ ] **Step 3: Implement log service**

```swift
import Foundation

public struct ConversionLog: Equatable, Sendable {
    public let taskID: UUID
    public let inputPath: String
    public let outputPath: String
    public let commandArguments: [String]
    public let startedAt: Date
    public let endedAt: Date
    public let exitCode: Int32
    public let rawLog: String
}

public struct LogService: Sendable {
    private let directory: URL

    public init(directory: URL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Logs/MediaForge", isDirectory: true)) {
        self.directory = directory
    }

    public func save(_ log: ConversionLog) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = ISO8601DateFormatter().string(from: log.startedAt).replacingOccurrences(of: ":", with: "-") + "_\(log.taskID.uuidString).log"
        let url = directory.appendingPathComponent(filename)
        let text = """
        MediaForge Conversion Log
        Started: \(log.startedAt)
        Ended: \(log.endedAt)
        Exit Code: \(log.exitCode)
        Input: \(log.inputPath)
        Output: \(log.outputPath)
        Arguments: \(log.commandArguments.joined(separator: " "))

        \(log.rawLog)
        """
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
```

- [ ] **Step 4: Run error mapper tests**

```bash
swift test --filter ErrorMapperTests
```

Expected: PASS when Swift toolchain is healthy.

- [ ] **Step 5: Commit errors and logs**

```bash
git add Sources/MediaForgeCore/Utilities/ErrorMapper.swift Sources/MediaForgeCore/Services/LogService.swift Tests/MediaForgeCoreTests/ErrorMapperTests.swift
git commit -m "Add readable errors and log service"
```

---

## Task 8: FFmpeg Service and Serial Queue

**Files:**
- Create: `Sources/MediaForgeCore/Services/FFmpegService.swift`
- Create: `Sources/MediaForgeCore/Services/ConversionQueue.swift`
- Create: `Tests/MediaForgeCoreTests/ConversionQueueTests.swift`

- [ ] **Step 1: Write queue tests with a fake converter**

```swift
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
    enum FakeResult { case success, failure(String) }
    private var results: [FakeResult]

    init(results: [FakeResult]) {
        self.results = results
    }

    func run(job: ConversionJob, progress: @escaping @Sendable (Double?) -> Void) async -> ConversionResult {
        let result = results.removeFirst()
        switch result {
        case .success:
            progress(1.0)
            return .success(job.outputURL)
        case .failure(let message):
            return .failure(message)
        }
    }
}
```

- [ ] **Step 2: Add queue models and protocols**

```swift
import Foundation

public struct ConversionJob: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let inputURL: URL
    public let outputURL: URL
    public let preset: ConversionPreset
    public let advancedOptions: AdvancedOptions

    public init(id: UUID = UUID(), inputURL: URL, outputURL: URL, preset: ConversionPreset, advancedOptions: AdvancedOptions = AdvancedOptions()) {
        self.id = id
        self.inputURL = inputURL
        self.outputURL = outputURL
        self.preset = preset
        self.advancedOptions = advancedOptions
    }
}

public enum ConversionResult: Equatable, Sendable {
    case success(URL)
    case failure(String)
    case cancelled

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    public var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

public protocol ConversionRunning: Sendable {
    func run(job: ConversionJob, progress: @escaping @Sendable (Double?) -> Void) async -> ConversionResult
}
```

- [ ] **Step 3: Implement serial `ConversionQueue`**

```swift
import Foundation

public actor ConversionQueue {
    private let runner: ConversionRunning
    private var isCancelled = false

    public init(runner: ConversionRunning) {
        self.runner = runner
    }

    public func cancelAll() {
        isCancelled = true
    }

    public func run(jobs: [ConversionJob], progress: @escaping @Sendable (UUID, Double?) -> Void = { _, _ in }) async -> [ConversionResult] {
        var results: [ConversionResult] = []

        for job in jobs {
            if isCancelled {
                results.append(.cancelled)
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
```

- [ ] **Step 4: Implement `FFmpegService`**

```swift
import Foundation

public actor FFmpegService: ConversionRunning {
    private let ffmpegURL: URL
    private let commandBuilder: CommandBuilder
    private let errorMapper: ErrorMapper
    private var currentProcess: Process?

    public init(ffmpegURL: URL, commandBuilder: CommandBuilder = CommandBuilder(), errorMapper: ErrorMapper = ErrorMapper()) {
        self.ffmpegURL = ffmpegURL
        self.commandBuilder = commandBuilder
        self.errorMapper = errorMapper
    }

    public func cancelCurrent() {
        currentProcess?.terminate()
    }

    public func run(job: ConversionJob, progress: @escaping @Sendable (Double?) -> Void) async -> ConversionResult {
        let arguments = commandBuilder.build(inputURL: job.inputURL, outputURL: job.outputURL, preset: job.preset, advancedOptions: job.advancedOptions)
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = arguments

        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = Pipe()
        currentProcess = process

        var rawLog = ""
        stderr.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            rawLog += chunk
            if let seconds = TimeParser.progressTime(fromFFmpegLine: chunk) {
                progress(seconds)
            }
        }

        do {
            try process.run()
            process.waitUntilExit()
            stderr.fileHandleForReading.readabilityHandler = nil
            currentProcess = nil

            if process.terminationStatus == 0 {
                progress(1.0)
                return .success(job.outputURL)
            }

            let mapped = errorMapper.map(rawLog: rawLog)
            return .failure(mapped.title + "。" + mapped.suggestion)
        } catch {
            stderr.fileHandleForReading.readabilityHandler = nil
            currentProcess = nil
            return .failure(error.localizedDescription)
        }
    }
}
```

- [ ] **Step 5: Run queue tests**

```bash
swift test --filter ConversionQueueTests
```

Expected: PASS when Swift toolchain is healthy.

- [ ] **Step 6: Commit conversion execution**

```bash
git add Sources/MediaForgeCore/Services/FFmpegService.swift Sources/MediaForgeCore/Services/ConversionQueue.swift Tests/MediaForgeCoreTests/ConversionQueueTests.swift
git commit -m "Add serial conversion queue"
```

---

## Task 9: App State and Core SwiftUI Layout

**Files:**
- Create: `Sources/MediaForge/AppState.swift`
- Replace: `Sources/MediaForge/Views/ContentView.swift`
- Create: `Sources/MediaForge/Views/FileDropView.swift`
- Create: `Sources/MediaForge/Views/FileListView.swift`
- Create: `Sources/MediaForge/Views/OutputSettingsView.swift`
- Create: `Sources/MediaForge/Views/ProgressPanel.swift`

- [ ] **Step 1: Create `AppState`**

```swift
import Foundation
import MediaForgeCore

@MainActor
final class AppState: ObservableObject {
    @Published var files: [MediaFile] = []
    @Published var selectedConversionType: ConversionType = .auto
    @Published var selectedPreset: ConversionPreset = PresetCatalog.videoToVideo[0]
    @Published var outputLocation: OutputLocationStrategy = .sourceDirectory
    @Published var conflictStrategy: ConflictStrategy = .autoRename
    @Published var advancedOptions = AdvancedOptions()
    @Published var currentProgress: Double?
    @Published var isConverting = false
    @Published var statusMessage = ""

    let locator = FFmpegLocator()
    var ffmpegPathSummary: String {
        locator.locate(named: "ffmpeg")?.path ?? "未检测到 FFmpeg"
    }

    func addFiles(urls: [URL]) {
        let newFiles = urls.filter { !$0.hasDirectoryPath }.map { url in
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
            return MediaFile(inputURL: url, fileSize: size, mediaInfo: nil, status: .queued)
        }
        files.append(contentsOf: newFiles)
    }

    func clearFiles() {
        files.removeAll()
        currentProgress = nil
        statusMessage = ""
    }
}
```

- [ ] **Step 2: Replace `ContentView` with workbench layout**

```swift
import SwiftUI
import MediaForgeCore

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HSplitView {
                VStack(spacing: 12) {
                    FileDropView()
                    FileListView()
                }
                .frame(minWidth: 620)

                OutputSettingsView()
                    .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
            }
            Divider()
            ProgressPanel()
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("MediaForge")
                .font(.title2.weight(.semibold))
            Text(appState.ffmpegPathSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Button {
            } label: {
                Image(systemName: "globe")
            }
            .help("切换语言")
            Button {
            } label: {
                Image(systemName: "gearshape")
            }
            .help("设置")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
```

- [ ] **Step 3: Create `FileDropView`**

```swift
import SwiftUI

struct FileDropView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 28))
            Text("拖拽视频或音频文件到这里，或点击选择文件")
                .font(.headline)
            HStack {
                Button("添加文件") { selectFiles() }
                Button("清空列表") { appState.clearFiles() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(isTargeted ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
        .padding([.top, .horizontal], 16)
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            appState.addFiles(urls: panel.urls)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in appState.addFiles(urls: [url]) }
            }
        }
        return true
    }
}
```

- [ ] **Step 4: Create `FileListView`**

```swift
import SwiftUI
import MediaForgeCore

struct FileListView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Table(appState.files) {
            TableColumn("文件名") { file in
                Text(file.fileName)
                    .lineLimit(1)
            }
            TableColumn("类型") { file in
                Text(file.mediaInfo?.mediaType.rawValue ?? "unknown")
            }
            TableColumn("大小") { file in
                Text(FileSizeFormatter.string(from: file.fileSize))
            }
            TableColumn("状态") { file in
                Text(statusText(file.status))
            }
        }
        .padding(.horizontal, 16)
    }

    private func statusText(_ status: ConversionStatus) -> String {
        switch status {
        case .analyzing: return "分析中"
        case .queued: return "等待转换"
        case .converting: return "转换中"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .cancelled: return "已取消"
        }
    }
}
```

- [ ] **Step 5: Create `OutputSettingsView` and `ProgressPanel`**

```swift
import SwiftUI
import MediaForgeCore

struct OutputSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showAdvanced = false

    var body: some View {
        Form {
            Picker("转换类型", selection: $appState.selectedConversionType) {
                ForEach(ConversionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            Picker("预设", selection: $appState.selectedPreset.id) {
                ForEach(PresetCatalog.all) { preset in
                    Text(preset.id).tag(preset.id)
                }
            }
            Picker("冲突处理", selection: $appState.conflictStrategy) {
                Text("自动重命名").tag(ConflictStrategy.autoRename)
                Text("跳过").tag(ConflictStrategy.skip)
                Text("覆盖").tag(ConflictStrategy.overwrite)
            }
            DisclosureGroup("高级参数", isExpanded: $showAdvanced) {
                TextField("音频码率", text: Binding(get: { appState.advancedOptions.audioBitrate ?? "" }, set: { appState.advancedOptions.audioBitrate = $0.isEmpty ? nil : $0 }))
                Stepper("声道: \(appState.advancedOptions.channels ?? 0)", value: Binding(get: { appState.advancedOptions.channels ?? 0 }, set: { appState.advancedOptions.channels = $0 == 0 ? nil : $0 }), in: 0...8)
            }
            Spacer()
            Button("开始转换") {
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.files.isEmpty)
        }
        .padding(16)
    }
}
```

```swift
import SwiftUI

struct ProgressPanel: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            ProgressView(value: appState.currentProgress)
                .frame(width: 220)
            Text(appState.statusMessage.isEmpty ? "等待任务" : appState.statusMessage)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
```

- [ ] **Step 6: Commit initial UI**

```bash
git add Sources/MediaForge
git commit -m "Build initial SwiftUI workbench"
```

---

## Task 10: Connect Analysis, Naming, and Conversion Actions

**Files:**
- Modify: `Sources/MediaForge/AppState.swift`
- Modify: `Sources/MediaForge/Views/OutputSettingsView.swift`
- Create: `Sources/MediaForge/Views/FailedTasksView.swift`
- Create: `Sources/MediaForge/Views/LogPanel.swift`

- [ ] **Step 1: Add conversion orchestration to `AppState`**

```swift
@MainActor
func startConversion() {
    guard let ffmpeg = locator.locate(named: "ffmpeg") else {
        statusMessage = "未检测到 FFmpeg"
        return
    }

    isConverting = true
    statusMessage = "正在转换"

    let naming = FileNamingService()
    let service = FFmpegService(ffmpegURL: ffmpeg.url)
    let queue = ConversionQueue(runner: service)
    let jobs = files.compactMap { file -> ConversionJob? in
        guard let output = try? naming.outputURL(for: file.inputURL, preset: selectedPreset, location: outputLocation, conflictStrategy: conflictStrategy) else {
            return nil
        }
        return ConversionJob(inputURL: file.inputURL, outputURL: output, preset: selectedPreset, advancedOptions: advancedOptions)
    }

    Task {
        let results = await queue.run(jobs: jobs) { [weak self] jobID, progress in
            Task { @MainActor in
                self?.currentProgress = progress
                self?.statusMessage = "正在转换 \(jobID.uuidString.prefix(8))"
            }
        }

        await MainActor.run {
            self.isConverting = false
            self.currentProgress = results.allSatisfy(\.isSuccess) ? 1.0 : nil
            self.statusMessage = "转换完成，成功 \(results.filter(\.isSuccess).count) 个，失败 \(results.filter(\.isFailure).count) 个"
        }
    }
}
```

- [ ] **Step 2: Wire the start button**

```swift
Button(appState.isConverting ? "转换中" : "开始转换") {
    appState.startConversion()
}
.buttonStyle(.borderedProminent)
.disabled(appState.files.isEmpty || appState.isConverting)
```

- [ ] **Step 3: Create failed tasks view with real filtering input**

```swift
import SwiftUI
import MediaForgeCore

struct FailedTasksView: View {
    let files: [MediaFile]

    var failedFiles: [MediaFile] {
        files.filter {
            if case .failed = $0.status { return true }
            return false
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("失败任务")
                .font(.headline)
            List(failedFiles) { file in
                Text(file.fileName)
            }
        }
        .padding()
    }
}
```

- [ ] **Step 4: Create log panel view**

```swift
import SwiftUI

struct LogPanel: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("日志")
                .font(.headline)
            ScrollView {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}
```

- [ ] **Step 5: Run a package describe check**

```bash
swift package describe
```

Expected: package manifest remains valid when Swift toolchain is healthy.

- [ ] **Step 6: Commit conversion wiring**

```bash
git add Sources/MediaForge
git commit -m "Connect UI to conversion flow"
```

---

## Task 11: Localization and Settings Shell

**Files:**
- Create: `Sources/MediaForge/Resources/Localizable.xcstrings`
- Create: `Sources/MediaForge/Views/SettingsView.swift`
- Modify: `Sources/MediaForge/AppState.swift`
- Modify: `Sources/MediaForge/Views/ContentView.swift`

- [ ] **Step 1: Add language state**

```swift
enum AppLanguage: String, CaseIterable {
    case system
    case zhHans
    case en
}

@Published var language: AppLanguage = .system

func toggleLanguage() {
    language = language == .zhHans ? .en : .zhHans
}
```

- [ ] **Step 2: Wire globe button**

```swift
Button {
    appState.toggleLanguage()
} label: {
    Image(systemName: "globe")
}
.help("切换语言")
```

- [ ] **Step 3: Create settings view**

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Picker("语言", selection: $appState.language) {
                Text("跟随系统").tag(AppLanguage.system)
                Text("中文").tag(AppLanguage.zhHans)
                Text("English").tag(AppLanguage.en)
            }
            Text("FFmpeg: \(appState.ffmpegPathSummary)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 420)
    }
}
```

- [ ] **Step 4: Add initial string catalog**

Use a minimal string catalog containing keys used by the visible UI. Keep FFmpeg, H.264, H.265, AV1, CRF, and bitrate untranslated.

```json
{
  "sourceLanguage" : "zh-Hans",
  "strings" : {
    "MediaForge" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "MediaForge" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "MediaForge" } }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] **Step 5: Commit localization shell**

```bash
git add Sources/MediaForge/Resources/Localizable.xcstrings Sources/MediaForge/Views/SettingsView.swift Sources/MediaForge/AppState.swift Sources/MediaForge/Views/ContentView.swift
git commit -m "Add localization and settings shell"
```

---

## Task 12: Build, Manual FFmpeg Smoke Tests, and Delivery Notes

**Files:**
- Modify: `docs/superpowers/plans/2026-06-04-mediaforge-macos-implementation.md` only if verification notes need permanent recording

- [ ] **Step 1: Run all tests**

```bash
swift test
```

Expected with healthy toolchain: all `MediaForgeCoreTests` pass.

- [ ] **Step 2: Build release app bundle**

```bash
scripts/build_app.sh
```

Expected with healthy toolchain:

```text
Built /Users/tianchenwu/Documents/格式转换/build/MediaForge.app
```

- [ ] **Step 3: Verify FFmpeg paths**

```bash
/opt/homebrew/bin/ffmpeg -version
/opt/homebrew/bin/ffprobe -version
```

Expected: both print version information and exit 0.

- [ ] **Step 4: Run manual UI smoke test**

Open:

```bash
open build/MediaForge.app
```

Expected:

- App launches
- FFmpeg status shows `/opt/homebrew/bin/ffmpeg`
- Drag/drop area is visible
- File list is empty and stable
- Start button is disabled until files are added

- [ ] **Step 5: Run manual conversion smoke tests**

Use local media files if available:

- mp4 to mp3
- mp4 to wav
- mov to mp4
- m4a to mp3
- two-file serial batch
- output conflict auto rename

Expected:

- Files appear in the list
- Conversion runs one at a time
- Failed files do not block subsequent files
- Outputs are created beside source files by default
- Existing outputs are auto-renamed
- Logs are saved under `~/Library/Logs/MediaForge`

- [ ] **Step 6: Record build limitation if toolchain remains mismatched**

If build fails with the current Command Line Tools SDK/compiler mismatch, record this in the final response:

```text
Source implementation is present, but local Swift build verification is blocked by the active Command Line Tools Swift/SDK mismatch. Install/select full Xcode, then rerun swift test and scripts/build_app.sh.
```

- [ ] **Step 7: Commit final verification adjustments**

```bash
git status --short
git add .
git commit -m "Prepare MediaForge MVP for local verification"
```

Only run the final commit if there are source or documentation changes not already committed.

---

## Self-Review

Spec coverage:

- SwiftUI GUI workbench: Task 1 and Task 9.
- Homebrew FFmpeg detection: Task 3.
- FFprobe media info: Task 4.
- Presets across video-to-audio, audio-to-audio, and video-to-video: Task 2.
- H.264 default, H.265 small, AV1 advanced: Task 2.
- Argument-array command building: Task 5.
- Serial batch queue with failure continuing: Task 8.
- Output beside source and auto rename: Task 6.
- Natural-language errors and raw logs: Task 7.
- Language switch: Task 11.
- Local `.app` packaging: Task 1 and Task 12.

Known build risk:

- Current machine lacks full Xcode and has a Swift SDK/compiler mismatch under Command Line Tools. Source implementation should proceed, but final compile and app bundle verification may require selecting a healthy Xcode toolchain.
