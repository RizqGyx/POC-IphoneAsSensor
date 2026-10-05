import Foundation

/// Debug-only placement-dependent heuristic, not a semantic classifier.
struct MovementClassifier {
    var neutralPitch: Double?
    mutating func calibrate(with sample: MovementSample?) { neutralPitch = sample?.pitch }
    func classify(_ sample: MovementSample) -> String {
        if sample.userAccY > 1.10 { return "Possible jump" }
        if let neutralPitch, abs(sample.pitch - neutralPitch) > 0.32, sample.userAccY < 0.15 { return "Possible duck / bend" }
        if abs(sample.userAccX) > 0.65, abs(sample.userAccX) > abs(sample.userAccY) { return sample.userAccX < 0 ? "Possible left shift" : "Possible right shift" }
        if sample.rotationMagnitude > 1.2 { return "Active rotation" }
        return "Still / unknown"
    }
}
