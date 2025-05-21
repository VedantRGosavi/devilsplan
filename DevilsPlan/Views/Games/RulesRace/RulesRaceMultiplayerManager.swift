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
            
            if let error = error {
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
    
    func sendGameData(_ data: RulesRaceGameData, type: String) {
        guard let match = match else { return }
        
        do {
            let gameData = MultiplayerGameData(type: type, data: data)
            let encodedData = try JSONEncoder().encode(gameData)
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
            let gameData = try JSONDecoder().decode(MultiplayerGameData.self, from: data)
            NotificationCenter.default.post(
                name: NSNotification.Name("gameDataReceived"),
                object: GameDataReceived(type: gameData.type, data: gameData.data)
            )
        } catch {
            print("Error decoding game data: \(error.localizedDescription)")
        }
    }
}

// Game data structures for syncing
struct MultiplayerGameData: Codable {
    let type: String
    let data: RulesRaceGameData
}

/*
struct GameDataReceived {
    let type: String
    let data: Data
}
*/

extension RulesRacePlayer {
    var gamePlayerID: String { id }
    var displayName: String { name }
} 