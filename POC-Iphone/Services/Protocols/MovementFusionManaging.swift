import Foundation

/// Extension point only. Vision is deliberately not linked or implemented in this POC.
/// A future Mac/iPad pose pipeline can conform and combine body semantics with IMU timing.
protocol MovementFusionManaging {
    func ingestMotion(_ sample: MovementSample)
    func ingestVisionPose(timestamp: TimeInterval, summary: String)
}
