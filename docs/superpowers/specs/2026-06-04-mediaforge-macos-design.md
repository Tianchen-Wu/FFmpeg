# MediaForge macOS 设计说明

日期：2026-06-04

## 1. 背景与目标

MediaForge macOS 是一个基于 FFmpeg 的 macOS 本地媒体格式转换工具。第一版目标是交付一个稳定可用的 SwiftUI 图形界面 App，用于处理用户本地已有的视频和音频文件。

软件优先服务于本地素材处理、课程录音处理、视频音频提取、语音识别前处理、视频转码和素材归档等场景。

第一版支持：

- 视频转音频
- 视频转视频
- 音频转音频
- 多文件导入
- 串行批处理转换
- 常用预设档位
- 折叠式高级参数
- 当前任务和整体进度显示
- 失败任务归类
- 中文自然语言错误解释
- 完整 FFmpeg 日志保存和复制
- 中文 / 英文界面切换
- Xcode 项目和本地可双击 `.app`

第一版明确不做：

- 在线视频下载
- DRM 破解
- Whisper 内置转录
- 字幕处理
- 剪辑时间线
- 音频降噪
- 视频画面增强
- 水印
- 云端上传
- 用户账号系统
- Developer ID 签名、公证和 Mac App Store 分发

## 2. 平台与技术路线

目标平台：

- macOS 13 Ventura 及以上
- 优先适配 Apple Silicon
- 兼容 Intel Mac

技术路线：

- SwiftUI 构建原生 macOS 界面
- Swift Concurrency 管理异步分析、转换和队列状态
- `Process` 调用 FFmpeg 和 FFprobe
- FFprobe 读取媒体信息
- FFmpeg 执行实际转换
- MVP 阶段关闭 App Sandbox
- MVP 阶段不内置 FFmpeg binary

FFmpeg 检测策略：

1. 优先从系统 PATH 查找 `ffmpeg` 和 `ffprobe`
2. 再检查 Homebrew Apple Silicon 路径 `/opt/homebrew/bin`
3. 再检查 Homebrew Intel 路径 `/usr/local/bin`
4. 如果仍未找到，显示安装提示和手动指定路径入口

当前开发机已确认：

- `ffmpeg` 位于 `/opt/homebrew/bin/ffmpeg`
- `ffprobe` 位于 `/opt/homebrew/bin/ffprobe`

## 3. 主流程

用户打开 App 后，把一个或多个本地媒体文件拖入工作台，或通过按钮选择文件/文件夹。App 使用 FFprobe 分析媒体类型、时长、容器、编码、分辨率、采样率、声道数和文件大小。

用户选择转换类型、预设档位、输出格式、输出位置策略和必要的高级参数，然后点击开始转换。

转换队列按顺序执行，一个文件完成后再处理下一个。某个文件失败时，该文件标记为失败并进入失败分组，队列继续处理后续文件。转换结束后，用户可以打开输出目录、复制日志、查看失败原因或重新处理失败任务。

默认输出策略：

- 默认输出到原文件同目录
- 默认不覆盖已有文件
- 默认自动重命名冲突文件
- 用户可以切换为统一输出目录

## 4. UI 结构与交互

主界面采用单窗口批处理工作台，不使用三步向导。

### 4.1 顶部工具栏

顶部工具栏包含：

- App 名称
- FFmpeg 状态
- 当前 FFmpeg 路径或版本摘要
- 语言切换按钮，使用地球图标
- 设置入口

语言切换：

- 默认跟随系统语言
- 支持中文和 English
- 顶部地球图标可快速切换语言
- 技术词保留原文，例如 FFmpeg、H.264、H.265、AV1、CRF、bitrate
- FFmpeg 原始日志保留英文原文

### 4.2 文件导入区

文件导入区支持：

- 拖拽导入文件
- 拖拽导入文件夹
- 点击按钮选择文件
- 点击按钮选择文件夹
- 清空列表

中文默认文案：

```text
拖拽视频或音频文件到这里，或点击选择文件
```

### 4.3 文件列表区

文件列表区是主界面的核心区域。默认显示必要信息，避免编码细节造成信息过载。

默认显示：

- 文件名
- 媒体类型
- 时长
- 文件大小
- 当前状态

次级信息或展开详情显示：

- 完整路径
- 容器格式
- 视频编码
- 音频编码
- 分辨率
- 采样率
- 声道数
- 输出路径

任务状态包括：

- 分析中
- 等待转换
- 转换中
- 已完成
- 失败
- 已取消

失败任务可通过筛选或分组集中查看。

### 4.4 输出设置区

输出设置区包含：

- 转换类型：自动判断、视频转音频、视频转视频、音频转音频
- 预设档位
- 输出格式
- 输出位置策略
- 文件名规则
- 冲突处理策略
- 转换完成后是否打开输出目录
- 折叠式高级参数

输出位置策略：

- 原文件同目录，默认
- 统一输出目录，用户手动选择

冲突处理策略：

- 自动重命名，默认
- 跳过
- 覆盖

### 4.5 进度区

进度区显示：

- 当前文件进度
- 整体进度
- 第几个 / 共几个
- 当前处理文件名
- 估算剩余时间
- 当前转换速度，如果 FFmpeg 输出可解析

进度计算方式：

1. FFprobe 读取总时长
2. 解析 FFmpeg stderr 中的 `time=00:00:00.00`
3. 当前进度 = 当前处理时间 / 总时长
4. 整体进度 = 已完成任务数 + 当前任务进度，再除以任务总数

如果进度解析失败，不中断转换，只显示不确定进度。

### 4.6 日志区

日志区可以作为底部区域或可展开抽屉。

日志区显示：

- 当前任务命令摘要
- 开始时间
- 结束时间
- 成功或失败状态
- 自然语言错误解释
- 输出路径
- 完整 FFmpeg 原始输出入口

日志必须支持复制。

每次转换都写入本地文本日志。日志第一版不使用数据库。

## 5. 转换预设

预设采用用途型名称，并用副说明显示关键参数。用户默认看用途，需要技术细节时可查看参数。

### 5.1 视频转音频

预设：

- MP3 通用高质量，`libmp3lame -q:a 2`
- M4A 通用，`aac -b:a 192k`
- WAV 无压缩，`pcm_s16le`
- FLAC 无损压缩，`flac`
- Whisper WAV，`16kHz / mono / pcm_s16le`
- 无损复制音轨，`-c:a copy`

无损复制音轨只在源音轨编码与目标容器兼容时建议使用。若执行失败，错误解释应提示用户改用转码预设。

### 5.2 音频转音频

预设：

- MP3 通用高质量，`libmp3lame -q:a 2`
- M4A 通用，`aac -b:a 192k`
- WAV 无压缩，`pcm_s16le`
- FLAC 无损压缩，`flac`
- Opus 小体积，`libopus -b:a 96k`
- Whisper WAV，`16kHz / mono / pcm_s16le`

### 5.3 视频转视频

视频转视频默认保持原分辨率，不做放大，不做复杂画面处理。第一版主要通过编码器和质量档位控制体积与兼容性。

预设：

- MP4 通用兼容，H.264，`libx264 -preset medium -crf 23 -codec:a aac -b:a 192k`
- MP4 高质量，H.264，`libx264 -preset slow -crf 18 -codec:a aac -b:a 256k`
- MP4 小体积，H.265，`libx265 -crf 28 -codec:a aac -b:a 128k`
- WebM 网页格式，VP9 + Opus，`libvpx-vp9 -crf 32 -b:v 0 -codec:a libopus -b:a 96k`
- AV1 小体积/高级，优先检测 `libsvtav1`，其次检测 `libaom-av1`
- 仅更换封装，`-codec copy`

默认选中 MP4 / H.264 通用兼容。H.265 和 AV1 不作为默认选项。AV1 需要标注速度慢、兼容性取决于设备、播放器和 FFmpeg 编码器。

App 应检测可用编码器。不可用的预设显示为不可选或提示原因。

## 6. 高级参数

高级参数默认收起。第一版只暴露格式转换所需的核心项，不做剪辑、字幕、降噪或转录功能。

音频高级参数：

- bitrate
- sample rate
- channel

视频高级参数：

- encoder
- CRF 或质量档
- bitrate 档

通用高级参数：

- 输出位置策略
- 冲突处理策略
- 是否转换完成后打开输出目录

不包含：

- 字幕轨选择
- 音轨混音
- 剪辑时间线
- 裁剪
- 降噪
- 转录
- 下载
- 水印

## 7. 命令生成与执行

### 7.1 命令生成

命令生成由 `CommandBuilder` 负责。

输入：

- 输入路径
- 输出路径
- 转换类型
- 输出格式
- 预设
- 高级参数
- 可用编码器信息

输出：

- FFmpeg 参数数组

禁止拼接 shell 字符串。必须使用参数数组调用 `Process`。

正确形式：

```swift
["-i", inputPath, "-vn", "-codec:a", "libmp3lame", "-q:a", "2", outputPath]
```

这样可以正确处理空格、中文、引号、括号和特殊字符路径。

### 7.2 FFprobe

`FFprobeService` 调用：

```bash
ffprobe -v error -print_format json -show_format -show_streams input
```

需要解析：

- duration
- format_name
- bit_rate
- size
- stream 信息
- 视频编码
- 音频编码
- 分辨率
- 帧率
- 采样率
- 声道数
- 音轨数量
- 字幕轨数量

如果 FFprobe 失败，使用扩展名辅助判断媒体类型，但状态中应保留分析失败信息。

### 7.3 FFmpeg 执行

`FFmpegService` 使用 `Process` 异步执行 FFmpeg。

必须支持：

- 异步运行
- 读取 stderr
- 解析进度
- 获取 exit code
- 取消当前任务
- 保存完整原始日志
- 把失败交给错误映射模块处理

FFmpeg 的进度通常输出到 stderr。stderr 不等于错误输出。

## 8. 队列策略

`ConversionQueue` 负责串行执行任务。

队列规则：

- 用户可以一次导入多个文件
- 第一版只做串行转换
- 不做并行转换
- 不做 CPU 调度策略
- 当前任务结束后再启动下一个任务
- 单个任务失败不阻塞队列
- 失败任务进入失败分组
- 用户可以取消当前任务
- 用户可以取消全部等待任务

任务记录：

- 输入路径
- 输出路径
- 转换类型
- 预设
- 状态
- 当前进度
- 开始时间
- 结束时间
- 简短错误解释
- 完整日志路径

## 9. 输出命名与冲突处理

默认输出到原文件同目录。

默认命名策略：

- 保留原文件名主体
- 按转换类型或预设添加简短后缀
- 替换为目标扩展名

示例：

```text
race_2024.mp4 -> race_2024_audio.mp3
lecture.mov -> lecture_whisper.wav
clip.mkv -> clip_h264.mp4
```

如果目标文件已存在，默认自动重命名：

```text
output.mp3
output_1.mp3
output_2.mp3
```

用户可以切换为跳过或覆盖。

## 10. 错误处理与日志

UI 不直接把 FFmpeg 原始报错作为唯一提示。错误处理分三层：

1. 自然语言解释
2. 可能原因和建议操作
3. 完整 FFmpeg 原始日志

第一版需要覆盖的错误类型：

- 输入文件不存在
- 输出目录不存在
- 没有写入权限
- FFmpeg 未安装
- FFprobe 未安装
- 格式不支持
- 编码器不可用
- 文件损坏
- 目标文件已存在
- 用户取消任务
- 磁盘空间不足
- 无法读取媒体时长
- 无损封装不兼容

示例：

原始错误：

```text
Unknown encoder 'libmp3lame'
```

用户提示：

```text
当前 FFmpeg 不支持 MP3 编码器 libmp3lame。请检查 FFmpeg 安装版本，或重新安装完整版本 FFmpeg。
```

日志保存：

- 界面显示当前任务日志摘要
- 完整日志可复制
- 每次转换保存文本日志
- 失败任务保存完整 FFmpeg stderr
- 第一版不做转换历史数据库

## 11. 项目结构

建议结构：

```text
MediaForge/
  MediaForgeApp.swift
  Models/
    MediaFile.swift
    MediaInfo.swift
    ConversionJob.swift
    ConversionPreset.swift
    ConversionStatus.swift
    OutputFormat.swift
  Services/
    FFmpegLocator.swift
    FFprobeService.swift
    FFmpegService.swift
    CommandBuilder.swift
    ConversionQueue.swift
    FileNamingService.swift
    LogService.swift
    EncoderCapabilityService.swift
  Utilities/
    TimeParser.swift
    FileSizeFormatter.swift
    ErrorMapper.swift
    LocalizationManager.swift
  Views/
    ContentView.swift
    FileDropView.swift
    FileListView.swift
    OutputSettingsView.swift
    ProgressPanel.swift
    LogPanel.swift
    FailedTasksView.swift
    SettingsView.swift
  Resources/
    Presets.json
    Localizable.xcstrings
```

核心逻辑应和 SwiftUI View 分离，方便测试和后续修改。

## 12. 测试策略

优先测试高风险逻辑：

- `CommandBuilder` 生成参数数组，不拼 shell 字符串
- 中文路径、空格路径和特殊字符路径
- FFprobe JSON 解析
- FFmpeg stderr 进度解析
- 输出文件名冲突自动重命名
- FFmpeg/FFprobe 缺失提示
- 编码器不可用错误映射
- 单文件转换
- 多文件串行转换
- 失败任务不阻塞后续队列
- 用户取消当前任务

手工验收场景：

- mp4 转 mp3
- mp4 转 wav
- mov 转 mp4
- m4a 转 mp3
- 多文件批量串行
- 中文路径
- 带空格路径
- 输出文件已存在
- 输入文件损坏
- FFmpeg 不存在
- 中途取消任务

## 13. 交付方式

第一版交付：

- 可打开和继续开发的 Xcode 项目
- 本地可双击运行的 `.app`
- 不开启 Sandbox
- 不做 Developer ID 签名
- 不做公证
- 不做 DMG 打包

后续分发阶段可补：

- Developer ID 签名
- Apple notarization
- DMG 打包
- App Sandbox 迁移
- 内置 FFmpeg binary 或更完善的 FFmpeg 路径设置

## 14. 里程碑

第一阶段：SwiftUI MVP 闭环

- 创建 macOS SwiftUI 项目
- 自动检测 FFmpeg/FFprobe
- 拖拽或选择文件
- FFprobe 分析媒体信息
- 选择预设和输出策略
- 执行单文件转换
- 显示当前任务进度

第二阶段：串行批处理与错误处理

- 多文件导入
- 串行队列
- 失败继续下一个
- 失败任务分组
- 日志保存和复制
- 自然语言错误映射

第三阶段：预设、高级参数和本地化

- 完整三类转换预设
- 编码器能力检测
- 折叠式高级参数
- 中文 / 英文切换
- 本地化字符串整理

第四阶段：构建与验收

- 单元测试核心服务
- 手工测试典型转换路径
- 构建本地 `.app`
- 确认可双击运行

## 15. 验收标准

MVP 完成后必须满足：

- App 能在 macOS 上启动
- 能自动检测 Homebrew FFmpeg/FFprobe
- 能拖拽添加视频和音频文件
- 能读取媒体基本信息
- 能完成视频转音频
- 能完成视频转视频
- 能完成音频转音频
- 能批量串行转换
- 能显示当前文件转换进度
- 单个任务失败不阻塞后续任务
- 失败原因有自然语言解释
- 完整 FFmpeg 日志可复制且有本地保存
- 能处理中文路径、空格路径和特殊字符路径
- 默认不覆盖同名文件
- 能自动重命名输出冲突
- 用户可以选择统一输出目录
- 转换完成后可以打开输出文件夹
- 项目可用 Xcode 打开
- 能构建出本地可双击 `.app`
