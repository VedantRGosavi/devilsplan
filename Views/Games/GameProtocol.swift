import SwiftUI
import Clerk

protocol GameProtocol {
    var gameState: GameState { get }
    var score: Int { get }
    var isMultiplayer: Bool { get }
    
    func startGame()
    func resetGame()
    func endGame()
    func updateGameProgress(userId: String) async throws
}

enum GameState {
    case notStarted
    case playing
    case paused
    case roundEnded
    case levelComplete
    case gameComplete
}

protocol GameView: View {
    associatedtype GameEngine: GameProtocol
    
    var engine: GameEngine { get }
    var showingTutorial: Bool { get set }
    
    func showTutorial()
    func handleGameComplete()
}

extension GameView {
    func defaultGameNavigation() -> some View {
        NavigationView {
            self
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading: BackButton())
        }
    }
}

struct BackButton: View {
    @Environment(\\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: { dismiss() }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Exit Game")
            }
            .foregroundColor(.white)
        }
    }
}

struct TutorialView<Content: View>: View {
    let title: String
    let content: Content
    let onDismiss: () -> Void
    
    init(title: String, @ViewBuilder content: () -> Content, onDismiss: @escaping () -> Void) {
        self.title = title
        self.content = content()
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                content
                    .padding()
                
                Button("Start Playing") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Skip") {
                onDismiss()
            })
        }
    }
} 