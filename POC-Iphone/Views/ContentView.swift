import SwiftUI

/// Chooses the appropriate presentation surface while `AppViewModel` owns the
/// shared service graph for both device roles.
struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()

    var body: some View {
        Group {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                MacControlView(viewModel: appViewModel.macControl)
            } else {
                SensorHomeView(viewModel: appViewModel.sensor)
            }
        }
        .onAppear { appViewModel.start() }
    }
}

#Preview { ContentView() }
