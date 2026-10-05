import Foundation

nonisolated enum StreamingMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case raw = "Raw Motion Streaming"
    case events = "Processed Events"
    var id: String { rawValue }
}

nonisolated enum MotionEventKind: String, Codable, Sendable {
    case movementStarted, movementStopped, leftMotion, rightMotion
    case jumpCandidate, duckCandidate, rotationDetected
}

nonisolated struct MotionPayload: Codable, Sendable {
    let sensorTimestamp: TimeInterval
    let sentAtEpoch: TimeInterval
    let userAccX, userAccY, userAccZ: Double
    let rotX, rotY, rotZ: Double
    let roll, pitch, yaw: Double
    let gravX, gravY, gravZ: Double
    let placement: String
    let movement: String

    static func from(_ sample: MovementSample) -> MotionPayload {
        MotionPayload(
            sensorTimestamp: sample.timestamp,
            sentAtEpoch: Date().timeIntervalSince1970,
            userAccX: sample.userAccX, userAccY: sample.userAccY, userAccZ: sample.userAccZ,
            rotX: sample.rotX, rotY: sample.rotY, rotZ: sample.rotZ,
            roll: sample.roll, pitch: sample.pitch, yaw: sample.yaw,
            gravX: sample.gravX, gravY: sample.gravY, gravZ: sample.gravZ,
            placement: sample.placement.rawValue,
            movement: sample.movement.rawValue
        )
    }

    var accelerationMagnitude: Double { sqrt(userAccX * userAccX + userAccY * userAccY + userAccZ * userAccZ) }
    var rotationMagnitude: Double { sqrt(rotX * rotX + rotY * rotY + rotZ * rotZ) }
}

nonisolated struct MotionEvent: Codable, Sendable {
    let kind: MotionEventKind
    let sensorTimestamp, sentAtEpoch, peakAcceleration, peakRotation: TimeInterval
}

nonisolated struct CueCommand: Codable, Sendable {
    let text: String
    let cueTimestamp: TimeInterval
    let requiresVision: Bool
}

nonisolated enum TrialControlAction: String, Codable, Sendable { case start, stop }

nonisolated struct TrialControl: Codable, Sendable {
    let action: TrialControlAction
    let configuration: TrialConfiguration?
}

nonisolated enum NetworkPacket: Codable, Sendable {
    case motion(MotionPayload)
    case event(MotionEvent)
    case cue(CueCommand)
    case control(TrialControl)
}
