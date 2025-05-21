import SwiftUI
import GameKit

class RulesRaceMultiplayerManager: NSObject, ObservableObject {
    @Published var isGameCenterEnabled = false
    @Published var isMatchmaking = false
    @Published var match: GKMatch?
    @Published var connectedPlayers: [GKPlayer] = []
    @Published var localPlayer: GKLocalPlayer = .local
    
    static let shared = RulesRaceMultiplayerManager()
    
    override init() {
        super.init()
        authenticatePlayer()
    }
    
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            if let viewController = viewController {
                // Present the view controller if needed
                print("Authentication required")
            } else if let error = error {
                print("Error authenticating: \(error.localizedDescription)")
            } else {
                self.isGameCenterEnabled = GKLocalPlayer.local.isAuthenticated
                if self.isGameCenterEnabled {
                    self.localPlayer = GKLocalPlayer.local
                }
            }
        }
    }
    
    func startMatchmaking() {
        guard isGameCenterEnabled else { return }
        
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4
        
        let matchmakingVC = GKMatchmakerViewController(matchRequest: request)
        matchmakingVC?.matchmakerDelegate = self
        
        isMatchmaking = true
    }
    
    func sendGameData(_ data: GameData) {
        guard let match = match else { return }
        
        do {
            let encodedData = try JSONEncoder().encode(data)
            try match.sendData(toAllPlayers: encodedData, with: .reliable)
        } catch {
            print("Error sending game data: \(error.localizedDescription)")
        }
    }
}

// MARK: - GKMatchmakerViewControllerDelegate
extension RulesRaceMultiplayerManager: GKMatchmakerViewControllerDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        isMatchmaking = false
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        isMatchmaking = false
        print("Matchmaking failed: \(error.localizedDescription)")
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        self.match = match
        match.delegate = self
        isMatchmaking = false
        viewController.dismiss(animated: true)
        
        // Initialize connected players
        connectedPlayers = match.players
    }
}

// MARK: - GKMatchDelegate
extension RulesRaceMultiplayerManager: GKMatchDelegate {
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            if !connectedPlayers.contains(player) {
                connectedPlayers.append(player)
            }
        case .disconnected:
            connectedPlayers.removeAll { $0 == player }
        default:
            break
        }
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromPlayer playerID: String) {
        do {
            let gameData = try JSONDecoder().decode(GameData.self, from: data)
            NotificationCenter.default.post(name: .gameDataReceived, object: gameData)
        } catch {
            print("Error decoding game data: \(error.localizedDescription)")
        }
    }
}

// Game data structure for syncing
struct GameData: Codable {
    let type: GameDataType
    let playerIndex: Int
    let diceResult: String?
    let position: Int?
    let isInPrison: Bool?
    let escapeTickets: Int?
    let personalRules: [String]?
}

enum GameDataType: String, Codable {
    case diceRoll
    case playerMove
    case customRule
    case gameState
}

// Notification name for game data
extension Notification.Name {
    static let gameDataReceived = Notification.Name("gameDataReceived")
} 