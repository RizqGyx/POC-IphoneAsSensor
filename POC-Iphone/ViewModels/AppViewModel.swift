import Combine
import Foundation

/// Composition root for the two-device POC. Services are shared by the iPhone
/// sensor UI and the Mac control UI, while each screen keeps its own presentation state.
@MainActor
final class AppViewModel: ObservableObject {
    let connectivity: ConnectivityManager
    let sensor: SensorViewModel
    let macControl: MacControlViewModel

    private var cancellables = Set<AnyCancellable>()

    init() {
        let connectivity = ConnectivityManager()
        self.connectivity = connectivity
        self.sensor = SensorViewModel(
            motion: MotionManager(),
            rhythm: RhythmCueManager(),
            connectivity: connectivity
        )
        self.macControl = MacControlViewModel(connectivity: connectivity)

        connectivity.$lastCue
            .compactMap { $0 }
            .sink { [weak self] _ in
                // Core Motion timestamps are local to the iPhone. Store the cue at
                // receipt time in the same iPhone monotonic clock domain.
                self?.sensor.registerRemoteCue()
            }
            .store(in: &cancellables)

        connectivity.$lastControl
            .compactMap { $0 }
            .sink { [weak self] control in
                self?.sensor.handle(control: control)
            }
            .store(in: &cancellables)
    }

    func start() {
        connectivity.start()
        sensor.start()
    }
}
