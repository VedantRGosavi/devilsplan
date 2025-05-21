import SwiftUI
import Clerk

struct GameView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if game.name == "Memory Match" {
                MemoryMatchView(game: game)
            } else {
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

struct TutorialView: View {
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
    GameView(game: Game(id: "1", name: "Memory Match", description: "Test your memory", levels: 10, maxScore: 1000))
} 