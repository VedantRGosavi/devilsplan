import SwiftUI
import Combine
import MultipeerConnectivity

class EquationHighLowGameService: NSObject {
    // MARK: - Properties
    private let serviceType = "eqn-high-low"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    
    private var isHost = false
    private(set) var currentPlayerId: String
    private var players: [Player] = []
    private var bids: [Bid] = []
    
    // MARK: - Publishers
    private let gameStateSubject = PassthroughSubject<GameState, Never>()
    var gameStatePublisher: AnyPublisher<GameState, Never> {
        gameStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    override init() {
        self.currentPlayerId = UUID().uuidString
        super.init()
        setupMultipeerConnectivity()
    }
    
    // MARK: - Setup
    private func setupMultipeerConnectivity() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        // Setup service advertiser and browser
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
        gameStateSubject.send(.waitingForPlayers)
    }
    
    func joinGame() {
        serviceBrowser?.startBrowsingForPeers()
    }
    
    func submitBid(_ bid: Bid) {
        // Send bid to all peers
        let bidData = try? JSONEncoder().encode(["type": "bid", "data": bid])
        sendData(bidData)
        
        bids.append(bid)
        
        // If host, check if all players have bid
        if isHost && bids.count == players.count {
            determineRoundWinner()
        }
    }
    
    func determineRoundWinner() {
        guard isHost else { return }
        
        // Group bids by high/low target
        let highBids = bids.filter { $0.targetHigh }
        let lowBids = bids.filter { !$0.targetHigh }
        
        // Find the closest result to target (20 for high, 1 for low)
        let highWinner = highBids.min { abs($0.equationResult - 20) < abs($1.equationResult - 20) }
        let lowWinner = lowBids.min { abs($0.equationResult - 1) < abs($1.equationResult - 1) }
        
        // Determine overall winner
        var winner: Bid?
        if let high = highWinner, let low = lowWinner {
            // Compare distances to respective targets
            let highDistance = abs(high.equationResult - 20)
            let lowDistance = abs(low.equationResult - 1)
            winner = highDistance < lowDistance ? high : low
        } else {
            winner = highWinner ?? lowWinner
        }
        
        // Update chips and eliminate players
        if let winner = winner {
            updatePlayersAfterRound(winner: winner)
        }
        
        // Send results to all peers
        let resultData = try? JSONEncoder().encode([
            "type": "roundResult",
            "winner": winner?.playerId ?? "",
            "players": players
        ])
        sendData(resultData)
        
        // Clear bids for next round
        bids.removeAll()
        
        // Check if game should end
        if players.filter({ !$0.isEliminated }).count <= 3 {
            gameStateSubject.send(.gameEnded)
        } else {
            gameStateSubject.send(.playing)
        }
    }
    
    private func updatePlayersAfterRound(winner: Bid) {
        // Winner collects all bids
        let totalBids = bids.reduce(0) { $0 + $1.amount }
        
        for i in 0..<players.count {
            if players[i].id == winner.playerId {
                players[i].chips += totalBids
            } else {
                players[i].chips -= bids.first(where: { $0.playerId == players[i].id })?.amount ?? 0
                if players[i].chips <= 0 {
                    players[i].isEliminated = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func sendData(_ data: Data?) {
        guard let data = data,
              let session = session,
              !session.connectedPeers.isEmpty else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCSessionDelegate
extension EquationHighLowGameService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            if isHost {
                // Add new player
                let newPlayer = Player(id: peerID.displayName, chips: 100, isEliminated: false)
                players.append(newPlayer)
                
                // Send current game state to all peers
                let gameData = try? JSONEncoder().encode([
                    "type": "gameState",
                    "players": players
                ])
                sendData(gameData)
                
                if players.count >= 2 {
                    gameStateSubject.send(.playing)
                }
            }
        case .disconnected:
            if isHost {
                // Remove disconnected player
                players.removeAll(where: { $0.id == peerID.displayName })
                if players.count < 2 {
                    gameStateSubject.send(.waitingForPlayers)
                }
            }
        default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        switch type {
        case "bid":
            if let bidData = try? JSONDecoder().decode(Bid.self, from: data) {
                bids.append(bidData)
                if isHost && bids.count == players.count {
                    determineRoundWinner()
                }
            }
        case "roundResult":
            if let players = json["players"] as? [Player] {
                self.players = players
                gameStateSubject.send(.roundEnded)
            }
        case "gameState":
            if let players = json["players"] as? [Player] {
                self.players = players
                gameStateSubject.send(.playing)
            }
        default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension EquationHighLowGameService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension EquationHighLowGameService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Handle peer loss if needed
    }
} 