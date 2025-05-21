import SwiftUI
import Clerk

struct MemoryMatchView: GameView {
    let game: Game
    @StateObject var engine: MemoryMatchEngine
    @Environment(Clerk.self) private var clerk
    @Environment(\.dismiss) private var dismiss
    @State var showingTutorial = true
    @State private var showingLevelComplete = false
    @State private var showingGameComplete = false
    @State private var isUpdatingProgress = false
    @State private var isLoadingProgress = true
    
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 10)
    ]
    
    var body: some View {
        defaultGameNavigation()
            .overlay {
                if isLoadingProgress {
                    ProgressView("Loading game...")
                } else {
                    VStack(spacing: 16) {
                        // Game Stats
                        HStack {
                            StatView(title: "Score", value: "\(engine.score)")
                            Spacer()
                            StatView(title: "Level", value: "\(engine.currentLevel)/10")
                            Spacer()
                            StatView(title: "Moves", value: "\(engine.moves)")
                        }
                        .padding(.horizontal)
                        
                        // Cards Grid
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(engine.cards) { card in
                                    MemoryCardView(card: card, color: .blue) {
                                        engine.cardTapped(card)
                                    }
                                    .aspectRatio(2/3, contentMode: .fit)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Memory Match")
            .sheet(isPresented: $showingTutorial) {
                showTutorial()
            }
            .sheet(isPresented: $showingLevelComplete) {
                LevelCompleteView(
                    level: engine.currentLevel,
                    score: engine.score,
                    moves: engine.moves
                ) {
                    engine.nextLevel()
                    showingLevelComplete = false
                }
            }
            .sheet(isPresented: $showingGameComplete) {
                handleGameComplete()
            }
            .onChange(of: engine.gameState) { _, newState in
                switch newState {
                case .levelComplete:
                    showingLevelComplete = true
                case .gameComplete:
                    showingGameComplete = true
                default:
                    break
                }
            }
            .task {
                await loadGameProgress()
            }
    }
    
    func showTutorial() {
        TutorialView(title: "How to Play Memory Match") {
            VStack(alignment: .leading, spacing: 15) {
                TutorialItem(
                    icon: "rectangle.on.rectangle",
                    title: "Find Matching Pairs",
                    description: "Flip cards to find matching pairs of symbols"
                )
                
                TutorialItem(
                    icon: "brain",
                    title: "Remember Locations",
                    description: "Try to remember where you saw each symbol"
                )
                
                TutorialItem(
                    icon: "stopwatch",
                    title: "Time Bonus",
                    description: "Complete levels quickly for bonus points"
                )
                
                TutorialItem(
                    icon: "arrow.up.forward",
                    title: "Progressive Difficulty",
                    description: "Each level adds more pairs to match"
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
                showingGameComplete = false
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
                engine.currentLevel = progress.currentLevel
                engine.score = progress.score
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

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
    }
}

struct TutorialItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LevelCompleteView: View {
    let level: Int
    let score: Int
    let moves: Int
    let onNextLevel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .padding()
            
            Text("Level \(level) Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                Text("Score: \(score)")
                    .font(.headline)
                Text("Moves: \(moves)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Button("Next Level") {
                onNextLevel()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
}

struct GameCompleteView: View {
    let score: Int
    let onPlayAgain: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .padding()
            
            Text("Congratulations!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've completed all levels!")
                .font(.headline)
            
            Text("Final Score: \(score)")
                .font(.title2)
                .padding()
            
            HStack(spacing: 20) {
                Button("Play Again") {
                    onPlayAgain()
                }
                .buttonStyle(.bordered)
                
                Button("Exit") {
                    onExit()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    MemoryMatchView(
        game: Game(id: "1", name: "Memory Match", description: "Test your memory", levels: 10, maxScore: 1000),
        engine: MemoryMatchEngine()
    )
    .environment(Clerk())
} 