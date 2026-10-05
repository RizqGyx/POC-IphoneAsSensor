import SwiftUI

struct SensorHomeView: View {
    @ObservedObject var viewModel: SensorViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SensorStatusSection(viewModel: viewModel)
                    SensorControlSection(viewModel: viewModel)
                    MovementTestSection(viewModel: viewModel)
                    ConnectionSection(viewModel: viewModel)
                    if viewModel.challenge == .cr1 { RhythmTestSection(viewModel: viewModel) }
                    SensorDashboardSection(viewModel: viewModel)
                    TrialControlSection(viewModel: viewModel)
                    trialResult
                    SensorResearchNotesView()
                }
                .padding()
            }
            .navigationTitle("Movement Research POC")
        }
    }

    @ViewBuilder private var trialResult: some View {
        if let trial = viewModel.motion.completedTrial,
           let analysis = viewModel.motion.analysis {
            TrialResultView(
                trial: trial,
                analysis: analysis,
                export: { viewModel.export(trial) },
                csvURL: viewModel.csvURL,
                exportError: viewModel.exportError
            )
        }
    }
}

private struct SensorStatusSection: View {
    @ObservedObject var viewModel: SensorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CR1 Rhythm / CR3 Dungeon + Boxing").font(.headline)
            Text(viewModel.motion.statusMessage)
                .font(.subheadline)
                .foregroundStyle(viewModel.motion.isSensorRunning ? .green : .secondary)
            Text("Technical exploration only: IMU measures phone movement, not body-part semantics.")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

private struct SensorControlSection: View {
    @ObservedObject var viewModel: SensorViewModel

    var body: some View {
        Button(viewModel.motion.isSensorRunning ? "Stop Sensor" : "Start Sensor") {
            viewModel.toggleSensor()
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.motion.isSensorRunning ? .red : .blue)
    }
}

private struct MovementTestSection: View {
    @ObservedObject var viewModel: SensorViewModel

    var body: some View {
        GroupBox("Movement Test Mode") {
            VStack(spacing: 10) {
                Picker("Challenge response", selection: $viewModel.challenge) {
                    ForEach(ChallengeResponse.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                Picker("Ground-truth movement", selection: $viewModel.movement) {
                    ForEach(viewModel.availableMovements) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                Picker("iPhone placement", selection: $viewModel.placement) {
                    ForEach(PhonePlacement.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                Picker("Speed", selection: $viewModel.speed) {
                    ForEach(MovementSpeed.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .padding(.top, 3)
        }
    }
}

private struct ConnectionSection: View {
    @ObservedObject var viewModel: SensorViewModel

    var body: some View {
        GroupBox("Mac Connection") {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.connectivity.status).font(.subheadline)
                Text(peerDescription).font(.caption).foregroundStyle(.secondary)
                Picker("Send mode", selection: Binding(
                    get: { viewModel.connectivity.streamingMode },
                    set: { viewModel.connectivity.streamingMode = $0 }
                )) {
                    ForEach(StreamingMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Text("Raw sends each processed sample. Events sends only heuristic state changes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
    }

    private var peerDescription: String {
        viewModel.connectivity.connectedPeers.isEmpty
            ? "No Mac connected"
            : "Peer: \(viewModel.connectivity.connectedPeers.joined(separator: ", "))"
    }
}

private struct RhythmTestSection: View {
    @ObservedObject var viewModel: SensorViewModel

    var body: some View {
        GroupBox("CR1 Rhythm Test Mode") {
            VStack(spacing: 10) {
                Picker("BPM", selection: $viewModel.bpm) {
                    ForEach([60, 90, 120, 150], id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Cue pattern", selection: $viewModel.rhythmPattern) {
                    ForEach(RhythmPattern.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                HStack {
                    Text("Beat \(viewModel.rhythm.beat): \(viewModel.rhythm.cueText)").font(.headline)
                    Spacer()
                    Button(viewModel.rhythm.isRunning ? "Stop Cue" : "Start Cue") {
                        viewModel.toggleRhythm()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.top, 3)
        }
    }
}

private struct SensorDashboardSection: View {
    @ObservedObject var viewModel: SensorViewModel

    var body: some View {
        GroupBox("Live Processed Device Motion") {
            if let sample = viewModel.motion.latestSample {
                VStack(spacing: 10) {
                    VectorMetricView(title: "User acceleration (g)", x: sample.userAccX, y: sample.userAccY, z: sample.userAccZ)
                    VectorMetricView(title: "Rotation rate (rad/s)", x: sample.rotX, y: sample.rotY, z: sample.rotZ)
                    VectorMetricView(title: "Attitude (roll / pitch / yaw)", x: sample.roll, y: sample.pitch, z: sample.yaw)
                    VectorMetricView(title: "Gravity (g)", x: sample.gravX, y: sample.gravY, z: sample.gravZ)
                    HStack { Text("Heuristic POC"); Spacer(); Text(viewModel.motion.detectedMovement).fontWeight(.semibold) }
                }
                .padding(.top, 2)
            } else {
                Text("Start Sensor on a physical iPhone.").foregroundStyle(.secondary)
            }
        }
    }
}

private struct TrialControlSection: View {
    @ObservedObject var viewModel: SensorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if viewModel.motion.isCountingDown { Text("Countdown: \(viewModel.motion.countdownRemaining)").font(.title2.bold()) }
            if viewModel.motion.isTrialRecording {
                ProgressView(value: viewModel.motion.recordingProgress)
                Button("Stop Trial", role: .destructive) { viewModel.stopTrial() }.buttonStyle(.bordered)
            } else {
                Button("Start Trial (3 s countdown + 4 s record)") { viewModel.startTrial() }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.motion.isCountingDown)
            }
        }
    }
}

private struct VectorMetricView: View {
    let title: String
    let x: Double
    let y: Double
    let z: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.subheadline.weight(.medium))
            HStack { value("x", x); value("y", y); value("z", z) }
        }
    }

    private func value(_ label: String, _ number: Double) -> some View {
        VStack(alignment: .leading) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(number, format: .number.precision(.fractionLength(3)))
                .font(.system(.body, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SensorResearchNotesView: View {
    var body: some View {
        GroupBox("Research notes") {
            Text("Waist is the symmetric baseline; abdomen/chest help test torso motion; pockets add asymmetric fabric/leg artefacts; handheld is for punch-motion comparison only. Repeat 5–10 trials per movement × placement × speed. IMU-only is plausible for timing, activity, body-shift and rotation clues; semantic arms/legs, posture correctness, and boxing technique generally require Vision or wearables.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }
}
