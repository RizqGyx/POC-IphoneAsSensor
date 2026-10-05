import SwiftUI

struct MacControlView: View {
    @ObservedObject var viewModel: MacControlViewModel

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top) { header; Spacer(); connectionPanel }
            cueBoard
            HStack(alignment: .top, spacing: 20) {
                controls.frame(maxWidth: 440)
                liveResults.frame(maxWidth: .infinity)
            }
            if !viewModel.history.isEmpty { comparison }
        }
        .padding(28)
        .frame(minWidth: 850, minHeight: 650)
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text("Motion Control Center").font(.largeTitle.bold())
            Text("\(viewModel.challenge.rawValue) • Level \(viewModel.level)").foregroundStyle(.secondary)
        }
    }

    private var connectionPanel: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(viewModel.connectivity.status).font(.headline)
            Text(peerDescription).foregroundStyle(viewModel.connectivity.connectedPeers.isEmpty ? .orange : .green)
            Text(latencyDescription).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var peerDescription: String {
        viewModel.connectivity.connectedPeers.isEmpty
            ? "Waiting for iPhone sensor"
            : viewModel.connectivity.connectedPeers.joined(separator: ", ")
    }

    private var latencyDescription: String {
        let current = formattedMilliseconds(viewModel.connectivity.currentLatency)
        let average = formattedMilliseconds(viewModel.connectivity.averageLatency)
        let minimum = formattedMilliseconds(viewModel.connectivity.minLatency)
        let maximum = formattedMilliseconds(viewModel.connectivity.maxLatency)
        return "Transport: \(current) current • \(average) avg • \(minimum)/\(maximum) min/max"
    }

    private var cueBoard: some View {
        VStack(spacing: 10) {
            Text(viewModel.currentCue)
                .font(.system(size: 58, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.45)
            if viewModel.currentCueRequiresVision {
                Label("Requires Vision / body tracking for full validation", systemImage: "eye.slash")
                    .foregroundStyle(.orange)
            } else {
                Text("iPhone IMU provides onset, energy, and rotation clues—not body-part semantics.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
    }

    private var controls: some View {
        GroupBox("Cue & trial control") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Test", selection: $viewModel.challenge) {
                    ForEach(ChallengeResponse.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Stepper("Level \(viewModel.level)", value: $viewModel.level, in: 1...6)
                Picker("Placement", selection: $viewModel.placement) {
                    ForEach(PhonePlacement.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                Picker("Speed", selection: $viewModel.speed) {
                    ForEach(MovementSpeed.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Divider()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(viewModel.availableCues) { cue in
                        Button(cue.text) { viewModel.present(cue) }.buttonStyle(.bordered)
                    }
                }
                HStack {
                    Button("Start iPhone Trial") { viewModel.startRemoteTrial() }.buttonStyle(.borderedProminent)
                    Button("Stop Trial", role: .destructive) { viewModel.stopRemoteTrial() }.buttonStyle(.bordered)
                }
            }
            .padding(.top, 4)
        }
    }

    private var liveResults: some View {
        GroupBox("Received movement") {
            VStack(alignment: .leading, spacing: 12) {
                result("Detected pattern", viewModel.detectedPattern)
                result("First iPhone motion", responseDescription)
                result("Estimated response", viewModel.estimatedResponse.map(formatSeconds) ?? "Waiting")
                result("Peak acceleration", String(format: "%.3f g", viewModel.peakAcceleration))
                result("Peak rotation", String(format: "%.3f rad/s", viewModel.peakRotation))
                if let motion = viewModel.connectivity.lastMotion {
                    Divider()
                    Text("Latest iPhone sample: \(motion.movement), \(motion.placement)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Response uses iPhone wall-clock send time as an estimate. Core Motion timestamps are retained but are not clock-synchronised with this Mac.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .padding(.top, 4)
        }
    }

    private var responseDescription: String {
        viewModel.estimatedResponse.map { String(format: "%.3f s after cue", $0) } ?? "Waiting"
    }

    private var comparison: some View {
        GroupBox("Placement comparison — saved Mac trials") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(viewModel.history.suffix(10)) { summary in
                    HStack {
                        Text(summary.movement).frame(width: 170, alignment: .leading)
                        Text(summary.placement).frame(width: 120, alignment: .leading)
                        Text(String(format: "peak %.2f g", summary.peakAcceleration))
                        Spacer()
                        Text(summary.response.map(formatSeconds) ?? "—")
                    }
                    .font(.caption)
                }
                Text("Repeat the same cue and placement, then compare peak and response distributions for consistency.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 3)
        }
    }

    private func result(_ name: String, _ value: String) -> some View {
        HStack { Text(name); Spacer(); Text(value).fontWeight(.semibold) }.font(.subheadline)
    }

    private func formattedMilliseconds(_ value: TimeInterval?) -> String {
        value.map { String(format: "%.0f ms", $0 * 1_000) } ?? "—"
    }

    private func formatSeconds(_ value: TimeInterval) -> String {
        String(format: "%.3f s", value)
    }
}
