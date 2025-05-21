import SwiftUI
import Clerk

class GameProgressService {
    static let shared = GameProgressService()
    
    private init() {}
    
    func loadGameProgress(userId: String, gameId: String) async throws -> GameProgress? {
        return try await ConvexClient.shared.getGameProgress(userId: userId, gameId: gameId)
    }
    
    func updateGameProgress(
        userId: String,
        gameId: String,
        status: String,
        currentLevel: Int,
        score: Int,
        completedAt: Date? = nil
    ) async throws {
        try await ConvexClient.shared.updateGameProgress(
            userId: userId,
            gameId: gameId,
            status: status,
            currentLevel: currentLevel,
            score: score,
            completedAt: completedAt
        )
    }
    
    func getLeaderboard(gameId: String, limit: Int = 10) async throws -> [LeaderboardEntry] {
        return try await ConvexClient.shared.getLeaderboard(gameId: gameId, limit: limit)
    }
}

struct GameProgress: Codable {
    let userId: String
    let gameId: String
    let status: String
    let currentLevel: Int
    let score: Int
    let completedAt: Date?
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let score: Int
    let rank: Int
}

struct LeaderboardView: View {
    let gameId: String
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading leaderboard...")
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Error loading leaderboard")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                List(entries) { entry in
                    HStack {
                        Text("\(entry.rank)")
                            .font(.headline)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(entry.username)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Text("\(entry.score)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task {
            do {
                entries = try await GameProgressService.shared.getLeaderboard(gameId: gameId)
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
} 