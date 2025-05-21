import SwiftUI
import Combine // Keep for AnyCancellable if needed, though likely not for this service's core logic
import MultipeerConnectivity

// Protocol for the Game Service that Engine will use
protocol GameNetworkingService {
    var localPlayerId: String { get }
    func startAdvertising()
    func startBrowsing()
    func sendData<T: Codable>(_ data: T, type: String)
    func disconnect()
    // Add any other necessary methods for the engine to call, e.g., setEngineReference
    func setEngineReference(_ engine: EquationHighLowEngine)
}

// Generic wrapper for sending typed data
struct GameDataWrapper<Payload: Codable>: Codable {
    let type: String
    let payload: Payload
}

class EquationHighLowGameService: NSObject, GameNetworkingService {
    weak var engine: EquationHighLowEngine? // Reference to the engine
    
    // Using the constant defined in EquationHighLowModels.swift
    private let serviceType = EquationHighLowServiceType 
    private let myPeerId: MCPeerID
    private var session: MCSession?
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    
    // isHost will be determined by the engine's logic (e.g., calling startAdvertising or startBrowsing)
    // private var isHostInternal: Bool = false 

    var localPlayerId: String { myPeerId.displayName }

    override init() {
        self.myPeerId = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        setupMultipeerConnectivity()
    }

    func setEngineReference(_ engine: EquationHighLowEngine) {
        self.engine = engine
    }
    
    private func setupMultipeerConnectivity() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceAdvertiser?.delegate = self
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        serviceBrowser?.delegate = self
    }
    
    // MARK: - GameNetworkingService Conformance
    func startAdvertising() {
        serviceAdvertiser?.startAdvertisingPeer()
        AppLogger.info("Started advertising as \(myPeerId.displayName)")
    }
    
    func startBrowsing() {
        serviceBrowser?.startBrowsingForPeers()
        AppLogger.info("Started browsing for peers as \(myPeerId.displayName)")
    }

    func sendData<T: Codable>(_ data: T, type: String) {
        let wrapper = GameDataWrapper(type: type, payload: data)
        guard let encodedData = try? JSONEncoder().encode(wrapper) else {
            AppLogger.error("Error encoding \(type) data. PlayerID: \(localPlayerId)")
            return
        }
        
        guard let session = session, !session.connectedPeers.isEmpty else {
            AppLogger.debug("No connected peers or session not available to send type \(type). PlayerID: \(localPlayerId)")
            return
        }
        
        do {
            try session.send(encodedData, toPeers: session.connectedPeers, with: .reliable)
            AppLogger.debug("Sent \(type) data to peers. PlayerID: \(localPlayerId)")
        } catch {
            AppLogger.error("Error sending \(type) data: \(error.localizedDescription). PlayerID: \(localPlayerId)")
        }
    }
    
    func disconnect() {
        serviceAdvertiser?.stopAdvertisingPeer()
        AppLogger.info("Stopped advertising. PlayerID: \(localPlayerId)")
        serviceBrowser?.stopBrowsingForPeers()
        AppLogger.info("Stopped browsing for peers. PlayerID: \(localPlayerId)")
        session?.disconnect()
        AppLogger.info("Disconnecting session for \(myPeerId.displayName). PlayerID: \(localPlayerId)")
    }
    
    // Remove game-specific logic like submitBid, determineRoundWinner, updatePlayersAfterRound
}

// MARK: - MCSessionDelegate
extension EquationHighLowGameService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            AppLogger.info("Peer \(peerID.displayName) changed state to \(state.rawValueDescription). PlayerID: \(self.localPlayerId)")
            switch state {
            case .connected:
                AppLogger.info("Connected to peer: \(peerID.displayName). PlayerID: \(self.localPlayerId)")
                self.engine?.handlePeerConnected(playerId: peerID.displayName)
            case .notConnected:
                AppLogger.info("Disconnected from peer: \(peerID.displayName). PlayerID: \(self.localPlayerId)")
                self.engine?.handlePeerDisconnected(playerId: peerID.displayName)
            case .connecting:
                 AppLogger.info("Peer \(peerID.displayName) connecting. PlayerID: \(self.localPlayerId)")
                break
            @unknown default:
                AppLogger.warning("Unknown peer state (\(state.rawValueDescription)) for \(peerID.displayName). PlayerID: \(self.localPlayerId)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            AppLogger.debug("Received data from \(peerID.displayName). PlayerID: \(self.localPlayerId)")
            do {
                let decoder = JSONDecoder()
                // Attempt to decode the wrapper to get the type and the payload (which is still Data)
                let genericWrapper = try decoder.decode(GameDataWrapper<Data>.self, from: data)
                self.engine?.handleReceivedData(payload: genericWrapper.payload, type: genericWrapper.type, fromPlayerId: peerID.displayName)
            } catch {
                 AppLogger.error("Error decoding received data wrapper from \(peerID.displayName): \(error). PlayerID: \(self.localPlayerId)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        AppLogger.debug("Received stream with name '\(streamName)' from peer \(peerID.displayName). PlayerID: \(self.localPlayerId)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        AppLogger.debug("Started receiving resource '\(resourceName)' from peer \(peerID.displayName). Progress: \(progress). PlayerID: \(self.localPlayerId)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            AppLogger.error("Error receiving resource '\(resourceName)' from peer \(peerID.displayName): \(error.localizedDescription). PlayerID: \(self.localPlayerId)")
        } else {
            AppLogger.debug("Finished receiving resource '\(resourceName)' from peer \(peerID.displayName) at \(localURL?.absoluteString ?? "N/A"). PlayerID: \(self.localPlayerId)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension EquationHighLowGameService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        AppLogger.info("Received invitation from \(peerID.displayName). Auto-accepting. PlayerID: \(localPlayerId)")
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension EquationHighLowGameService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        AppLogger.info("Found peer: \(peerID.displayName). Inviting. PlayerID: \(localPlayerId)")
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        AppLogger.info("Lost peer: \(peerID.displayName). PlayerID: \(localPlayerId)")
        DispatchQueue.main.async {
            self.engine?.handlePeerLost(playerId: peerID.displayName)
        }
    }
}

// Helper extension for MCSessionState rawValue description
extension MCSessionState {
    var rawValueDescription: String {
        switch self {
        case .notConnected: return "notConnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        @unknown default: return "unknown"
        }
    }
}