import Combine
import Foundation

@MainActor
final class SensorViewModel: ObservableObject {
    let motion: MotionManager
    let rhythm: RhythmCueManager
    let connectivity: ConnectivityManager

    @Published var challenge: ChallengeResponse = .cr1 {
        didSet { normalizeSelectedMovement() }
    }
    @Published var movement: TestMovement = .idle
    @Published var placement: PhonePlacement = .waistCenter
    @Published var speed: MovementSpeed = .medium
    @Published var bpm = 120
    @Published var rhythmPattern: RhythmPattern = .single
    @Published private(set) var csvURL: URL?
    @Published private(set) var exportError: String?

    private var cancellables = Set<AnyCancellable>()

    init(motion: MotionManager, rhythm: RhythmCueManager, connectivity: ConnectivityManager) {
        self.motion = motion
        self.rhythm = rhythm
        self.connectivity = connectivity

        forwardChanges(from: motion)
        forwardChanges(from: rhythm)
        forwardChanges(from: connectivity)

        rhythm.$latestCueTimestamp
            .sink { [weak self] timestamp in self?.motion.registerCue(timestamp: timestamp) }
            .store(in: &cancellables)
    }

    var availableMovements: [TestMovement] {
        TestMovement.allCases.filter { $0.challenge == challenge }
    }

    var trialConfiguration: TrialConfiguration {
        TrialConfiguration(
            challenge: challenge,
            movement: movement,
            placement: placement,
            speed: speed
        )
    }

    func start() {
        motion.connect(to: connectivity)
    }

    func toggleSensor() {
        motion.isSensorRunning ? motion.stopSensor() : motion.startSensor()
    }

    func toggleRhythm() {
        rhythm.isRunning ? rhythm.stop() : rhythm.start(bpm: bpm, pattern: rhythmPattern)
    }

    func startTrial() {
        csvURL = nil
        exportError = nil
        motion.startTrial(configuration: trialConfiguration)
    }

    func stopTrial() {
        motion.stopTrial()
    }

    func export(_ trial: Trial) {
        do {
            csvURL = try CSVExporter.export(trial)
            exportError = nil
        } catch {
            csvURL = nil
            exportError = error.localizedDescription
        }
    }

    func registerRemoteCue() {
        motion.registerCue(timestamp: ProcessInfo.processInfo.systemUptime)
    }

    func handle(control: TrialControl) {
        switch control.action {
        case .start:
            guard let configuration = control.configuration else { return }
            motion.startTrial(configuration: configuration)
        case .stop:
            motion.stopTrial()
        }
    }

    private func normalizeSelectedMovement() {
        guard movement.challenge != challenge else { return }
        movement = availableMovements.first ?? .idle
    }

    private func forwardChanges(from object: some ObservableObject) {
        object.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
