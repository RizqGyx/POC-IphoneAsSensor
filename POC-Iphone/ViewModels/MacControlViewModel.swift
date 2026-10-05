import Combine
import Foundation

@MainActor
final class MacControlViewModel: ObservableObject {
    let connectivity: ConnectivityManager

    @Published var challenge: ChallengeResponse = .cr1
    @Published var level = 1
    @Published var placement: PhonePlacement = .waistCenter
    @Published var speed: MovementSpeed = .medium
    @Published private(set) var currentCue = "CONNECT IPHONE"
    @Published private(set) var cueSentAt: TimeInterval?
    @Published private(set) var firstMotionAt: TimeInterval?
    @Published private(set) var peakAcceleration = 0.0
    @Published private(set) var peakRotation = 0.0
    @Published private(set) var detectedPattern = "—"
    @Published private(set) var history: [MacTrialSummary] = []

    private var selectedCue: MacCue?
    private var cancellables = Set<AnyCancellable>()

    init(connectivity: ConnectivityManager) {
        self.connectivity = connectivity
        connectivity.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        connectivity.$lastMotion
            .compactMap { $0 }
            .sink { [weak self] in self?.receive($0) }
            .store(in: &cancellables)
        connectivity.$lastEvent
            .compactMap { $0 }
            .sink { [weak self] in self?.receive($0) }
            .store(in: &cancellables)
    }

    var availableCues: [MacCue] {
        challenge == .cr1 ? MacCue.rhythmCues : MacCue.dungeonCues
    }

    var currentCueRequiresVision: Bool {
        selectedCue?.requiresVision ?? false
    }

    var estimatedResponse: TimeInterval? {
        guard let cueSentAt, let firstMotionAt else { return nil }
        return firstMotionAt - cueSentAt
    }

    func present(_ cue: MacCue) {
        selectedCue = cue
        currentCue = cue.text
        cueSentAt = Date().timeIntervalSince1970
        firstMotionAt = nil
        peakAcceleration = 0
        peakRotation = 0
        detectedPattern = "Waiting for iPhone"
        connectivity.sendCue(text: cue.text, requiresVision: cue.requiresVision)
    }

    func startRemoteTrial() {
        guard let selectedCue else { return }
        connectivity.sendTrialStart(
            TrialConfiguration(
                challenge: challenge,
                movement: selectedCue.movement,
                placement: placement,
                speed: speed
            )
        )
    }

    func stopRemoteTrial() {
        connectivity.sendTrialStop()
        saveResult()
    }

    private func receive(_ motion: MotionPayload) {
        peakAcceleration = max(peakAcceleration, motion.accelerationMagnitude)
        peakRotation = max(peakRotation, motion.rotationMagnitude)
        if firstMotionAt == nil, peakAcceleration > 0.3 {
            firstMotionAt = motion.sentAtEpoch
        }
        detectedPattern = "Raw motion stream"
    }

    private func receive(_ event: MotionEvent) {
        peakAcceleration = max(peakAcceleration, event.peakAcceleration)
        peakRotation = max(peakRotation, event.peakRotation)
        if firstMotionAt == nil, event.kind != .movementStopped {
            firstMotionAt = event.sentAtEpoch
        }
        detectedPattern = event.kind.rawValue
    }

    private func saveResult() {
        history.append(
            MacTrialSummary(
                movement: currentCue,
                placement: placement.rawValue,
                peakAcceleration: peakAcceleration,
                response: estimatedResponse
            )
        )
    }
}

struct MacCue: Identifiable {
    let id = UUID()
    let text: String
    let movement: TestMovement
    let requiresVision: Bool

    init(_ text: String, _ movement: TestMovement, requiresVision: Bool = false) {
        self.text = text
        self.movement = movement
        self.requiresVision = requiresVision
    }

    static let rhythmCues = [
        MacCue("LEFT", .weightShiftLeft), MacCue("RIGHT", .weightShiftRight),
        MacCue("UP", .bothArmsUp, requiresVision: true), MacCue("DOWN", .squat),
        MacCue("HOLD", .idle), MacCue("STEP LEFT", .stepLeft),
        MacCue("STEP RIGHT", .stepRight), MacCue("ROTATE LEFT", .torsoRotationLeft),
        MacCue("ROTATE RIGHT", .torsoRotationRight), MacCue("JUMP", .smallJump)
    ]
    static let dungeonCues = [
        MacCue("DODGE LEFT", .dodgeLeft), MacCue("DODGE RIGHT", .dodgeRight),
        MacCue("DUCK", .duck), MacCue("JUMP", .jump), MacCue("STEP LEFT", .stepLeft),
        MacCue("STEP RIGHT", .stepRight), MacCue("PULL BACK", .pullBack),
        MacCue("QUICK CHANGE LEFT → RIGHT", .rapidDirectionChange),
        MacCue("JAB", .leftJab, requiresVision: true), MacCue("CROSS", .cross, requiresVision: true),
        MacCue("LEFT HOOK", .leftHook, requiresVision: true),
        MacCue("RIGHT UPPERCUT", .rightUppercut, requiresVision: true),
        MacCue("JAB → CROSS", .jabCross, requiresVision: true),
        MacCue("SLIP → COUNTER", .slipLeftCounter, requiresVision: true)
    ]
}

struct MacTrialSummary: Identifiable {
    let id = UUID()
    let movement: String
    let placement: String
    let peakAcceleration: Double
    let response: TimeInterval?
}
