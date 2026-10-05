import SwiftUI
struct TrialResultView: View {
    let trial: Trial
    let analysis: TrialAnalysis
    let export: () -> Void
    let csvURL: URL?
    let exportError: String?
    var body: some View { GroupBox("Trial Result") { VStack(alignment: .leading, spacing: 7) {
        row("Movement", trial.configuration.movement.rawValue); row("Placement", trial.configuration.placement.rawValue); row("Speed", trial.configuration.speed.rawValue)
        row("Duration / samples", String(format: "%.2f s / %d", trial.duration, trial.samples.count)); row("Peak / average acceleration", String(format: "%.3f / %.3f g", analysis.peakAcceleration, analysis.averageAcceleration)); row("Peak rotation", String(format: "%.3f rad/s", analysis.peakRotationRate)); row("Dominant axis", analysis.dominantAxis)
        row("Movement onset", analysis.movementOnset.map { String(format: "%.3f (motion timestamp)", $0) } ?? "Not detected"); row("Nearest-beat timing error", analysis.timingError.map { String(format: "%+.3f s", $0) } ?? "No cue in trial")
        Text("Acceleration magnitude").font(.caption); SensorGraphView(samples: trial.samples, value: \.accelerationMagnitude, color: .blue)
        Text("Rotation magnitude").font(.caption); SensorGraphView(samples: trial.samples, value: \.rotationMagnitude, color: .orange)
        Button("Prepare CSV Export", action: export).buttonStyle(.bordered)
        if let csvURL { ShareLink(item: csvURL) { Label("Export CSV", systemImage: "square.and.arrow.up") } }
        if let exportError { Text(exportError).font(.caption).foregroundStyle(.red) }
    }.padding(.top, 3) } }
    private func row(_ name: String, _ value: String) -> some View { HStack { Text(name); Spacer(); Text(value).fontWeight(.medium).multilineTextAlignment(.trailing) }.font(.subheadline) }
}
