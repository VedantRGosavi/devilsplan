import SwiftUI
import Clerk

struct Game: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String
    let levels: Int
    let maxScore: Int
    
    static let preview = Game(
        id: "preview",
        name: "Preview Game",
        description: "A preview game for testing",
        imageUrl: "https://example.com/preview.jpg",
        levels: 1,
        maxScore: 1000
    )
    
    static let sampleGames = [
        Game(
            id: "memory_match",
            name: "Memory Match",
            description: "Test your memory by matching pairs of cards. Each level adds more pairs to challenge you!",
            imageUrl: "https://example.com/memory.jpg",
            levels: 10,
            maxScore: 10000
        ),
        Game(
            id: "rules_race",
            name: "Rules Race",
            description: "Race to the finish line in this multiplayer board game. Watch out for special squares!",
            imageUrl: "https://example.com/race.jpg",
            levels: 1,
            maxScore: 5000
        ),
        Game(
            id: "equation_high_low",
            name: "Equation High-Low",
            description: "Build equations to get as close as possible to the target number. Bet wisely!",
            imageUrl: "https://example.com/equation.jpg",
            levels: 5,
            maxScore: 7500
        )
    ]
}

struct GamesListView: View {
    @Environment(Clerk.self) private var clerk
    @State private var games: [Game] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            List(games) { game in
                NavigationLink(destination: GameDetailView(game: game)) {
                    GameRowView(game: game)
                }
            }
            .navigationTitle("Games")
            .task {
                await loadGames()
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading games...")
                }
            }
        }
    }
    
    private func loadGames() async {
        // TODO: Replace with actual API call when backend is ready
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        games = Game.sampleGames
        isLoading = false
    }
}

#Preview {
    GamesListView()
        .environment(Clerk.shared)
} 