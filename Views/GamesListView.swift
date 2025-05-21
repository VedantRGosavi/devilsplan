import SwiftUI
import Clerk

struct Game: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let levels: Int
    let maxScore: Int
    var progress: GameProgress?
    
    enum CodingKeys: String, CodingKey {
        case id = "gameId"
        case name
        case description
        case levels
        case maxScore
    }
}

struct GameProgress: Codable {
    let currentLevel: Int
    let score: Int
    let status: String
}

struct GamesListView: View {
    @Environment(Clerk.self) private var clerk
    @State private var games: [Game] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(games) { game in
                                GameCardView(game: game)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Devil's Games")
            .task {
                await loadGames()
            }
        }
    }
    
    private func loadGames() async {
        guard let userId = clerk.user?.id else { return }
        
        do {
            // Fetch games list
            let url = URL(string: "\(ConvexClient.shared.baseURL)/listGames")!
            let (data, _) = try await URLSession.shared.data(from: url)
            var games = try JSONDecoder().decode([Game].self, from: data)
            
            // Fetch progress for each game
            for i in 0..<games.count {
                if let progress = try await ConvexClient.shared.getGameProgress(
                    userId: userId,
                    gameId: games[i].id
                ) {
                    games[i].progress = progress
                }
            }
            
            self.games = games
        } catch {
            print("Failed to load games: \(error)")
        }
        
        isLoading = false
    }
}

struct GameCardView: View {
    let game: Game
    
    var body: some View {
        NavigationLink(destination: GameView(game: game)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(game.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(game.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("\(game.levels) Levels", systemImage: "stairs")
                    Spacer()
                    Label("\(game.maxScore) Points", systemImage: "star.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if let progress = game.progress {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: Double(progress.currentLevel), total: Double(game.levels))
                            .tint(.green)
                        
                        Text("Level \(progress.currentLevel) • Score: \(progress.score)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

#Preview {
    GamesListView()
        .environment(Clerk())
} 