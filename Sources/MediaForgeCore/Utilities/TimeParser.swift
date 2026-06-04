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
