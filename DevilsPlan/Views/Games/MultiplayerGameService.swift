import SwiftUI
import MultipeerConnectivity
import Combine
import GameKit

class MultiplayerGameService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isGameCenterEnabled = false
    @Published var isMatchmaking = false
    @Published var match: GKMatch?
    @Published var connectedPlayers: [GKPlayer] = []
    @Published var localPlayer: GKLocalPlayer = .local
    
    // MARK: - Private Properties
    private var session: MCSession?
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private let serviceType: String
    private let myPeerId: MCPeerID
    
    private var isHost = false
    private(set) var currentPlayerId: String
    
    // MARK: - Publishers
    private let gameStateSubject = PassthroughSubject<GameState, Never>()
    var gameStatePublisher: AnyPublisher<GameState, Never> {
        gameStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(serviceType: String) {
        self.serviceType = serviceType
        self.myPeerId = MCPeerID(displayName: UIDevice.current.name)
        self.currentPlayerId = UUID().uuidString
        super.init()
        setupMultipeerConnectivity()
    }
    
    // MARK: - Setup
    private func setupMultipeerConnectivity() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        serviceAdvertiser?.delegate = self
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        serviceBrowser?.delegate = self
    }
    
    // MARK: - Game Control
    func startHosting() {
        isHost = true
        serviceAdvertiser?.startAdvertisingPeer()
        gameStateSubject.send(.notStarted)
    }
    
    func joinGame() {
        serviceBrowser?.startBrowsingForPeers()
    }
    
    func sendGameData<T: Encodable>(_ data: T, type: String) {
        let wrapper = GameDataWrapper(type: type, data: data)
        guard let encodedData = try? JSONEncoder().encode(wrapper) else { return }
        sendData(encodedData)
    }
    
    private func sendData(_ data: Data) {
        guard let session = session,
              !session.connectedPeers.isEmpty else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
    
    func disconnect() {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceBrowser?.stopBrowsingForPeers()
        session?.disconnect()
    }
}

// MARK: - MCSessionDelegate
extension MultiplayerGameService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if self.isHost {
                    self.gameStateSubject.send(.notStarted)
                }
            case .disconnected:
                self.gameStateSubject.send(.notStarted)
            default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let wrapper = try? JSONDecoder().decode(GameDataWrapper.self, from: data) else { return }
        NotificationCenter.default.post(
            name: .gameDataReceived,
            object: GameDataReceived(type: wrapper.type, data: wrapper.data, fromPeer: peerID)
        )
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultiplayerGameService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultiplayerGameService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

// MARK: - Supporting Types
struct GameDataWrapper: Codable {
    let type: String
    let data: Data
    
    init<T: Encodable>(type: String, data: T) throws {
        self.type = type
        self.data = try JSONEncoder().encode(data)
    }
}

struct GameDataReceived {
    let type: String
    let data: Data
    let fromPeer: MCPeerID
}

extension Notification.Name {
    static let gameDataReceived = Notification.Name("gameDataReceived")
} 