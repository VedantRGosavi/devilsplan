import Foundation
import Combine

// Models (GameState, Player, EquationCard, CardType, Operation, EquationGameData, EquationMove) 
// and Collection extension are now defined in EquationHighLowModels.swift

class EquationHighLowEngine: ObservableObject, GameProtocol {
    @Published private(set) var availableCards: [EquationCard] = []
    @Published private(set) var selectedCards: [EquationCard] = []
    // currentPlayerChips now reflects the chips of the local player from the `players` list
    @Published var currentPlayerChips: Int = 100
    @Published var bidAmount: Int = 1 // Default bid amount, can be changed by UI
    @Published var gameState: GameState = .notStarted
    @Published private(set) var players: [Player] = []
    @Published private(set) var currentPlayerIndex: Int = 0 // Host controls this
    @Published private(set) var roundWinner: Player?
    @Published var score: Int = 0 // Local player's score
    @Published private(set) var currentLevel: Int = 1
    @Published private(set) var displayedEquationValue: Double? = nil // For UI display of current selection's value
    
    var isMultiplayer: Bool { true } // This class is designed for multiplayer
    var isHost: Bool = false // Is this instance the host?
    
    private let gameNetworkingService: GameNetworkingService // Using the protocol
    private let gameId: String // To store the game ID
    private var cancellables = Set<AnyCancellable>() // Keep for any Combine subscriptions if needed
    
    // Store bids from players for the current round for the host to evaluate
    @Published private(set) var playerBids: [String: Int] = [:] // [PlayerID: BidAmount]
    
    init(gameNetworkingService: GameNetworkingService, gameId: String) {
        self.gameNetworkingService = gameNetworkingService
        self.gameId = gameId
        // The service should have its engine reference set externally after engine init,
        // or via a method if a two-way dependency during init is complex.
        // For simplicity, assuming service can be given a reference.
        // (The service's setEngineReference was added in its refactoring)
    }
    
    // MARK: - Game Lifecycle & Hosting
    func hostGame() {
        isHost = true
        resetGameInternals() // Reset state before hosting
        // Add host player. Name can be customized.
        let hostPlayer = Player(id: gameNetworkingService.localPlayerId, name: "Player 1 (Host)", chips: 100, score: 0)
        players.append(hostPlayer)
        currentPlayerChips = hostPlayer.chips // Update local display of chips
        score = hostPlayer.score ?? 0 // Update local display of score
        gameState = .waitingForPlayers
        gameNetworkingService.startAdvertising()
        setupInitialGameStateForHost() // Prepare cards, doesn't broadcast yet
        broadcastFullGameState()     // Broadcast initial state
        AppLogger.info("Engine \(gameNetworkingService.localPlayerId) is hosting. State: \(gameState). Players: \(players.count)")
    }

    func joinGame() {
        isHost = false
        resetGameInternals() // Reset state before joining
        gameState = .waitingForPlayers
        gameNetworkingService.startBrowsing()
        AppLogger.info("Engine \(gameNetworkingService.localPlayerId) is joining. State: \(gameState)")
    }

    // MARK: - GameProtocol Implementation
    func startGame() { // Called by UI, typically by the host to move from waiting to playing
        guard isHost else {
            AppLogger.warning("Client \(gameNetworkingService.localPlayerId) attempted to start game, but only host can.")
            return
        }
        
        if gameState == .waitingForPlayers && !players.isEmpty {
            AppLogger.info("Host \(gameNetworkingService.localPlayerId) is starting the game. Current players: \(players.count)")
            gameState = .playing
            currentLevel = 1
            // score and currentPlayerChips for host already set in hostGame()
            
            // Resetting parts of the game state for the actual start
            availableCards = generateCards()
            selectedCards = []
            currentPlayerIndex = 0 // Host starts
            roundWinner = nil
            playerBids.removeAll()
            
            // Ensure all players in the list are reset for the game start (e.g. target numbers)
            for i in 0..<players.count {
                players[i].targetNumber = Int.random(in: 1...100) // Assign initial random target
                players[i].score = 0 // Reset scores for all players at game start
            }
            if let hostPlayer = players.first(where: {$0.id == gameNetworkingService.localPlayerId}) {
                 self.score = hostPlayer.score ?? 0 // Update host's score display
            }

            broadcastFullGameState()
        } else {
            AppLogger.warning("Host \(gameNetworkingService.localPlayerId) cannot start game. Not in waiting state or no players. Current state: \(gameState)")
        }
    }
    
    private func resetGameInternals() {
        availableCards = generateCards()
        selectedCards = []
        currentPlayerChips = 100 // Reset for local UI, will be updated from player list
        bidAmount = 1
        players = []
        currentPlayerIndex = 0
        roundWinner = nil
        score = 0
        currentLevel = 1
        playerBids.removeAll()
        // gameState will be set by hostGame/joinGame or startGame
    }
    
    func resetGame() { // GameProtocol reset, typically called by host
        AppLogger.info("Engine: resetGame called by \(gameNetworkingService.localPlayerId). isHost: \(isHost)")
        guard isHost else { return }
        
        resetGameInternals()
        let hostPlayer = Player(id: gameNetworkingService.localPlayerId, name: "Player 1 (Host)", chips: 100, score: 0)
        players.append(hostPlayer)
        currentPlayerChips = hostPlayer.chips
        score = hostPlayer.score ?? 0
        
        gameState = .waitingForPlayers // Reset to waiting state for host to start again
        setupInitialGameStateForHost() 
        broadcastFullGameState()
    }
    
    func endGame() {
        AppLogger.info("Engine: endGame called by \(gameNetworkingService.localPlayerId). isHost: \(isHost). Current state: \(gameState)")
        gameState = .gameComplete
        if isHost { // Only host broadcasts the final state and tells service to disconnect.
            broadcastFullGameState() 
        }
        gameNetworkingService.disconnect() // All instances should disconnect from network.
    }
    
    func updateGameProgress(userId: String) async throws {
        let progressUserId = players.first(where: { $0.id == gameNetworkingService.localPlayerId })?.id ?? userId
        try await GameProgressService.shared.updateGameProgress(
            userId: progressUserId, gameId: self.gameId, // Use stored gameId
            status: gameState == .gameComplete ? "completed" : "in_progress",
            currentLevel: currentLevel, score: score, // This is local player's score
            completedAt: gameState == .gameComplete ? Date() : nil
        )
    }
    
    // MARK: - Networking Callbacks (called by GameNetworkingService)
    
    func handlePeerConnected(playerId: String) {
        AppLogger.info("Engine: handlePeerConnected from \(playerId). Current player: \(gameNetworkingService.localPlayerId), isHost: \(isHost)")
        guard isHost else { return }
        
        if !players.contains(where: { $0.id == playerId }) {
            let newPlayerName = "Player \(players.count + 1)"
            players.append(Player(id: playerId, name: newPlayerName, chips: 100, score: 0))
            AppLogger.info("Engine Host \(gameNetworkingService.localPlayerId) added player \(playerId). Total players: \(players.count)")
            broadcastFullGameState()
        }
    }

    func handlePeerDisconnected(playerId: String) {
        AppLogger.info("Engine: handlePeerDisconnected for \(playerId). Current player: \(gameNetworkingService.localPlayerId), isHost: \(isHost)")
        // Note: Host disconnection logic for clients will be handled in a subsequent, focused change.
        // This logging is for when the host processes a peer disconnect.
        guard isHost else { 
            // Client side: If the disconnected player is the host, this needs specific handling.
            // This will be addressed in host disconnection logic.
            // For now, just log if it's not the host that got disconnected.
            if playerId != self.hostPlayerId { // Assuming self.hostPlayerId is correctly set on client
                 AppLogger.info("Client \(gameNetworkingService.localPlayerId) noted peer \(playerId) disconnected.")
            }
            return 
        } 
        
        let originalPlayerCount = players.count
        players.removeAll { $0.id == playerId }
        if players.count < originalPlayerCount {
            AppLogger.info("Engine Host \(gameNetworkingService.localPlayerId) removed player \(playerId). Total players: \(players.count)")
        }
        
        if players.isEmpty && isHost {
            AppLogger.info("Engine Host \(gameNetworkingService.localPlayerId) is the only one left or no one left; resetting to notStarted.")
            gameState = .notStarted 
        } else if currentPlayerIndex >= players.count && !players.isEmpty {
            currentPlayerIndex = 0 
        }
        broadcastFullGameState()
    }
    
    func handlePeerLost(playerId: String) {
        AppLogger.info("Engine: handlePeerLost for \(playerId). Current player: \(gameNetworkingService.localPlayerId), isHost: \(isHost)")
        handlePeerDisconnected(playerId: playerId) // Treat lost peer same as disconnected
    }

    func handleReceivedData(payload: Data, type: String, fromPlayerId: String) {
        // print("Engine: Received data type '\(type)' from \(fromPlayerId). isHost: \(isHost)")
        do {
            let decoder = JSONDecoder()
            switch type {
            case "gameState":
                if !isHost { // Only non-host clients should process full gameState received from host
                    let gameData = try decoder.decode(EquationGameData.self, from: payload)
                    applyGameState(gameData)
                }
            case "move":
                let moveData = try decoder.decode(EquationMove.self, from: payload)
                if isHost { // Host processes moves from clients
                    processMove(moveData, fromPlayerId: fromPlayerId)
                } else { // Client received a move (e.g. echo from host, or direct from another client if not host-authoritative)
                    // If clients are allowed to see moves directly, they might apply them optimistically.
                    // For now, relying on host's broadcastFullGameState for authoritative state.
                    // However, applying selectCard optimistically can make UI feel more responsive.
                    if moveData.type == .selectCard, let cardId = moveData.cardId {
                        if let cardIndex = self.availableCards.firstIndex(where: { $0.id == cardId }) {
                            let card = self.availableCards.remove(at: cardIndex)
                            if !self.selectedCards.contains(where: { $0.id == card.id }) {
                                self.selectedCards.append(card)
                            }
                        }
                    }
                    AppLogger.debug("Client Engine \(gameNetworkingService.localPlayerId): Optimistically updated UI for selectCard from \(fromPlayerId).")
                }
            default:
                AppLogger.warning("Engine: Unknown data type received: \(type) from \(fromPlayerId).")
            }
        } catch {
            // Error already logged by AppLogger in the catch block.
        }
    }
    
    private func applyGameState(_ gameData: EquationGameData) {
        guard !isHost else { return } // Host should not apply game state from network

        self.availableCards = gameData.availableCards
        self.players = gameData.players
        self.currentPlayerIndex = gameData.currentPlayerIndex
        self.selectedCards = gameData.selectedCards ?? []
        self.currentLevel = gameData.currentLevel ?? 1
        self.gameState = gameData.gameState ?? .playing // Default to playing if nil, but should always be sent
        self.roundWinner = gameData.roundWinner
        
        if let myPlayerState = self.players.first(where: { $0.id == self.gameNetworkingService.localPlayerId }) {
            self.score = myPlayerState.score ?? 0
            self.currentPlayerChips = myPlayerState.chips
        } else {
            // If local player is not in the list, client might need to re-join or is eliminated.
            if self.gameState != .gameComplete && self.gameState != .notStarted && self.gameState != .waitingForPlayers {
                 AppLogger.warning("Client Engine: Local player \(self.gameNetworkingService.localPlayerId) not found in received player list from host. Current GameState: \(self.gameState)")
            } else {
                 self.currentPlayerChips = 0 
                 self.score = 0
            }
        }
        AppLogger.debug("Client Engine \(gameNetworkingService.localPlayerId): Applied game state from host. Current player: \(self.players[safe: self.currentPlayerIndex]?.id ?? "N/A")")
    }

    // MARK: - Game Actions & Logic
    private func setupInitialGameStateForHost() { // Called by host
        guard isHost else { return }
        availableCards = generateCards()
        selectedCards = []
        currentPlayerIndex = 0 
        roundWinner = nil
        playerBids.removeAll()
        // players list already initiated with host
    }

    func broadcastFullGameState() {
        guard isHost else { return }
        
        let gameData = EquationGameData(
            availableCards: availableCards, players: players, currentPlayerIndex: currentPlayerIndex,
            selectedCards: selectedCards, currentLevel: currentLevel, gameState: gameState, roundWinner: roundWinner
        )
        AppLogger.debug("Host Engine \(gameNetworkingService.localPlayerId): Broadcasting full game state. Current player: \(players[safe: currentPlayerIndex]?.id ?? "N/A")")
        gameNetworkingService.sendData(gameData, type: "gameState")
    }
    
    func selectCard(_ card: EquationCard) {
        guard let localPlayerId = players.first(where: { $0.id == gameNetworkingService.localPlayerId })?.id,
              players[safe: currentPlayerIndex]?.id == localPlayerId else {
            AppLogger.warning("Not player's turn (\(gameNetworkingService.localPlayerId)) to select a card. Current turn: \(players[safe: currentPlayerIndex]?.id ?? "N/A")")
            return
        }
        
        guard !selectedCards.contains(where: { $0.id == card.id }),
              availableCards.contains(where: {$0.id == card.id}) else {
            AppLogger.warning("Card \(card.id) already selected or not available. PlayerID: \(localPlayerId)")
            return
        }
        
        let move = EquationMove(playerId: localPlayerId, cardId: card.id, type: .selectCard)
        gameNetworkingService.sendData(move, type: "move")
        
        if isHost { // Host processes its own move immediately
            processMove(move, fromPlayerId: localPlayerId)
        } else { // Client optimistically updates UI
            if let cardIndex = self.availableCards.firstIndex(where: { $0.id == card.id }) {
                let selectedCard = self.availableCards.remove(at: cardIndex)
                if !self.selectedCards.contains(where: { $0.id == selectedCard.id }) {
                    self.selectedCards.append(selectedCard)
                }
            }
            // Update displayed equation value after optimistic client-side selection
            updateDisplayedEquationValue() 
        }
    }

    func deselectLastCard() {
        guard let localPlayerId = players.first(where: { $0.id == gameNetworkingService.localPlayerId })?.id,
              players[safe: currentPlayerIndex]?.id == localPlayerId else {
            AppLogger.warning("Not player's turn (\(gameNetworkingService.localPlayerId)) to deselect a card.")
            return
        }

        if selectedCards.isEmpty {
            AppLogger.info("No cards selected to deselect. PlayerID: \(localPlayerId)")
            return
        }

        // Create a "deselectLast" move
        let move = EquationMove(playerId: localPlayerId, type: .deselectLast)
        gameNetworkingService.sendData(move, type: "move")

        if isHost { // Host processes its own move immediately
            processMove(move, fromPlayerId: localPlayerId)
        } else { // Client optimistically updates UI
            if let lastCard = selectedCards.popLast() {
                availableCards.append(lastCard) // Add back to available cards
                // Sort available cards if necessary for consistent display (optional)
                // availableCards.sort(by: { ... }) 
            }
            updateDisplayedEquationValue()
        }
    }
    
    func placeBid() {
        guard let localPlayerId = players.first(where: { $0.id == gameNetworkingService.localPlayerId })?.id,
              let localPlayerArrayIndex = players.firstIndex(where: {$0.id == localPlayerId}), 
              players[safe: currentPlayerIndex]?.id == localPlayerId else {
            AppLogger.warning("Not player's turn (\(gameNetworkingService.localPlayerId)) to place a bid.")
            return
        }
        
        guard players[localPlayerArrayIndex].chips >= bidAmount else {
            AppLogger.warning("Player \(localPlayerId) does not have enough chips (\(players[localPlayerArrayIndex].chips)) to place bid (\(bidAmount)).")
            return
        }
        
        let move = EquationMove(playerId: localPlayerId, bidAmount: bidAmount, type: .placeBid)
        gameNetworkingService.sendData(move, type: "move")

        if isHost { // Host processes its own move immediately
            processMove(move, fromPlayerId: localPlayerId)
        } else { // Client optimistically updates UI
            if self.players[localPlayerArrayIndex].chips >= bidAmount {
                 self.players[localPlayerArrayIndex].chips -= bidAmount // Update local player object
                 self.currentPlayerChips = self.players[localPlayerArrayIndex].chips // Update published value
                 // Note: playerBids is not updated on client side, host manages this.
            }
        }
    }
    
    private func processMove(_ move: EquationMove, fromPlayerId: String) {
        guard isHost else { 
            AppLogger.warning("Client Engine (\(gameNetworkingService.localPlayerId)) received processMove call, but only host should process. Move: \(move.type) from \(fromPlayerId)")
            return
        }

        AppLogger.info("Host Engine (\(gameNetworkingService.localPlayerId)) processing move type \(move.type) from \(fromPlayerId)")
        var stateChanged = false
        switch move.type {
        case .selectCard:
            guard let cardId = move.cardId,
                  let cardFromAvailable = availableCards.first(where: { $0.id == cardId }) else { 
                AppLogger.warning("Host Engine: Card not found in available for selectCard: \(cardId ?? "nil"). PlayerID: \(fromPlayerId)")
                return 
            }

            // Card selection validation
            if selectedCards.isEmpty {
                guard cardFromAvailable.type == .number else {
                    AppLogger.warning("Host Engine: Invalid first card selection. Must be a number. Card: \(cardFromAvailable.value). PlayerID: \(fromPlayerId)")
                    return 
                }
            } else {
                let lastSelectedCard = selectedCards.last!
                if lastSelectedCard.type == .number {
                    guard cardFromAvailable.type == .operation else {
                        AppLogger.warning("Host Engine: Invalid card selection after number. Must be an operator. Card: \(cardFromAvailable.value). PlayerID: \(fromPlayerId)")
                        return 
                    }
                } else { // Last selected was an operator
                    guard cardFromAvailable.type == .number else {
                        AppLogger.warning("Host Engine: Invalid card selection after operator. Must be a number. Card: \(cardFromAvailable.value). PlayerID: \(fromPlayerId)")
                        return
                    }
                }
            }

            if !selectedCards.contains(where: { $0.id == cardId }) {
                selectedCards.append(cardFromAvailable)
                availableCards.removeAll { $0.id == cardId }
                stateChanged = true
                updateDisplayedEquationValue() 
            }
        case .deselectLast:
            if let lastCard = selectedCards.popLast() {
                availableCards.append(lastCard) 
                stateChanged = true
                updateDisplayedEquationValue() 
            } else {
                AppLogger.warning("Host Engine: Attempted to deselect from empty selectedCards. PlayerID: \(fromPlayerId)")
            }
        case .placeBid:
            guard let bidAmt = move.bidAmount,
                  let playerIdx = players.firstIndex(where: { $0.id == fromPlayerId }) else {
                AppLogger.warning("Host Engine: Invalid bid move from \(fromPlayerId). Missing bid amount or player not found.")
                return 
            }
            
            if players[playerIdx].chips >= bidAmt {
                players[playerIdx].chips -= bidAmt
                playerBids[fromPlayerId] = (playerBids[fromPlayerId] ?? 0) + bidAmt 
                stateChanged = true
                
                let activePlayers = players.filter { $0.chips > 0 || playerBids[$0.id] != nil } 
                if playerBids.count == activePlayers.count && !activePlayers.isEmpty {
                    evaluateRound() 
                    return 
                }
            } else {
                AppLogger.warning("Host Engine: Player \(fromPlayerId) insufficient chips (\(players[playerIdx].chips)) for bid (\(bidAmt)).")
                return 
            }
        }
        
        // If state changed from selectCard or a bid that didn't trigger evaluation yet:
        if stateChanged {
            // Advance turn only after a successful action for the current player
            // Check if the game is in a state where turn should advance (e.g. not all bids are in)
            if players.count > 0 { // Ensure players list is not empty
                 currentPlayerIndex = (currentPlayerIndex + 1) % players.count
            }
            broadcastFullGameState()
        }
    }
    
    private func evaluateRound() { 
        guard isHost else { return }
        AppLogger.info("Host Engine (\(gameNetworkingService.localPlayerId)): Evaluating round. Number of bids: \(playerBids.count)")
        guard let result = calculateEquationResult() else {
            AppLogger.error("Host Engine (\(gameNetworkingService.localPlayerId)): Could not calculate equation result for evaluation.")
            startNewRound() 
            broadcastFullGameState()
            return
        }
        
        var bestDifference = Double.infinity
        var winnerId: String?
        
        for (pId, _) in playerBids { 
            if let player = players.first(where: { $0.id == pId }) {
                let difference = abs(result - Double(player.targetNumber)) 
                if difference < bestDifference {
                    bestDifference = difference
                    winnerId = player.id
                } else if difference == bestDifference {
                    // TODO: Handle ties if necessary more robustly (e.g. split pot or random)
                    AppLogger.info("Tie detected in evaluateRound. Current winner: \(winnerId ?? "none"), Tie with: \(player.id)")
                }
            }
        }
        
        if let winId = winnerId, let winnerIdx = players.firstIndex(where: { $0.id == winId }) {
            roundWinner = players[winnerIdx]
            let pot = playerBids.values.reduce(0, +) 
            players[winnerIdx].chips += pot
            players[winnerIdx].score = (players[winnerIdx].score ?? 0) + pot
            if players[winnerIdx].id == gameNetworkingService.localPlayerId { 
                self.score = players[winnerIdx].score ?? 0 
                self.currentPlayerChips = players[winnerIdx].chips 
            }
            AppLogger.info("Host Engine (\(gameNetworkingService.localPlayerId)): Round winner is \(players[winnerIdx].name) with pot \(pot).")
        } else {
            roundWinner = nil 
            AppLogger.info("Host Engine (\(gameNetworkingService.localPlayerId)): No winner this round, or no bids placed.")
        }
        
        playerBids.removeAll() 
        
        let activePlayersWithChips = players.filter { $0.chips > 0 }
        if activePlayersWithChips.count <= 1 && players.count > 1 { 
            AppLogger.info("Host Engine (\(gameNetworkingService.localPlayerId)): Game complete due to chip count. Active players: \(activePlayersWithChips.count)")
            gameState = .gameComplete
        } else if currentLevel >= 10 { 
            AppLogger.info("Host Engine (\(gameNetworkingService.localPlayerId)): Game complete due to reaching max levels.")
            gameState = .gameComplete
        } else {
            startNewRound()
        }
        broadcastFullGameState() 
    }
    
    private func startNewRound() { 
        guard isHost else { return }
        AppLogger.info("Host Engine (\(gameNetworkingService.localPlayerId)): Starting new round. Current level: \(currentLevel + 1)")
        selectedCards = []
        availableCards = generateCards() 
        roundWinner = nil 
        currentLevel += 1
        playerBids.removeAll()
        
        for i in 0..<players.count { 
            players[i].targetNumber = Int.random(in: 1...100) 
        }
        
        if players.count > 0 { 
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count 
        } else {
            currentPlayerIndex = 0
        }
        gameState = .playing 
    }
    
    // This is the main calculation for round evaluation
    private func calculateEquationResult() -> Double? {
        return calculateEquationValue(from: self.selectedCards)
    }

    // Renamed from ViewModel's calculateEquationResult(from:)
    // This can be used for both display and final evaluation.
    private func calculateEquationValue(from cards: [EquationCard]) -> Double? {
        guard isValidEquation(cards: cards) else { return nil }

        guard let firstNumber = Double(cards[0].value) else { return nil }
        var currentResult = firstNumber
        
        var i = 1
        while i < cards.count {
            let operationCard = cards[i]
            guard let operation = operationCard.operation else { return nil } 
            
            guard i + 1 < cards.count, let nextNumberValue = Double(cards[i+1].value) else { return nil } 
            
            switch operation {
            case .add: currentResult += nextNumberValue
            case .subtract: currentResult -= nextNumberValue
            case .multiply: currentResult *= nextNumberValue
            case .divide:
                if nextNumberValue == 0 { return nil } 
                currentResult /= nextNumberValue
            }
            i += 2 
        }
        return currentResult
    }

    // Moved from ViewModel
    private func isValidEquation(cards: [EquationCard]) -> Bool {
        guard cards.count >= 3, cards.count % 2 == 1 else { return false } 

        for (index, card) in cards.enumerated() {
            if index % 2 == 0 && card.type != .number { return false } 
            if index % 2 != 0 && card.type != .operation { return false } 
        }
        return true
    }
    
    private func updateDisplayedEquationValue() {
        self.displayedEquationValue = calculateEquationValue(from: self.selectedCards)
    }

    internal func generateCards() -> [EquationCard] { 
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

// Player, EquationCard, CardType, Operation, EquationGameData, EquationMove structs/enums 
// are now defined in EquationHighLowModels.swift
}

// Helper for safe array access is now in EquationHighLowModels.swift