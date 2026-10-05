import Combine
import CoreMotion
import Foundation

@MainActor final class MotionManager: ObservableObject {
    @Published private(set) var latestSample: MovementSample?
    @Published private(set) var isSensorRunning = false
    @Published private(set) var isTrialRecording = false
    @Published private(set) var isCountingDown = false
    @Published private(set) var countdownRemaining = 0
    @Published private(set) var recordingProgress = 0.0
    @Published private(set) var detectedMovement = "Still / unknown"
    @Published private(set) var completedTrial: Trial?
    @Published private(set) var analysis: TrialAnalysis?
    @Published private(set) var statusMessage = "Sensor stopped"
    let recordingDuration: TimeInterval = 4

    private let manager = CMMotionManager()
    private let queue: OperationQueue = { let q = OperationQueue(); q.name = "motion-updates"; q.qualityOfService = .userInteractive; return q }()
    private let recorder = TrialRecorder()
    private var classifier = MovementClassifier(), timer: Timer?, lastCueTimestamp: TimeInterval?
    private weak var connectivity: ConnectivityManager?
    private var lastSentEvent: MotionEventKind?

    func connect(to manager: ConnectivityManager) { connectivity = manager }

    func startSensor() {
        guard !isSensorRunning else { return }; guard manager.isDeviceMotionAvailable else { statusMessage = "Device Motion unavailable — use physical iPhone"; return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard self != nil else { return }
            if let error { Task { @MainActor [weak self] in self?.statusMessage = error.localizedDescription }; return }
            guard let motion else { return }; let values = Self.values(from: motion)
            Task { @MainActor [weak self, values] in self?.receive(values) }
        }
        isSensorRunning = true; statusMessage = "Processed CMDeviceMotion at 60 Hz"
    }
    func stopSensor() { stopTrial(); manager.stopDeviceMotionUpdates(); isSensorRunning = false; statusMessage = "Sensor stopped" }
    func registerCue(timestamp: TimeInterval?) { lastCueTimestamp = timestamp }

    func startTrial(configuration: TrialConfiguration) {
        if !isSensorRunning { startSensor() }; guard isSensorRunning else { return }
        completedTrial = nil; analysis = nil; classifier.calibrate(with: latestSample); isCountingDown = true; countdownRemaining = 3; statusMessage = "Get ready… 3"
        timer?.invalidate(); timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in Task { @MainActor [weak self] in self?.advanceCountdown(configuration) } }
    }
    func stopTrial() {
        timer?.invalidate(); timer = nil; isCountingDown = false
        guard isTrialRecording else { return }
        if let trial = recorder.stop() { completedTrial = trial; analysis = MovementAnalyzer.analyze(trial); statusMessage = "Trial complete: \(trial.samples.count) samples" }
        isTrialRecording = false; recordingProgress = 0
    }
    private func advanceCountdown(_ configuration: TrialConfiguration) {
        countdownRemaining -= 1; guard countdownRemaining <= 0 else { statusMessage = "Get ready… \(countdownRemaining)"; return }
        timer?.invalidate(); recorder.start(configuration: configuration); isCountingDown = false; isTrialRecording = true; recordingProgress = 0; statusMessage = "Recording \(configuration.movement.rawValue)"
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in Task { @MainActor [weak self] in self?.advanceRecording() } }
    }
    private func advanceRecording() { guard let started = recorder.startedAt else { return }; recordingProgress = min(Date().timeIntervalSince(started) / recordingDuration, 1); if recordingProgress >= 1 { stopTrial() } }
    private func receive(_ v: Values) {
        let c = recorder.configuration ?? TrialConfiguration(challenge: .cr1, movement: .idle, placement: .waistCenter, speed: .medium)
        let s = MovementSample(timestamp: v.timestamp, challengeResponse: c.challenge, movement: c.movement, placement: c.placement, speed: c.speed, userAccX: v.ax, userAccY: v.ay, userAccZ: v.az, rotX: v.rx, rotY: v.ry, rotZ: v.rz, roll: v.roll, pitch: v.pitch, yaw: v.yaw, gravX: v.gx, gravY: v.gy, gravZ: v.gz, cueTimestamp: lastCueTimestamp)
        latestSample = s; detectedMovement = classifier.classify(s); if isTrialRecording { recorder.append(s) }
        guard let connectivity else { return }
        switch connectivity.streamingMode {
        case .raw: connectivity.sendMotion(s)
        case .events: streamEvent(from: s)
        }
    }
    private func streamEvent(from s: MovementSample) {
        let event: MotionEventKind? = switch detectedMovement {
        case "Possible left shift": .leftMotion
        case "Possible right shift": .rightMotion
        case "Possible jump": .jumpCandidate
        case "Possible duck / bend": .duckCandidate
        case "Active rotation": .rotationDetected
        default: s.accelerationMagnitude > 0.2 ? .movementStarted : .movementStopped
        }
        guard let event, event != lastSentEvent else { return }; lastSentEvent = event
        connectivity?.sendEvent(MotionEvent(kind: event, sensorTimestamp: s.timestamp, sentAtEpoch: Date().timeIntervalSince1970, peakAcceleration: s.accelerationMagnitude, peakRotation: s.rotationMagnitude))
    }
    nonisolated struct Values: Sendable { let timestamp, ax, ay, az, rx, ry, rz, roll, pitch, yaw, gx, gy, gz: Double }
    nonisolated private static func values(from m: CMDeviceMotion) -> Values { Values(timestamp: m.timestamp, ax: m.userAcceleration.x, ay: m.userAcceleration.y, az: m.userAcceleration.z, rx: m.rotationRate.x, ry: m.rotationRate.y, rz: m.rotationRate.z, roll: m.attitude.roll, pitch: m.attitude.pitch, yaw: m.attitude.yaw, gx: m.gravity.x, gy: m.gravity.y, gz: m.gravity.z) }
}
