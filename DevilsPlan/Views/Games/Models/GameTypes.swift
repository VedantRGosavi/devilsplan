import Foundation

// Make GameState accessible throughout the app
public enum GameState: String, Codable {
    case notStarted
    case playing
    case paused
    case roundEnded
    case levelComplete
    case gameComplete
}

// Base protocol for player types
public protocol GamePlayer: Identifiable {
    var id: String { get }
    var name: String { get }
    var score: Int { get }
}

public struct GameProgress: Codable {
    let currentLevel: Int
    let score: Int
    let status: String
    
    init(currentLevel: Int, score: Int, status: String) {
        self.currentLevel = currentLevel
        self.score = score
        self.status = status
    }
} 