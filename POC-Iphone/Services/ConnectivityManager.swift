import Combine
import Foundation
import MultipeerConnectivity

@MainActor final class ConnectivityManager: NSObject, ObservableObject {
    @Published private(set) var connectedPeers: [String] = []
    @Published private(set) var lastMotion: MotionPayload?
    @Published private(set) var lastEvent: MotionEvent?
    @Published private(set) var lastCue: CueCommand?
    @Published private(set) var lastControl: TrialControl?
    @Published private(set) var latencySamples: [TimeInterval] = []
    @Published var streamingMode: StreamingMode = .raw
    @Published private(set) var status = "Searching for peer…"

    private let service = "motion-poc-6"
    private let peer = MCPeerID(displayName: String(ProcessInfo.processInfo.hostName.prefix(32)))
    private lazy var session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    override init() { super.init(); session.delegate = self }
    func start() {
        guard advertiser == nil else { return }
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: ["role": "motion-poc"], serviceType: service)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: service)
        advertiser?.delegate = self; browser?.delegate = self; advertiser?.startAdvertisingPeer(); browser?.startBrowsingForPeers()
    }
    func stop() { advertiser?.stopAdvertisingPeer(); browser?.stopBrowsingForPeers(); session.disconnect(); advertiser = nil; browser = nil; connectedPeers = []; status = "Connection stopped" }
    func sendMotion(_ sample: MovementSample) { send(.motion(.from(sample)), reliably: false) }
    func sendEvent(_ event: MotionEvent) { send(.event(event), reliably: true) }
    func sendCue(text: String, requiresVision: Bool) { send(.cue(CueCommand(text: text, cueTimestamp: ProcessInfo.processInfo.systemUptime, requiresVision: requiresVision)), reliably: true) }
    func sendTrialStart(_ configuration: TrialConfiguration) { send(.control(TrialControl(action: .start, configuration: configuration)), reliably: true) }
    func sendTrialStop() { send(.control(TrialControl(action: .stop, configuration: nil)), reliably: true) }
    private func send(_ packet: NetworkPacket, reliably: Bool) {
        guard !session.connectedPeers.isEmpty, let data = try? JSONEncoder().encode(packet) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: reliably ? .reliable : .unreliable)
    }
    private func receive(_ data: Data) {
        guard let packet = try? JSONDecoder().decode(NetworkPacket.self, from: data) else { return }
        let receivedAt = Date().timeIntervalSince1970
        switch packet {
        case .motion(let payload):
            lastMotion = payload; appendLatency(receivedAt - payload.sentAtEpoch)
        case .event(let event):
            lastEvent = event; appendLatency(receivedAt - event.sentAtEpoch)
        case .cue(let cue): lastCue = cue
        case .control(let control): lastControl = control
        }
    }
    private func appendLatency(_ value: TimeInterval) { guard value >= 0 else { return }; latencySamples = Array((latencySamples + [value]).suffix(100)) }
    var currentLatency: TimeInterval? { latencySamples.last }
    var averageLatency: TimeInterval? { latencySamples.isEmpty ? nil : latencySamples.reduce(0, +) / Double(latencySamples.count) }
    var minLatency: TimeInterval? { latencySamples.min() }
    var maxLatency: TimeInterval? { latencySamples.max() }
}

extension ConnectivityManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) { Task { @MainActor [weak self] in self?.connectedPeers = session.connectedPeers.map(\.displayName); self?.status = state == .connected ? "Connected to \(peerID.displayName)" : "Searching for peer…" } }
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) { Task { @MainActor [weak self] in self?.receive(data) } }
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
extension ConnectivityManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) { Task { @MainActor [weak self] in invitationHandler(true, self?.session) } }
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) { Task { @MainActor [weak self] in guard let self else { return }; browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10) } }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
}
