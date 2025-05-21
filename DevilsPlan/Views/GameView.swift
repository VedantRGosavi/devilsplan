import SwiftUI
import Clerk

protocol GameView: View {
    associatedtype Engine: GameProtocol
    var game: Game { get }
    var engine: Engine { get }
    
    func showTutorial()
    func handleGameComplete()
    func defaultGameNavigation() -> AnyView
}

extension GameView {
    func defaultGameNavigation() -> AnyView {
        AnyView(
            VStack {
                body
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        )
    }
}

struct GameContainerView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            switch game.id {
            case "memory_match":
                MemoryMatchView(
                    game: game,
                    engine: MemoryMatchEngine()
                )
            case "rules_race":
                RulesRaceView(
                    game: game,
                    engine: RulesRaceEngine()
                )
            case "equation_high_low":
                EquationHighLowView(
                    game: game,
                    engine: EquationHighLowEngine()
                )
            default:
                VStack {
                    Text("Game: \(game.name)")
                        .font(.title)
                    
                    Text("Coming Soon!")
                        .font(.headline)
                        .padding()
                    
                    Button("Back to Games") {
                        dismiss()
                    }
                    .padding()
                }
                .navigationTitle(game.name)
            }
        }
    }
}

struct GameTutorialContainerView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("How to Play")
                    .font(.title)
                    .padding()
                
                Text("Tutorial content for \(game.name) will be added here.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Start Game") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarItems(trailing: Button("Skip") {
                dismiss()
            })
        }
    }
}

#Preview {
    GameContainerView(game: Game.preview)
        .environment(Clerk.shared)
} 