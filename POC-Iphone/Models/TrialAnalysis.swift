import Foundation

nonisolated struct TrialAnalysis: Sendable {
    let peakAcceleration: Double
    let averageAcceleration: Double
    let peakRotationRate: Double
    let movementOnset: TimeInterval?
    let timingError: TimeInterval?
    let dominantAxis: String
}
