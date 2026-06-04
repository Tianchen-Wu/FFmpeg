import Foundation

public struct UserFacingErrorMessage: Equatable, Sendable {
    public let title: String
    public let suggestion: String

    public init(title: String, suggestion: String) {
        self.title = title
        self.suggestion = suggestion
    }
}

public struct ErrorMapper: Sendable {
    public init() {}

    public func map(rawLog: String) -> UserFacingErrorMessage {
        let lower = rawLog.lowercased()

        if lower.contains("unknown encoder") {
            return UserFacingErrorMessage(
                title: "当前 FFmpeg 不支持所选编码器",
                suggestion: "请检查 FFmpeg 安装版本，或改用其它转换预设。完整错误日志已保存。"
            )
        }
        if lower.contains("permission denied") || lower.contains("operation not permitted") {
            return UserFacingErrorMessage(
                title: "输出目录没有写入权限",
                suggestion: "请选择其它输出目录，或检查当前目录的文件权限。"
            )
        }
        if lower.contains("no such file or directory") {
            return UserFacingErrorMessage(
                title: "输入文件或输出目录不存在",
                suggestion: "请确认文件没有被移动或删除，并重新添加任务。"
            )
        }
        if lower.contains("invalid data found") || lower.contains("moov atom not found") {
            return UserFacingErrorMessage(
                title: "文件可能损坏或格式无法读取",
                suggestion: "请尝试用播放器打开源文件，或改用其它输入文件。"
            )
        }
        if lower.contains("not enough space") || lower.contains("no space left") {
            return UserFacingErrorMessage(
                title: "磁盘空间不足",
                suggestion: "请清理磁盘空间，或选择容量更充足的输出位置。"
            )
        }
        if lower.contains("could not write header") && lower.contains("invalid argument") {
            return UserFacingErrorMessage(
                title: "当前封装或编码组合不兼容",
                suggestion: "请改用转码预设，不要使用仅更换封装。"
            )
        }

        return UserFacingErrorMessage(
            title: "转换失败",
            suggestion: "请查看完整 FFmpeg 日志，或尝试更换预设后重新转换。"
        )
    }
}
