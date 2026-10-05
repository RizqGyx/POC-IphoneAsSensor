import Foundation

enum CSVExporter {
    static func export(_ trial: Trial) throws -> URL {
        let f = ISO8601DateFormatter(); let stamp = f.string(from: trial.startedAt).replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("motion-trial-\(stamp).csv")
        var csv = "# trialStartedAt,\(f.string(from: trial.startedAt))\n"
        csv += "timestamp,challengeResponse,movement,placement,speed,userAccX,userAccY,userAccZ,rotX,rotY,rotZ,roll,pitch,yaw,gravX,gravY,gravZ,cueTimestamp\n"
        for s in trial.samples {
            let cue = s.cueTimestamp.map { String($0) } ?? ""
            csv += "\(s.timestamp),\(s.challengeResponse.rawValue),\(s.movement.rawValue),\(s.placement.rawValue),\(s.speed.rawValue),\(s.userAccX),\(s.userAccY),\(s.userAccZ),\(s.rotX),\(s.rotY),\(s.rotZ),\(s.roll),\(s.pitch),\(s.yaw),\(s.gravX),\(s.gravY),\(s.gravZ),\(cue)\n"
        }
        try csv.write(to: url, atomically: true, encoding: .utf8); return url
    }
}
