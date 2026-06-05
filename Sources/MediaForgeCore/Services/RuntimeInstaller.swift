import Foundation

public struct RuntimeInstallProgress: Equatable, Sendable {
    public let fraction: Double
    public let message: String

    public init(fraction: Double, message: String) {
        self.fraction = fraction
        self.message = message
    }
}

public enum RuntimeInstaller {
    public static let progressPrefix = "__MEDIAFORGE_RUNTIME_PROGRESS__"
    public static let linkedRuntimeEstimateMegabytes = 350
    public static let recommendedFreeSpaceMegabytes = 1_024

    public static func parseProgressLine(_ line: String) -> RuntimeInstallProgress? {
        let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == progressPrefix, let fraction = Double(parts[1]) else {
            return nil
        }
        return RuntimeInstallProgress(fraction: min(max(fraction, 0), 1), message: String(parts[2]))
    }

    public static func homebrewInstallScript() -> String {
        """
        #!/bin/zsh
        set -uo pipefail

        export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
        HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

        progress() {
          echo "\(progressPrefix)|$1|$2"
        }

        finish_with_error() {
          progress "$1" "$2"
          exit 1
        }

        load_brew_shellenv() {
          if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
          elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
          fi
        }

        prepare_homebrew_prefix_if_needed() {
          if command -v brew >/dev/null 2>&1; then
            return 0
          fi

          if [ "$(uname -m)" != "arm64" ]; then
            return 0
          fi

          if [ -d /opt/homebrew ] && [ -w /opt/homebrew ]; then
            return 0
          fi

          progress "0.25" "请求系统认证以准备 Homebrew 目录"
          current_user="$(id -un)"
          /usr/bin/osascript - "$current_user" <<'OSA'
        on run argv
          set accountName to item 1 of argv
          do shell script "/bin/mkdir -p /opt/homebrew && /usr/sbin/chown -R " & quoted form of (accountName & ":admin") & " /opt/homebrew" with administrator privileges
        end run
        OSA
        }

        progress "0.10" "检查 FFmpeg 运行环境"
        load_brew_shellenv

        if command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1; then
          progress "1.00" "FFmpeg 运行环境已就绪"
          command -v ffmpeg
          command -v ffprobe
          exit 0
        fi

        if ! command -v brew >/dev/null 2>&1; then
          progress "0.20" "准备安装 Homebrew"
          prepare_homebrew_prefix_if_needed || finish_with_error "0.25" "Homebrew 目录准备失败"
          install_script="$(mktemp /tmp/mediaforge-homebrew-install.XXXXXX)"
          progress "0.35" "下载 Homebrew 官方安装脚本"
          /usr/bin/curl -fsSL "$HOMEBREW_INSTALL_URL" -o "$install_script" || finish_with_error "0.35" "Homebrew 安装脚本下载失败"
          chmod +x "$install_script"
          progress "0.55" "正在安装 Homebrew"
          NONINTERACTIVE=1 /bin/bash "$install_script" || finish_with_error "0.55" "Homebrew 安装失败"
          load_brew_shellenv
        fi

        if ! command -v brew >/dev/null 2>&1; then
          finish_with_error "0.60" "未能找到 Homebrew"
        fi

        progress "0.75" "正在安装 FFmpeg"
        brew install ffmpeg || finish_with_error "0.75" "FFmpeg 安装失败"

        progress "0.95" "验证 FFmpeg 和 FFprobe"
        load_brew_shellenv
        hash -r 2>/dev/null || true
        if command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1; then
          progress "1.00" "FFmpeg 运行环境安装完成"
          command -v ffmpeg
          command -v ffprobe
          exit 0
        else
          finish_with_error "0.95" "安装完成但未检测到 FFmpeg 或 FFprobe"
        fi
        """
    }
}
