import SwiftUI
import Clerk

struct RulesRaceView: GameView {
    let game: Game
    @StateObject var engine: RulesRaceEngine
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
                        // Game board
                        GameBoardView(
                            players: engine.players,
                            rules: engine.rules,
                            currentPlayerIndex: engine.currentPlayerIndex
                        )
                        
                        // Player stats
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(engine.players) { player in
                                    RulesRacePlayerStatsView(
                                        player: player,
                                        isCurrentPlayer: engine.players[engine.currentPlayerIndex].id == player.id
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Dice and controls
                        if engine.players[engine.currentPlayerIndex].id == clerk.user?.id {
                            DiceView(result: engine.diceResult) {
                                engine.rollDice()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rules Race")
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
        TutorialView(title: "How to Play Rules Race") {
            VStack(alignment: .leading, spacing: 15) {
                TutorialItem(
                    icon: "dice",
                    title: "Roll the Dice",
                    description: "Take turns rolling the dice to move forward"
                )
                
                TutorialItem(
                    icon: "arrow.up.and.down",
                    title: "Special Squares",
                    description: "Landing on certain squares will move you up or down"
                )
                
                TutorialItem(
                    icon: "person.3",
                    title: "Multiplayer",
                    description: "Play with friends and compete to reach the finish first"
                )
                
                TutorialItem(
                    icon: "flag.checkered",
                    title: "Win Condition",
                    description: "First player to reach or pass 100 wins"
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

struct GameBoardView: View {
    let players: [RulesRacePlayer]
    let rules: [GameRule]
    let currentPlayerIndex: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Board background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 2)
                    )
                
                // Grid lines
                Path { path in
                    for i in 1...9 {
                        let x = geometry.size.width * CGFloat(i) / 10
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        
                        let y = geometry.size.height * CGFloat(i) / 10
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                
                // Rules
                ForEach(rules, id: \.position) { rule in
                    RuleArrow(
                        from: positionToPoint(rule.position, in: geometry.size),
                        to: positionToPoint(rule.newPosition, in: geometry.size),
                        isUpward: rule.newPosition > rule.position
                    )
                }
                
                // Players
                ForEach(players) { player in
                    PlayerToken(
                        position: positionToPoint(player.position, in: geometry.size),
                        isCurrentPlayer: players[currentPlayerIndex].id == player.id
                    )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }
    
    private func positionToPoint(_ position: Int, in size: CGSize) -> CGPoint {
        let row = (position - 1) / 10
        let col = (position - 1) % 10
        
        return CGPoint(
            x: size.width * (CGFloat(col) + 0.5) / 10,
            y: size.height * (CGFloat(9 - row) + 0.5) / 10
        )
    }
}

struct RuleArrow: View {
    let from: CGPoint
    let to: CGPoint
    let isUpward: Bool
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(isUpward ? Color.green : Color.red, lineWidth: 2)
    }
}

struct PlayerToken: View {
    let position: CGPoint
    let isCurrentPlayer: Bool
    
    var body: some View {
        Circle()
            .fill(isCurrentPlayer ? Color.yellow : Color.white)
            .frame(width: 20, height: 20)
            .position(position)
            .shadow(color: isCurrentPlayer ? .yellow.opacity(0.5) : .white.opacity(0.3), radius: 5)
    }
}

struct RulesRacePlayerStatsView: View {
    let player: RulesRacePlayer
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(player.name)
                .font(.headline)
                .foregroundColor(isCurrentPlayer ? .yellow : .white)
            Text("Position: \(player.position)")
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

struct DiceView: View {
    let result: Int
    let onRoll: () -> Void
    
    var body: some View {
        VStack {
            Text("\(result)")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 100, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple)
                        .shadow(color: .purple.opacity(0.5), radius: 10)
                )
            
            Button(action: onRoll) {
                Text("Roll Dice")
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

#Preview {
    RulesRaceView(
        game: Game.preview,
        engine: RulesRaceEngine()
    )
    .environment(Clerk.shared)
} 