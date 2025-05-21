import Foundation
import Combine

class RulesRaceEngine: ObservableObject, GameProtocol {
    @Published private(set) var players: [RulesRacePlayer] = []
    @Published private(set) var currentPlayerIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var currentLevel = 1
    @Published var gameState: GameState = .notStarted
    @Published private(set) var diceResult = 0
    @Published private(set) var rules: [GameRule] = []
    
    var isMultiplayer: Bool { true }
    
    private let multiplayerService: MultiplayerGameService
    private var cancellables = Set<AnyCancellable>()
    
    init(multiplayerService: MultiplayerGameService = MultiplayerGameService(serviceType: "rules-race")) {
        self.multiplayerService = multiplayerService
        setupMultiplayer()
    }
    
    // MARK: - GameProtocol Implementation
    func startGame() {
        resetGame()
        gameState = .playing
        if multiplayerService.isHost {
            setupInitialGameState()
        }
    }
    
    func resetGame() {
        players = []
        currentPlayerIndex = 0
        score = 0
        currentLevel = 1
        diceResult = 0
        rules = []
        gameState = .notStarted
    }
    
    func endGame() {
        gameState = .gameComplete
        multiplayerService.disconnect()
    }
    
    func updateGameProgress(userId: String) async throws {
        try await GameProgressService.shared.updateGameProgress(
            userId: userId,
            gameId: "rules_race",
            status: gameState == .gameComplete ? "completed" : "in_progress",
            currentLevel: currentLevel,
            score: score,
            completedAt: gameState == .gameComplete ? Date() : nil
        )
    }
    
    // MARK: - Game Logic
    private func setupMultiplayer() {
        multiplayerService.gameStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleGameState(state)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .gameDataReceived)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let data = notification.object as? GameDataReceived else { return }
                self?.handleGameData(data)
            }
            .store(in: &cancellables)
    }
    
    private func setupInitialGameState() {
        // Create initial game state
        rules = createDefaultRules()
        players = [RulesRacePlayer(id: multiplayerService.currentPlayerId, name: "Host", position: 0)]
        
        // Send initial state to other players
        let gameData = RulesRaceGameData(
            rules: rules,
            players: players,
            currentPlayerIndex: currentPlayerIndex
        )
        multiplayerService.sendGameData(gameData, type: "gameState")
    }
    
    private func handleGameState(_ state: GameState) {
        gameState = state
    }
    
    private func handleGameData(_ data: GameDataReceived) {
        do {
            switch data.type {
            case "gameState":
                let gameData = try JSONDecoder().decode(RulesRaceGameData.self, from: data.data)
                rules = gameData.rules
                players = gameData.players
                currentPlayerIndex = gameData.currentPlayerIndex
            case "move":
                let moveData = try JSONDecoder().decode(RulesRaceMove.self, from: data.data)
                handleMove(moveData)
            default:
                break
            }
        } catch {
            print("Error handling game data: \(error)")
        }
    }
    
    func rollDice() {
        guard currentPlayerIndex < players.count,
              players[currentPlayerIndex].id == multiplayerService.currentPlayerId else { return }
        
        let result = Int.random(in: 1...6)
        diceResult = result
        
        let move = RulesRaceMove(
            playerId: multiplayerService.currentPlayerId,
            diceResult: result
        )
        
        multiplayerService.sendGameData(move, type: "move")
        handleMove(move)
    }
    
    private func handleMove(_ move: RulesRaceMove) {
        guard let playerIndex = players.firstIndex(where: { $0.id == move.playerId }) else { return }
        
        // Update player position
        var player = players[playerIndex]
        player.position += move.diceResult
        
        // Apply rules
        for rule in rules {
            if player.position == rule.position {
                player.position = rule.newPosition
                break
            }
        }
        
        // Update player
        players[playerIndex] = player
        
        // Check for win condition
        if player.position >= 100 {
            gameState = .gameComplete
            score = calculateScore(for: player)
        }
        
        // Next player's turn
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }
    
    private func calculateScore(for player: RulesRacePlayer) -> Int {
        // Score based on position and remaining players
        let positionScore = max(0, 100 - player.position) * 10
        let playerScore = (players.count - currentPlayerIndex) * 100
        return positionScore + playerScore
    }
    
    private func createDefaultRules() -> [GameRule] {
        [
            GameRule(position: 16, newPosition: 6),
            GameRule(position: 47, newPosition: 26),
            GameRule(position: 49, newPosition: 11),
            GameRule(position: 56, newPosition: 53),
            GameRule(position: 62, newPosition: 19),
            GameRule(position: 64, newPosition: 60),
            GameRule(position: 87, newPosition: 24),
            GameRule(position: 93, newPosition: 73),
            GameRule(position: 95, newPosition: 75),
            GameRule(position: 98, newPosition: 78)
        ]
    }
}

struct RulesRacePlayer: Codable, Identifiable {
    let id: String
    let name: String
    var position: Int
}

struct GameRule: Codable {
    let position: Int
    let newPosition: Int
}

struct RulesRaceGameData: Codable {
    let rules: [GameRule]
    let players: [RulesRacePlayer]
    let currentPlayerIndex: Int
}

struct RulesRaceMove: Codable {
    let playerId: String
    let diceResult: Int
} 