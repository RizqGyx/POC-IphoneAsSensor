import Foundation

@MainActor final class TrialRecorder {
    private(set) var configuration: TrialConfiguration?; private(set) var startedAt: Date?; private var samples: [MovementSample] = []
    func start(configuration: TrialConfiguration) { self.configuration = configuration; startedAt = Date(); samples = [] }
    func append(_ sample: MovementSample) { samples.append(sample) }
    func stop() -> Trial? { guard let configuration, let startedAt else { return nil }; defer { self.configuration = nil; self.startedAt = nil; samples = [] }; return Trial(configuration: configuration, samples: samples, startedAt: startedAt, duration: Date().timeIntervalSince(startedAt)) }
}
