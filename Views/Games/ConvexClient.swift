import Foundation

enum ConvexError: Error {
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
}

class ConvexClient {
    static let shared = ConvexClient()
    let baseURL: String
    
    private init() {
        // Get the URL from environment configuration
        if let url = Bundle.main.infoDictionary?["CONVEX_URL"] as? String {
            self.baseURL = url
        } else {
            // Fallback to development URL
            self.baseURL = "http://localhost:8000"
        }
    }
    
    func updateGameProgress(
        userId: String,
        gameId: String,
        status: String,
        currentLevel: Int,
        score: Int,
        completedAt: Date? = nil
    ) async throws {
        let url = URL(string: "\(baseURL)/updateGameProgress")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "userId": userId,
            "gameId": gameId,
            "status": status,
            "currentLevel": currentLevel,
            "score": score,
            "completedAt": completedAt?.timeIntervalSince1970
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ConvexError.invalidResponse
        }
        
        // Parse response if needed
        _ = try JSONSerialization.jsonObject(with: data)
    }
    
    func getGameProgress(userId: String, gameId: String) async throws -> GameProgress? {
        let url = URL(string: "\(baseURL)/getGameProgress?userId=\(userId)&gameId=\(gameId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ConvexError.invalidResponse
        }
        
        // Parse the response into GameProgress
        struct Response: Codable {
            let currentLevel: Int
            let score: Int
            let status: String
        }
        
        if let json = try? JSONDecoder().decode(Response.self, from: data) {
            return GameProgress(
                currentLevel: json.currentLevel,
                score: json.score,
                status: json.status
            )
        }
        return nil
    }
} 