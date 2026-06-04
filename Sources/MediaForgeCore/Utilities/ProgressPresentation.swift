import Foundation

public struct ProgressPresentation: Equatable, Sendable {
    public let isConverting: Bool
    public let currentProgress: Double?
    public let overallProgress: Double?

    public init(isConverting: Bool, currentProgress: Double?, overallProgress: Double?) {
        self.isConverting = isConverting
        self.currentProgress = currentProgress
        self.overallProgress = overallProgress
    }

    public var shouldShowProgress: Bool {
        isConverting
    }

    public var hasCurrentBar: Bool {
        isConverting && currentProgress != nil
    }

    public var hasOverallBar: Bool {
        isConverting && overallProgress != nil
    }

    public var currentPercentText: String {
        percentText(currentProgress)
    }

    public var overallPercentText: String {
        percentText(overallProgress)
    }

    private func percentText(_ value: Double?) -> String {
        guard isConverting else { return "" }
        guard let value else { return "--" }
        let clamped = min(max(value, 0), 1)
        return "\(Int((clamped * 100).rounded()))%"
    }
}
