import Foundation
import Combine

class EquationHighLowEngine: ObservableObject, GameProtocol {
    @Published private(set) var availableCards: [EquationCard] = []
    @Published private(set) var selectedCards: [EquationCard] = []
    @Published private(set) var currentPlayerChips = 100 // Starting chips
    @Published private(set) var bidAmount = 1
    @Published var gameState: GameState = .notStarted
    @Published private(set) var players: [Player] = []
    @Published private(set) var currentPlayerIndex = 0
    @Published private(set) var roundWinner: Player?
    @Published private(set) var score = 0
    @Published private(set) var currentLevel = 1
    
    var isMultiplayer: Bool { true }
    
    private let multiplayerService: MultiplayerGameService
    private var cancellables = Set<AnyCancellable>()
    
    init(multiplayerService: MultiplayerGameService = MultiplayerGameService(serviceType: "equation-high-low")) {
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
        availableCards = generateCards()
        selectedCards = []
        currentPlayerChips = 100
        bidAmount = 1
        players = []
        currentPlayerIndex = 0
        roundWinner = nil
        score = 0
        currentLevel = 1
        gameState = .notStarted
    }
    
    func endGame() {
        gameState = .gameComplete
        multiplayerService.disconnect()
    }
    
    func updateGameProgress(userId: String) async throws {
        try await GameProgressService.shared.updateGameProgress(
            userId: userId,
            gameId: "equation_high_low",
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
        availableCards = generateCards()
        players = [Player(id: multiplayerService.currentPlayerId, name: "Host", chips: 100)]
        
        let gameData = EquationGameData(
            availableCards: availableCards,
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
                let gameData = try JSONDecoder().decode(EquationGameData.self, from: data.data)
                availableCards = gameData.availableCards
                players = gameData.players
                currentPlayerIndex = gameData.currentPlayerIndex
            case "move":
                let moveData = try JSONDecoder().decode(EquationMove.self, from: data.data)
                handleMove(moveData)
            default:
                break
            }
        } catch {
            print("Error handling game data: \(error)")
        }
    }
    
    func selectCard(_ card: EquationCard) {
        guard currentPlayerIndex < players.count,
              players[currentPlayerIndex].id == multiplayerService.currentPlayerId,
              !selectedCards.contains(where: { $0.id == card.id }) else { return }
        
        selectedCards.append(card)
        availableCards.removeAll { $0.id == card.id }
        
        let move = EquationMove(
            playerId: multiplayerService.currentPlayerId,
            cardId: card.id,
            type: .selectCard
        )
        
        multiplayerService.sendGameData(move, type: "move")
    }
    
    func placeBid() {
        guard currentPlayerIndex < players.count,
              players[currentPlayerIndex].id == multiplayerService.currentPlayerId,
              currentPlayerChips >= bidAmount else { return }
        
        currentPlayerChips -= bidAmount
        
        let move = EquationMove(
            playerId: multiplayerService.currentPlayerId,
            bidAmount: bidAmount,
            type: .placeBid
        )
        
        multiplayerService.sendGameData(move, type: "move")
        handleMove(move)
    }
    
    private func handleMove(_ move: EquationMove) {
        switch move.type {
        case .selectCard:
            guard let cardId = move.cardId,
                  let card = availableCards.first(where: { $0.id == cardId }) else { return }
            selectedCards.append(card)
            availableCards.removeAll { $0.id == cardId }
            
        case .placeBid:
            guard let bidAmount = move.bidAmount else { return }
            if let playerIndex = players.firstIndex(where: { $0.id == move.playerId }) {
                players[playerIndex].chips -= bidAmount
                evaluateRound()
            }
        }
        
        // Next player's turn
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }
    
    private func evaluateRound() {
        guard let result = calculateEquationResult() else { return }
        
        // Find the player with the highest bid who got closest to the target number
        var bestDifference = Double.infinity
        var winningPlayer: Player?
        
        for player in players {
            let difference = abs(result - Double(player.targetNumber))
            if difference < bestDifference {
                bestDifference = difference
                winningPlayer = player
            }
        }
        
        if let winner = winningPlayer {
            roundWinner = winner
            if let index = players.firstIndex(where: { $0.id == winner.id }) {
                players[index].chips += bidAmount * 2
                if winner.id == multiplayerService.currentPlayerId {
                    score += bidAmount * 2
                }
            }
        }
        
        // Check for game over
        if players.contains(where: { $0.chips <= 0 }) {
            gameState = .gameComplete
        } else {
            startNewRound()
        }
    }
    
    private func startNewRound() {
        selectedCards = []
        availableCards = generateCards()
        roundWinner = nil
        currentLevel += 1
        
        let gameData = EquationGameData(
            availableCards: availableCards,
            players: players,
            currentPlayerIndex: currentPlayerIndex
        )
        multiplayerService.sendGameData(gameData, type: "gameState")
    }
    
    private func calculateEquationResult() -> Double? {
        guard selectedCards.count >= 3 else { return nil }
        
        let numbers = selectedCards.compactMap { Double($0.value) }
        let operators = selectedCards.compactMap { $0.operation }
        
        guard numbers.count >= 2, operators.count >= 1 else { return nil }
        
        var result = numbers[0]
        var numberIndex = 1
        var operatorIndex = 0
        
        while numberIndex < numbers.count && operatorIndex < operators.count {
            switch operators[operatorIndex] {
            case .add:
                result += numbers[numberIndex]
            case .subtract:
                result -= numbers[numberIndex]
            case .multiply:
                result *= numbers[numberIndex]
            case .divide:
                guard numbers[numberIndex] != 0 else { return nil }
                result /= numbers[numberIndex]
            }
            
            numberIndex += 1
            operatorIndex += 1
        }
        
        return result
    }
    
    private func generateCards() -> [EquationCard] {
        var cards: [EquationCard] = []
        
        // Generate number cards (1-10)
        for i in 1...10 {
            cards.append(EquationCard(id: UUID().uuidString, value: String(i), type: .number))
        }
        
        // Generate operator cards
        let operators: [Operation] = [.add, .subtract, .multiply, .divide]
        for op in operators {
            cards.append(EquationCard(id: UUID().uuidString, value: op.rawValue, type: .operation, operation: op))
        }
        
        return cards.shuffled()
    }
}

struct Player: Codable, Identifiable {
    let id: String
    let name: String
    var chips: Int
    var targetNumber: Int = Int.random(in: 1...100)
}

struct EquationGameData: Codable {
    let availableCards: [EquationCard]
    let players: [Player]
    let currentPlayerIndex: Int
}

struct EquationMove: Codable {
    let playerId: String
    var cardId: String?
    var bidAmount: Int?
    let type: MoveType
}

enum MoveType: String, Codable {
    case selectCard
    case placeBid
} 