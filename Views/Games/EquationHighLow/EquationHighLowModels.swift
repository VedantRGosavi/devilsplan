import Foundation

// MARK: - Game State

enum GameState: String, Codable { // Ensure Codable for network transmission
    case notStarted
    case waitingForPlayers
    case playing
    case roundEnded // If applicable for specific game logic
    case gameComplete
    case error // For handling errors
}

// MARK: - Player Definition

struct Player: Codable, Identifiable {
    let id: String 
    var name: String
    var chips: Int
    var targetNumber: Int = Int.random(in: 1...100) 
    var score: Int? = 0 
}

// MARK: - Card Definitions

struct EquationCard: Codable, Identifiable, Hashable { // Added Hashable for .Set operations if needed
    let id: String
    let value: String
    let type: CardType
    var operation: Operation?
}

enum CardType: String, Codable {
    case number
    case operation
}

enum Operation: String, Codable {
    case add = "+"
    case subtract = "-"
    case multiply = "×"
    case divide = "÷"
}

// MARK: - Network Data Structures

struct EquationGameData: Codable {
    let availableCards: [EquationCard]
    let players: [Player]
    let currentPlayerIndex: Int
    var selectedCards: [EquationCard]? 
    var currentLevel: Int?
    var gameState: GameState? // Transmit current game state
    var roundWinner: Player? // Transmit round winner
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
    case deselectLast // New move type for undoing last card selection
}

// MARK: - Error Types

enum EquationError: Error {
    case divisionByZero
    case malformedEquation
    // case unknownOperator // Not strictly needed if operators are from a fixed enum
}

extension EquationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .divisionByZero:
            return NSLocalizedString("Error: Division by zero.", comment: "Division by zero error")
        case .malformedEquation:
            return NSLocalizedString("Error: Incomplete or invalid equation.", comment: "Malformed equation error")
        }
    }
}


// MARK: - Utility Extensions

// MARK: - Service Constants
let EquationHighLowServiceType = "eqn-high-low"

// Helper for safe array access
extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
