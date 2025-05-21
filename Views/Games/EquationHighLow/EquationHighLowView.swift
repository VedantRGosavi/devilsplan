import SwiftUI
import Clerk

struct EquationHighLowView: GameView {
    let game: Game
    @StateObject var engine: EquationHighLowEngine
    @Environment(Clerk.self) private var clerk
    @Environment(\.dismiss) private var dismiss
    @State var showingTutorial = true
    @State private var isUpdatingProgress = false
    @State private var isLoadingProgress = true
    
    var body: some View {
        defaultGameNavigation()
            .overlay {
                if isLoadingProgress {
                    ProgressView("Loading game...")
                } else {
                    VStack(spacing: 20) {
                        // Game stats
                        HStack {
                            StatView(title: "Chips", value: "\(engine.currentPlayerChips)")
                            Spacer()
                            StatView(title: "Level", value: "\(engine.currentLevel)")
                            Spacer()
                            StatView(title: "Score", value: "\(engine.score)")
                        }
                        .padding(.horizontal)
                        
                        // Available cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(engine.availableCards) { card in
                                    CardView(card: card) {
                                        engine.selectCard(card)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Selected cards
                        HStack(spacing: 10) {
                            ForEach(engine.selectedCards) { card in
                                CardView(card: card)
                            }
                        }
                        .padding()
                        
                        // Bid controls
                        if engine.players[engine.currentPlayerIndex].id == clerk.user?.id {
                            BidControlsView(
                                bidAmount: engine.bidAmount,
                                onPlaceBid: {
                                    engine.placeBid()
                                }
                            )
                        }
                        
                        // Player stats
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(engine.players) { player in
                                    PlayerStatsView(
                                        player: player,
                                        isCurrentPlayer: engine.players[engine.currentPlayerIndex].id == player.id
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Equation High-Low")
            .sheet(isPresented: $showingTutorial) {
                showTutorial()
            }
            .onChange(of: engine.gameState) { _, newState in
                if newState == .gameComplete {
                    handleGameComplete()
                }
            }
            .task {
                await loadGameProgress()
            }
    }
    
    func showTutorial() {
        TutorialView(title: "How to Play Equation High-Low") {
            VStack(alignment: .leading, spacing: 15) {
                TutorialItem(
                    icon: "number",
                    title: "Build Equations",
                    description: "Select cards to create mathematical equations"
                )
                
                TutorialItem(
                    icon: "target",
                    title: "Target Number",
                    description: "Try to get as close as possible to your target number"
                )
                
                TutorialItem(
                    icon: "dollarsign.circle",
                    title: "Place Bids",
                    description: "Bet chips on your equation being closest"
                )
                
                TutorialItem(
                    icon: "person.3",
                    title: "Multiplayer",
                    description: "Compete with friends to win the most chips"
                )
            }
        } onDismiss: {
            showingTutorial = false
        }
    }
    
    func handleGameComplete() {
        GameCompleteView(
            score: engine.score,
            onPlayAgain: {
                engine.resetGame()
                engine.startGame()
            },
            onExit: {
                updateGameProgress { dismiss() }
            }
        )
    }
    
    private func loadGameProgress() async {
        guard let userId = clerk.user?.id else { return }
        
        do {
            if let progress = try await GameProgressService.shared.loadGameProgress(userId: userId, gameId: game.id) {
                // Initialize the game engine with the saved progress
                // Note: For multiplayer games, we might want to handle this differently
                if progress.status == "in_progress" {
                    engine.currentLevel = progress.currentLevel
                    engine.score = progress.score
                }
            }
        } catch {
            print("Failed to load game progress: \(error)")
        }
        
        isLoadingProgress = false
    }
    
    private func updateGameProgress(completion: @escaping () -> Void) {
        guard !isUpdatingProgress, let userId = clerk.user?.id else { return }
        isUpdatingProgress = true
        
        Task {
            do {
                try await engine.updateGameProgress(userId: userId)
            } catch {
                print("Failed to update game progress: \(error)")
            }
            
            DispatchQueue.main.async {
                isUpdatingProgress = false
                completion()
            }
        }
    }
}

struct CardView: View {
    let card: EquationCard
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            Text(card.value)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 90)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(card.type == .number ? Color.blue : Color.purple)
                        .shadow(color: card.type == .number ? .blue.opacity(0.5) : .purple.opacity(0.5), radius: 5)
                )
        }
        .disabled(onTap == nil)
    }
}

struct BidControlsView: View {
    let bidAmount: Int
    let onPlaceBid: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Current Bid: \(bidAmount)")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: onPlaceBid) {
                Text("Place Bid")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        Capsule()
                            .fill(Color.purple)
                    )
            }
        }
        .padding()
    }
}

struct PlayerStatsView: View {
    let player: Player
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(player.name)
                .font(.headline)
                .foregroundColor(isCurrentPlayer ? .yellow : .white)
            Text("Target: \(player.targetNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Chips: \(player.chips)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrentPlayer ? Color.yellow : Color.purple, lineWidth: 2)
                )
        )
    }
}

#Preview {
    EquationHighLowView(
        game: Game(id: "3", name: "Equation High-Low", description: "Build equations to win", levels: 1, maxScore: 1000),
        engine: EquationHighLowEngine()
    )
    .environment(Clerk())
} 