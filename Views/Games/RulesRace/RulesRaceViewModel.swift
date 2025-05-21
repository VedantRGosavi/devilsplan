import SwiftUI
import Combine
import GameKit

enum DiceResult: String, CaseIterable {
    case one1 = "1"
    case one2 = "1"
    case two = "2"
    case three = "3"
    case prison = "Prison"
    case escapePrison = "Escape Prison"
}

class RulesRaceViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var lastDiceRoll: String?
    @Published var isRolling: Bool = false
    @Published var gameState: GameState = .notStarted
    @Published var winner: Player?
    @Published var isMultiplayerGame: Bool = false
    
    private let multiplayerManager = RulesRaceMultiplayerManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    var currentPlayerName: String {
        guard !players.isEmpty else { return "No players" }
        return players[currentPlayerIndex].name
    }
    
    var isLocalPlayerTurn: Bool {
        guard isMultiplayerGame else { return true }
        return currentPlayerIndex == localPlayerIndex
    }
    
    private var localPlayerIndex: Int {
        players.firstIndex { $0.id == multiplayerManager.localPlayer.gamePlayerID } ?? 0
    }
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .gameDataReceived)
            .sink { [weak self] notification in
                guard let gameData = notification.object as? GameData else { return }
                self?.handleReceivedGameData(gameData)
            }
            .store(in: &cancellables)
    }
    
    func setupGame(isMultiplayer: Bool = false) {
        isMultiplayerGame = isMultiplayer
        
        if isMultiplayer {
            // Set up multiplayer game with connected players
            let connectedPlayers = multiplayerManager.connectedPlayers
            players = connectedPlayers.enumerated().map { index, player in
                Player(id: player.gamePlayerID,
                      name: player.displayName,
                      position: 0,
                      escapeTickets: 0)
            }
            // Add local player
            players.append(Player(id: multiplayerManager.localPlayer.gamePlayerID,
                                name: multiplayerManager.localPlayer.displayName,
                                position: 0,
                                escapeTickets: 0))
        } else {
            // Set up local game with dummy players
            players = [
                Player(id: UUID().uuidString, name: "Player 1", position: 0, escapeTickets: 0),
                Player(id: UUID().uuidString, name: "Player 2", position: 0, escapeTickets: 0),
                Player(id: UUID().uuidString, name: "Player 3", position: 0, escapeTickets: 0),
                Player(id: UUID().uuidString, name: "Player 4", position: 0, escapeTickets: 0)
            ]
        }
        
        currentPlayerIndex = 0
        gameState = .playing
        
        // Sync initial game state in multiplayer
        if isMultiplayer {
            syncGameState()
        }
    }
    
    func rollDice() {
        guard gameState == .playing && isLocalPlayerTurn else { return }
        
        isRolling = true
        
        // Simulate dice rolling animation
        var rollCount = 0
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Show random faces during animation
                self.lastDiceRoll = DiceResult.allCases.randomElement()?.rawValue
                
                rollCount += 1
                if rollCount >= 10 {
                    // Final result
                    let finalResult = DiceResult.allCases.randomElement()!
                    self.lastDiceRoll = finalResult.rawValue
                    self.handleDiceResult(finalResult)
                    self.isRolling = false
                    
                    // Sync dice roll in multiplayer
                    if self.isMultiplayerGame {
                        self.syncDiceRoll(finalResult)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleDiceResult(_ result: DiceResult) {
        var currentPlayer = players[currentPlayerIndex]
        
        switch result {
        case .one1, .one2:
            currentPlayer.position += 1
        case .two:
            currentPlayer.position += 2
        case .three:
            currentPlayer.position += 3
        case .prison:
            currentPlayer.isInPrison = true
        case .escapePrison:
            currentPlayer.escapeTickets += 1
        }
        
        // Update player in array
        players[currentPlayerIndex] = currentPlayer
        
        // Check for win condition
        if currentPlayer.position >= 30 {
            gameState = .finished
            winner = currentPlayer
            return
        }
        
        // Move to next player
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        
        // Skip imprisoned players
        while players[currentPlayerIndex].isInPrison && players[currentPlayerIndex].escapeTickets == 0 {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        }
        
        // Sync game state in multiplayer
        if isMultiplayerGame {
            syncGameState()
        }
    }
    
    // MARK: - Multiplayer Sync Methods
    
    private func syncDiceRoll(_ result: DiceResult) {
        let gameData = GameData(type: .diceRoll,
                              playerIndex: currentPlayerIndex,
                              diceResult: result.rawValue,
                              position: nil,
                              isInPrison: nil,
                              escapeTickets: nil,
                              personalRules: nil)
        multiplayerManager.sendGameData(gameData)
    }
    
    private func syncGameState() {
        let currentPlayer = players[currentPlayerIndex]
        let gameData = GameData(type: .gameState,
                              playerIndex: currentPlayerIndex,
                              diceResult: nil,
                              position: currentPlayer.position,
                              isInPrison: currentPlayer.isInPrison,
                              escapeTickets: currentPlayer.escapeTickets,
                              personalRules: currentPlayer.personalRules)
        multiplayerManager.sendGameData(gameData)
    }
    
    private func handleReceivedGameData(_ gameData: GameData) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch gameData.type {
            case .diceRoll:
                if let diceResult = gameData.diceResult,
                   let result = DiceResult(rawValue: diceResult) {
                    self.handleDiceResult(result)
                }
                
            case .gameState:
                if let position = gameData.position,
                   let isInPrison = gameData.isInPrison,
                   let escapeTickets = gameData.escapeTickets {
                    var player = self.players[gameData.playerIndex]
                    player.position = position
                    player.isInPrison = isInPrison
                    player.escapeTickets = escapeTickets
                    if let rules = gameData.personalRules {
                        player.personalRules = rules
                    }
                    self.players[gameData.playerIndex] = player
                }
                
            case .customRule:
                if let rules = gameData.personalRules {
                    var player = self.players[gameData.playerIndex]
                    player.personalRules = rules
                    self.players[gameData.playerIndex] = player
                }
                
            case .playerMove:
                // Handle any additional player move synchronization
                break
            }
        }
    }
}

// Game state enum
enum GameState {
    case notStarted
    case playing
    case finished
}

// Player model
struct Player: Identifiable {
    let id: String
    let name: String
    var position: Int
    var escapeTickets: Int
    var isInPrison: Bool = false
    var personalRules: [String] = []
} 