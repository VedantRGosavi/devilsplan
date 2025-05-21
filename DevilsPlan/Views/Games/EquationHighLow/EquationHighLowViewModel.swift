import SwiftUI
import Combine
import Foundation

// Game-specific player type
struct EquationPlayer: GamePlayer {
    let id: String
    var name: String
    var currentGuess: Int?
    var roundsWon: Int
    var score: Int { roundsWon * 100 }
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
        self.roundsWon = 0
    }
}

class EquationHighLowViewModel: ObservableObject {
    @Published var availableCards: [EquationCard] = []
    @Published var selectedCards: [EquationCard] = []
    @Published var currentPlayerChips = 100 // Starting chips
    @Published var bidAmount = 1
    @Published var canBid = false
    @Published var gameState: EquationGameState = .waitingForPlayers
    @Published var players: [EquationPlayer] = []
    @Published var currentPlayerIndex = 0
    @Published var roundWinner: EquationPlayer?
    @Published var winner: EquationPlayer?
    @Published var isMultiplayerGame: Bool = false
    
    var currentEquationResult: Double? {
        calculateEquationResult()
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let gameService: EquationHighLowGameService
    
    init(gameService: EquationHighLowGameService = EquationHighLowGameService()) {
        self.gameService = gameService
        setupGame()
        observeGameState()
    }
    
    private func setupGame() {
        // Generate number cards (1-9)
        let numberCards = (1...9).map { EquationCard(type: .number, value: Double($0), display: "\($0)") }
        
        // Generate operator cards (+, -, *, /)
        let operatorCards = [
            EquationCard(type: .operation, value: 0, display: "+", operation: .add),
            EquationCard(type: .operation, value: 0, display: "-", operation: .subtract),
            EquationCard(type: .operation, value: 0, display: "×", operation: .multiply),
            EquationCard(type: .operation, value: 0, display: "÷", operation: .divide)
        ]
        
        availableCards = (numberCards + operatorCards).shuffled()
    }
    
    private func observeGameState() {
        gameService.gameStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleGameState(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleGameState(_ state: EquationGameState) {
        gameState = state
        switch state {
        case .waitingForPlayers:
            break
        case .playing:
            canBid = true
        case .roundEnded:
            canBid = false
            determineRoundWinner()
        case .gameEnded:
            handleGameEnd()
        }
    }
    
    func selectCard(_ card: EquationCard) {
        guard isValidCardSelection(card) else { return }
        
        if let index = availableCards.firstIndex(where: { $0.id == card.id }) {
            availableCards.remove(at: index)
            selectedCards.append(card)
            
            // Check if equation is complete
            if isValidEquation() {
                canBid = true
            }
        }
    }
    
    func removeCard(_ card: EquationCard) {
        if let index = selectedCards.firstIndex(where: { $0.id == card.id }) {
            selectedCards.remove(at: index)
            availableCards.append(card)
            canBid = false
        }
    }
    
    private func isValidCardSelection(_ card: EquationCard) -> Bool {
        // Check if the card selection follows valid equation pattern
        let currentCount = selectedCards.count
        
        if currentCount == 0 {
            return card.type == .number
        }
        
        let lastCard = selectedCards.last!
        if lastCard.type == .number {
            return card.type == .operation
        } else {
            return card.type == .number
        }
    }
    
    private func isValidEquation() -> Bool {
        // Check if we have a valid equation (number-operation-number pattern)
        guard selectedCards.count >= 3 else { return false }
        
        let isValidPattern = selectedCards.enumerated().allSatisfy { index, card in
            if index % 2 == 0 {
                return card.type == .number
            } else {
                return card.type == .operation
            }
        }
        
        return isValidPattern && selectedCards.count % 2 == 1
    }
    
    private func calculateEquationResult() -> Double? {
        guard isValidEquation() else { return nil }
        
        var result = selectedCards[0].value
        
        for i in stride(from: 1, to: selectedCards.count - 1, by: 2) {
            let operation = selectedCards[i].operation!
            let nextNumber = selectedCards[i + 1].value
            
            switch operation {
            case .add:
                result += nextNumber
            case .subtract:
                result -= nextNumber
            case .multiply:
                result *= nextNumber
            case .divide:
                guard nextNumber != 0 else { return nil }
                result /= nextNumber
            }
        }
        
        return result
    }
    
    func placeBid(isHigh: Bool) {
        guard let result = currentEquationResult else { return }
        
        let bid = Bid(
            playerId: gameService.currentPlayerId,
            amount: bidAmount,
            targetHigh: isHigh,
            equationResult: result
        )
        
        gameService.submitBid(bid)
    }
    
    private func determineRoundWinner() {
        gameService.determineRoundWinner()
    }
    
    private func handleGameEnd() {
        // Handle game end state, show final results
    }
}

// MARK: - Game Models
enum EquationGameState {
    case waitingForPlayers
    case playing
    case roundEnded
    case gameEnded
    
    var toGameState: GameState {
        switch self {
        case .waitingForPlayers:
            return .notStarted
        case .playing:
            return .playing
        case .roundEnded:
            return .roundEnded
        case .gameEnded:
            return .gameComplete
        }
    }
}

struct Bid {
    let playerId: String
    let amount: Int
    let targetHigh: Bool
    let equationResult: Double
}

enum CardType: Codable {
    case number
    case operation // Renamed from 'operator'
}

enum Operation: Codable {
    case add
    case subtract
    case multiply
    case divide
}

struct EquationCard: Identifiable, Codable {
    let id = UUID()
    let type: CardType
    let value: Double
    let display: String
    var operation: Operation?
} 