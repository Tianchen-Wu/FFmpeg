import Foundation

public enum RuntimeInstaller {
    public static let linkedRuntimeEstimateMegabytes = 350
    public static let recommendedFreeSpaceMegabytes = 1_024

    public static func homebrewInstallScript() -> String {
        """
        #!/bin/zsh
        set -u

        echo "FFmpeg runtime installer"
        echo "This installs FFmpeg with Homebrew for local media conversion."
        echo

        if command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1; then
          echo "FFmpeg and FFprobe are already installed:"
          command -v ffmpeg
          command -v ffprobe
          echo
          echo "Return to FFmpeg and click Recheck."
          printf "\\nPress Return to close this window..."
          read _
          exit 0
        fi

        if ! command -v brew >/dev/null 2>&1; then
          echo "Homebrew was not found on this Mac."
          echo "Install Homebrew from https://brew.sh first, then run this installer again."
          printf "\\nPress Return to close this window..."
          read _
          exit 1
        fi

        echo "Homebrew found at:"
        command -v brew
        echo
        echo "Running: brew install ffmpeg"
        echo "Suggested free disk space: at least 1 GB."
        echo
        brew install ffmpeg

        echo
        if command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1; then
          echo "FFmpeg runtime installed successfully:"
          command -v ffmpeg
          command -v ffprobe
          echo
          echo "Return to FFmpeg and click Recheck."
        else
          echo "Install finished, but FFmpeg was not found in PATH."
          echo "Restart FFmpeg or check your Homebrew shell environment."
        fi

        printf "\\nPress Return to close this window..."
        read _
        """
    }
}
