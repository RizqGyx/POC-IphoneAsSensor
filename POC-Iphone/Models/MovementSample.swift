import Foundation

nonisolated enum ChallengeResponse: String, CaseIterable, Identifiable, Codable, Sendable { case cr1 = "CR1 Rhythm / Dance"; case cr3 = "CR3 Dungeon / Boxing"; var id: String { rawValue } }

/// Ground-truth labels selected by the researcher; not semantic IMU predictions.
nonisolated enum TestMovement: String, CaseIterable, Identifiable, Codable, Sendable {
    case idle = "Idle / Hold", stepLeft = "Step Left", stepRight = "Step Right", stepForward = "Step Forward", stepBackward = "Step Backward", sideStep = "Side Step", doubleStep = "Double Step", march = "March", kneeRaiseLeft = "Knee Raise Left", kneeRaiseRight = "Knee Raise Right", squat = "Squat", smallJump = "Small Jump", jumpLeftRight = "Jump Left / Right", weightShiftLeft = "Weight Shift Left", weightShiftRight = "Weight Shift Right", leanLeft = "Lean Left", leanRight = "Lean Right", bodyShiftLeft = "Body Shift Left", bodyShiftRight = "Body Shift Right", torsoRotationLeft = "Torso Rotation Left", torsoRotationRight = "Torso Rotation Right", bendForward = "Bend Forward", returnUpright = "Return Upright", bounce = "Bounce", leftArmUp = "Left Arm Up", rightArmUp = "Right Arm Up", bothArmsUp = "Both Arms Up", armCross = "Arm Cross", armOpen = "Arm Open", armSwing = "Arm Swing", alternatingArms = "Alternating Arms", leftArmLeftStep = "Left Arm + Left Step", oppositeArmLeg = "Opposite Arm + Opposite Leg"
    case dodgeLeft = "Dodge Left", dodgeRight = "Dodge Right", duck = "Duck", crouch = "Crouch", jump = "Jump", quickStop = "Quick Stop", rapidDirectionChange = "Rapid Direction Change", slipLeft = "Slip Left", slipRight = "Slip Right", rollUnder = "Roll Under", pullBack = "Pull Back", leanBack = "Lean Back", blockLeft = "Block Left", blockRight = "Block Right", pivot = "Pivot", leftJab = "Left Jab", rightJab = "Right Jab", cross = "Cross", leftHook = "Left Hook", rightHook = "Right Hook", leftUppercut = "Left Uppercut", rightUppercut = "Right Uppercut", bodyShotLeft = "Body Shot Left", bodyShotRight = "Body Shot Right", jabCross = "Jab → Cross", jabCrossHook = "Jab → Cross → Hook", slipLeftCounter = "Slip Left → Counter", duckHook = "Duck → Hook"
    var id: String { rawValue }
    var challenge: ChallengeResponse { switch self { case .dodgeLeft, .dodgeRight, .duck, .crouch, .jump, .quickStop, .rapidDirectionChange, .slipLeft, .slipRight, .rollUnder, .pullBack, .leanBack, .blockLeft, .blockRight, .pivot, .leftJab, .rightJab, .cross, .leftHook, .rightHook, .leftUppercut, .rightUppercut, .bodyShotLeft, .bodyShotRight, .jabCross, .jabCrossHook, .slipLeftCounter, .duckHook: return .cr3; default: return .cr1 } }
}

nonisolated enum PhonePlacement: String, CaseIterable, Identifiable, Codable, Sendable { case waistCenter = "Waist Center", abdomen = "Abdomen / Stomach", chest = "Chest", rightPocket = "Right Pocket", leftPocket = "Left Pocket", handheld = "Handheld"; var id: String { rawValue } }
nonisolated enum MovementSpeed: String, CaseIterable, Identifiable, Codable, Sendable { case slow = "Slow", medium = "Medium", fast = "Fast"; var id: String { rawValue } }
nonisolated enum RhythmPattern: String, CaseIterable, Identifiable, Codable, Sendable { case single = "Single", repeated = "Repeated", hold = "Hold", alternating = "Alternating", sequential = "Sequential"; var id: String { rawValue } }

nonisolated struct TrialConfiguration: Codable, Sendable { let challenge: ChallengeResponse; let movement: TestMovement; let placement: PhonePlacement; let speed: MovementSpeed }

/// Processed CMDeviceMotion: acceleration/gravity in g; rotation rad/s; attitude radians.
nonisolated struct MovementSample: Identifiable, Sendable {
    let id = UUID(); let timestamp: TimeInterval; let challengeResponse: ChallengeResponse; let movement: TestMovement; let placement: PhonePlacement; let speed: MovementSpeed
    let userAccX, userAccY, userAccZ: Double; let rotX, rotY, rotZ: Double; let roll, pitch, yaw: Double; let gravX, gravY, gravZ: Double; let cueTimestamp: TimeInterval?
    var accelerationMagnitude: Double { sqrt(userAccX * userAccX + userAccY * userAccY + userAccZ * userAccZ) }
    var rotationMagnitude: Double { sqrt(rotX * rotX + rotY * rotY + rotZ * rotZ) }
}

nonisolated struct Trial: Identifiable, Sendable { let id = UUID(); let configuration: TrialConfiguration; let samples: [MovementSample]; let startedAt: Date; let duration: TimeInterval }
