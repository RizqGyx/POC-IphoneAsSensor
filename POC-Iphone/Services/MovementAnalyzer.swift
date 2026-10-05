import Foundation

nonisolated enum MovementAnalyzer {
    static func analyze(_ trial: Trial) -> TrialAnalysis {
        let s = trial.samples, a = s.map(\.accelerationMagnitude), r = s.map(\.rotationMagnitude), n = min(s.count, 18)
        let baseline = n > 0 ? a.prefix(n).reduce(0, +) / Double(n) : 0
        let index = s.indices.first { a[$0] > max(baseline + 0.30, 0.45) || r[$0] > 0.85 }
        let onset = index.map { s[$0].timestamp }
        let cue = onset.flatMap { onset in s.compactMap(\.cueTimestamp).min(by: { abs($0 - onset) < abs($1 - onset) }) }
        let axes = [("X", s.map { abs($0.userAccX) }.max() ?? 0), ("Y", s.map { abs($0.userAccY) }.max() ?? 0), ("Z", s.map { abs($0.userAccZ) }.max() ?? 0)]
        return TrialAnalysis(peakAcceleration: a.max() ?? 0, averageAcceleration: a.isEmpty ? 0 : a.reduce(0, +) / Double(a.count), peakRotationRate: r.max() ?? 0, movementOnset: onset, timingError: onset.flatMap { x in cue.map { x - $0 } }, dominantAxis: axes.max(by: { $0.1 < $1.1 })?.0 ?? "—")
    }
}
