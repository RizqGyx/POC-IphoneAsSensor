import Combine
import Foundation

@MainActor final class RhythmCueManager: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var beat = 0
    @Published private(set) var latestCueTimestamp: TimeInterval?
    @Published private(set) var cueText = "Ready"
    private var timer: Timer?
    func start(bpm: Int, pattern: RhythmPattern) { stop(); isRunning = true; emit(pattern); timer = Timer.scheduledTimer(withTimeInterval: 60 / Double(bpm), repeats: true) { [weak self] _ in Task { @MainActor [weak self] in self?.emit(pattern) } } }
    func stop() { timer?.invalidate(); timer = nil; isRunning = false; cueText = "Ready" }
    private func emit(_ pattern: RhythmPattern) { beat += 1; latestCueTimestamp = ProcessInfo.processInfo.systemUptime; switch pattern { case .single: cueText = "MOVE"; case .repeated: cueText = "REPEAT"; case .hold: cueText = beat.isMultiple(of: 4) ? "RELEASE" : "HOLD"; case .alternating: cueText = beat.isMultiple(of: 2) ? "RIGHT" : "LEFT"; case .sequential: cueText = ["1", "2", "3", "4"][(beat - 1) % 4] } }
}
