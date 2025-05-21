import SwiftUI
import Combine

class EquationHighLowViewModel: ObservableObject {
    @ObservedObject var engine: EquationHighLowEngine
    
    // Properties like canBid will now be derived from engine's state or be methods in the engine
    // @Published var canBid = false 

    // currentEquationResult will now be a method or computed property that likely calls engine's logic
    // Or the engine itself might publish the result if it's part of the shared state.
    // For now, let's assume it's a calculation based on engine.selectedCards
    var currentEquationResult: Double? {
        // Logic has been moved to the engine. ViewModel now reads from engine's published property.
        return engine.displayedEquationValue
    }
    
    // private var cancellables = Set<AnyCancellable>() // No longer needed
    // private let gameService: EquationHighLowGameService // ViewModel interacts with Engine, not GameService directly.
    
    init(engine: EquationHighLowEngine) {
        self.engine = engine
        // setupGame() is removed - engine handles its own setup
        // observeGameState() is removed - direct observation of engine's @Published properties
    }
    
    // setupGame() removed - engine handles this
    
    // observeGameState() and handleGameState() removed
    
    func selectCard(_ card: EquationCard) {
        // Delegate to the engine. The engine will handle selection logic and multiplayer broadcast.
        engine.selectCard(card)
        // Logic for canBid should be handled by the engine's state changes.
    }
    
    // Renamed from removeCard to better reflect the action now implemented in the engine.
    // The view might need to be updated if it was calling removeCard(card).
    // This method now doesn't need a card parameter if it always removes the last one.
    func deselectLastSelectedCard() { 
        engine.deselectLastCard()
    }
    
    // isValidCardSelection, isValidEquation, and calculateEquationResult(from:)
    // have been moved to EquationHighLowEngine.
    // The ViewModel will rely on the engine for these logic pieces.
    
    // placeBid() method in ViewModel:
    // The engine has `placeBid()`. The ViewModel should have a corresponding method.
    // This was removed in a previous step due to `isHigh` parameter, but a simple passthrough is needed.
    func placeBid() {
        engine.placeBid()
    }
    
    // placeBid(isHigh: Bool) was removed.
    // ViewModel should call engine.placeBid().
    // The engine's placeBid() uses its own bidAmount.
    // The concept of "isHigh" or a specific target for a bid needs to be reconciled
    // with how engine.evaluateRound() uses player.targetNumber.
    // For now, the ViewModel will only trigger the engine's existing placeBid().
    // If player.targetNumber needs to be set, it would be a separate action via the engine.

    // determineRoundWinner() and handleGameEnd() were stubs calling gameService,
    // these are responsibilities of the engine.
}

// MARK: - Game Models
// GameState, Player, EquationCard, CardType, Operation models 
// are now sourced from EquationHighLowModels.swift.
// The Bid struct, as previously used here, is considered obsolete.