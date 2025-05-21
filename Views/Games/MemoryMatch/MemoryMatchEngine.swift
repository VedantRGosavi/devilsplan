import Foundation

class MemoryMatchEngine: ObservableObject, GameProtocol {
    @Published private(set) var cards: [MemoryCard]
    @Published private(set) var score = 0
    @Published private(set) var moves = 0
    @Published private(set) var currentLevel = 1
    @Published private(set) var matchesFound = 0
    @Published var gameState: GameState = .notStarted
    
    var isMultiplayer: Bool { false }
    
    private var firstFlippedCardIndex: Int?
    private let maxLevel = 10
    private let baseScore = 100
    private let timePenalty = 10
    private let movesPenalty = 5
    private var levelStartTime: Date?
    
    enum GameState {
        case playing
        case levelComplete
        case gameComplete
        case notStarted
    }
    
    init(level: Int = 1) {
        self.currentLevel = level
        self.cards = []
        startGame()
    }
    
    // MARK: - GameProtocol Implementation
    func startGame() {
        resetGame()
        gameState = .playing
        startLevel()
    }
    
    func resetGame() {
        currentLevel = 1
        score = 0
        moves = 0
        gameState = .notStarted
        startLevel()
    }
    
    func endGame() {
        gameState = .gameComplete
    }
    
    func updateGameProgress(userId: String) async throws {
        try await GameProgressService.shared.updateGameProgress(
            userId: userId,
            gameId: "memory_match",
            status: gameState == .gameComplete ? "completed" : "in_progress",
            currentLevel: currentLevel,
            score: score,
            completedAt: gameState == .gameComplete ? Date() : nil
        )
    }
    
    // MARK: - Game Logic
    private func createCards(pairs: Int) -> [MemoryCard] {
        let emojis = ["🎮", "🎲", "🎯", "🎪", "🎨", "🎭", "🎪", "🎫", "🎬", "🎤",
                     "🎧", "🎼", "🎹", "🎸", "🎺", "🎻", "🎭", "🎪", "🎨", "🎯"]
        
        let selectedEmojis = Array(emojis.prefix(pairs))
        let cardPairs = selectedEmojis.flatMap { emoji in
            [
                MemoryCard(id: Int.random(in: 0...10000), content: emoji),
                MemoryCard(id: Int.random(in: 0...10000), content: emoji)
            ]
        }
        return cardPairs.shuffled()
    }
    
    func startLevel() {
        let pairs = min(4 + currentLevel, 10) // Increases pairs with level, max 10 pairs
        cards = createCards(pairs: pairs)
        matchesFound = 0
        levelStartTime = Date()
        gameState = .playing
    }
    
    func cardTapped(_ card: MemoryCard) {
        guard let index = cards.firstIndex(of: card),
              !cards[index].isFaceUp,
              !cards[index].isMatched,
              gameState == .playing else { return }
        
        // Flip the card
        cards[index].isFaceUp = true
        moves += 1
        
        // Check if this is the first or second card
        if let firstIndex = firstFlippedCardIndex {
            // Second card
            checkForMatch(firstIndex: firstIndex, secondIndex: index)
            firstFlippedCardIndex = nil
        } else {
            // First card
            firstFlippedCardIndex = index
        }
    }
    
    private func checkForMatch(firstIndex: Int, secondIndex: Int) {
        let card1 = cards[firstIndex]
        let card2 = cards[secondIndex]
        
        if card1.content == card2.content {
            // Match found
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            matchesFound += 1
            updateScore(matched: true)
            
            // Check if level is complete
            if matchesFound == cards.count / 2 {
                handleLevelComplete()
            }
        } else {
            // No match
            updateScore(matched: false)
            // Flip cards back after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.cards[firstIndex].isFaceUp = false
                self.cards[secondIndex].isFaceUp = false
            }
        }
    }
    
    private func updateScore(matched: Bool) {
        if matched {
            // Calculate time bonus
            let timeElapsed = Date().timeIntervalSince(levelStartTime ?? Date())
            let timeBonus = max(0, baseScore - Int(timeElapsed) * timePenalty)
            
            // Calculate moves bonus
            let expectedMoves = cards.count
            let movesBonus = max(0, baseScore - (moves - expectedMoves) * movesPenalty)
            
            // Add score
            score += timeBonus + movesBonus + (baseScore * currentLevel)
        } else {
            // Penalty for wrong match
            score = max(0, score - movesPenalty)
        }
    }
    
    private func handleLevelComplete() {
        if currentLevel < maxLevel {
            gameState = .levelComplete
        } else {
            gameState = .gameComplete
        }
    }
    
    func nextLevel() {
        guard currentLevel < maxLevel else { return }
        currentLevel += 1
        moves = 0
        startLevel()
    }
} 