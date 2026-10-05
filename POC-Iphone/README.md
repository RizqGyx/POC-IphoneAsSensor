# Two-device Movement Research POC

SwiftUI + Core Motion exploration for determining what an iPhone IMU adds to CR1 rhythm/dance and CR3 dungeon/boxing. It records how the **phone** moves, not a semantic body pose or movement-correctness judgment.

The same target now runs in two roles:

- **iPhone:** wearable sensor, recording processed `CMDeviceMotion`, trial CSV, and either raw or processed-event stream.
- **Mac Catalyst:** large cue/control surface. It sends cues and trial controls, receives live motion/events, and displays response estimate, peaks, transport latency, and recent placement summaries.

Both peers discover each other over local Wi-Fi / peer-to-peer using `MultipeerConnectivity`; no backend or cloud is used. The current SDK marks MultipeerConnectivity APIs deprecated in favor of Network.framework. It remains implemented here because it is the smallest Apple-native POC path; transport measurements are intentionally displayed so a later Network.framework replacement can be evaluated against it.

## Project layout

```text
POC-Iphone/
├── Models/
│   ├── MovementSample.swift          # Domain labels, samples, trials
│   ├── TrialAnalysis.swift
│   └── Networking/NetworkPacket.swift
├── Services/
│   ├── MotionManager.swift
│   ├── ConnectivityManager.swift
│   ├── RhythmCueManager.swift
│   ├── TrialRecorder.swift
│   ├── MovementAnalyzer.swift
│   ├── MovementClassifier.swift
│   ├── CSVExporter.swift
│   └── Protocols/MovementFusionManaging.swift
├── ViewModels/
│   ├── AppViewModel.swift
│   ├── SensorViewModel.swift
│   └── MacControlViewModel.swift
└── Views/
    ├── ContentView.swift
    ├── MacControlView.swift
    ├── Sensor/SensorHomeView.swift
    └── Components/
        ├── SensorGraphView.swift
        └── TrialResultView.swift
```

## Key files

- `AppViewModel.swift`: composition root; injects shared services and routes remote cue/trial controls.
- `SensorViewModel.swift`: iPhone screen state, sensor/rhythm/trial actions, and CSV export state.
- `MacControlViewModel.swift`: Mac cue state, response metrics, placement-history state, and remote trial actions.
- `ContentView.swift` / `MacControlView.swift`: SwiftUI rendering only; they do not own experiment business logic.
- `MotionManager.swift`: processed `CMDeviceMotion` at 60 Hz, countdown, 4-second record window, and live values.
- `MovementSample.swift`: challenge, ground-truth movement, placement, speed, and all sensor values.
- `TrialRecorder.swift`: intentionally small per-trial sample collector.
- `MovementAnalyzer.swift`: acceleration/rotation metrics, movement-onset heuristic, nearest-cue timing error, dominant axis.
- `RhythmCueManager.swift`: visual metronome/cue for 60/90/120/150 BPM.
- `MovementClassifier.swift`: debug-only live heuristic; never ground truth.
- `SensorGraphView.swift` / `TrialResultView.swift`: result visualisation.
- `CSVExporter.swift`: shareable raw-sample CSV.
- `ConnectivityManager.swift`: peer discovery, Raw Motion vs Processed Event packets, cue/control packets, and transport statistics.
- `MacControlView.swift`: Catalyst Mac cue/control dashboard for CR1 and CR3.
- `MovementFusionManaging.swift`: Vision/IMU extension interface only; it does not implement or link Vision.

## MVVM boundaries

- **Models:** `MovementSample`, `Trial`, `TrialConfiguration`, network packet types, and analysis result values. They are plain `Sendable` data.
- **Services:** `MotionManager`, `ConnectivityManager`, `RhythmCueManager`, `TrialRecorder`, `MovementAnalyzer`, and `CSVExporter`. They perform device, networking, timing, storage, or calculation work.
- **ViewModels:** `AppViewModel`, `SensorViewModel`, and `MacControlViewModel`. They own presentation state and map user actions to services.
- **Views:** `ContentView`, `SensorHomeView`, `MacControlView`, `TrialResultView`, and `SensorGraphView`. They render state and call ViewModel actions.

## Run on physical iPhone

1. Open `POC-Iphone.xcodeproj` in Xcode.
2. Target **POC-Iphone** → **Signing & Capabilities**: select your Apple Development Team and, if required, set a unique bundle identifier.
3. Run once to the connected iPhone. Accept the **Local Network** permission prompt.
4. Select **My Mac (Mac Catalyst)** as a second run destination and run the same target. The Mac opens the control center automatically.
5. Keep both apps open. After they show Connected, choose a cue on Mac, choose placement/speed, then start the iPhone trial from Mac.

`CMMotionManager` device-motion updates require no Motion/Fitness privacy key. Local Network and Bonjour service declarations are configured in the generated Info.plist. The Simulator is not valid for the sensor experiment.

## Protocol

For each movement, placement, and speed, keep orientation/mounting fixed and capture 5–10 trials. Start the iPhone sensor, select CR1 or CR3, a ground-truth movement, placement, and speed, then start a trial. A 3-second countdown is followed by a 4-second recording; it can also be stopped manually. For CR1, the iPhone retains its local BPM mode; the Mac control center is the primary large-distance cue view.

On iPhone, compare **Raw Motion Streaming** (one processed sample per update, sent unreliably to avoid backlog) and **Processed Events** (reliable state-change events only). Do not treat event names as ground truth: they are threshold baselines for testing whether edge processing is useful.

Export every trial. The header is:

`timestamp,challengeResponse,movement,placement,speed,userAccX,userAccY,userAccZ,rotX,rotY,rotZ,roll,pitch,yaw,gravX,gravY,gravZ,cueTimestamp`

`timestamp` and iPhone-local `cueTimestamp` use the Core Motion-compatible monotonic iPhone time base, so their difference is suitable for timing inside one phone session. Mac and iPhone monotonic clocks are not synchronised: Mac response estimates use wall-clock send/receive epochs; displayed transport latency is `Mac received epoch − iPhone sent epoch`, not `Mac received epoch − iPhone sensor timestamp`.

## Reading results

- Compare peak/average acceleration, peak rotation, dominant axis, onset, and the two graphs across repeated trials—not one isolated trial.
- For CR1, timing error is movement onset minus nearest cue. It is a baseline heuristic, not a validated rhythm score.
- Test waist first as a symmetric reference; abdomen/chest for torso; pockets for natural-use artefacts; handheld only to understand hand/punch signal.

## Limits and next experiment

IMU can be useful for onset, rhythm energy, broad body shift, rotation, and rapid direction changes. It cannot reliably say whether the left/right arm, left/right leg, or a correct boxing technique caused the signal when mounted at the body. Pocket fabric, orientation, drift, device model, and personal movement style alter the data.

The next comparison should timestamp Vision pose frames and IMU samples together: Vision answers **what/where** (body part, pose, correctness); IMU contributes **when/how energetic** (onset, acceleration, rotation). Compare Vision-only, IMU-only, and fused trials before selecting primary versus supplementary input.
