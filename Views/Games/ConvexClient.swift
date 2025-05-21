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
        // The CONVEX_URL should be set in your app's Info.plist.
        // For example, add a key "CONVEX_URL" with your Convex deployment URL string value.
        // e.g., "https://your-convex-deployment.convex.cloud"

        if let configuredURL = Bundle.main.infoDictionary?["CONVEX_URL"] as? String, !configuredURL.isEmpty {
            self.baseURL = configuredURL
            AppLogger.info("Using configured CONVEX_URL: \(self.baseURL)")
        } else {
            #if DEBUG
            // In DEBUG mode, if CONVEX_URL is not set or is empty,
            // fall back to a local development URL and log a warning.
            AppLogger.warning("""
            CONVEX_URL not found in Info.plist or is empty.
            Falling back to development URL: http://localhost:8000.
            Please set CONVEX_URL in your Info.plist for other configurations.
            """)
            self.baseURL = "http://localhost:8000"
            #else
            // In RELEASE mode (or any non-DEBUG mode), if CONVEX_URL is not set or is empty,
            // it's a critical configuration error.
            // Crashing loudly to prevent a misconfigured production app from running.
            fatalError("""
            ConvexClient CRITICAL ERROR: CONVEX_URL not found in Info.plist or is empty.
            This is required for production builds. Please set it in your Info.plist.
            """)
            // self.baseURL = "" // Should not reach here due to fatalError
            #endif
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body) // This can throw, handled by func signature
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                // Consider logging the response details here if it's not a 2xx
                // For example, if response is HTTPURLResponse, log httpResponse.statusCode
                // If response is not HTTPURLResponse, log generic invalidResponse
                AppLogger.warning("updateGameProgress received invalid HTTP response: \(String(describing: response))")
                throw ConvexError.invalidResponse
            }
            
            // Attempt to parse response JSON. Even if we don't use the result,
            // this validates that the response is valid JSON.
            _ = try JSONSerialization.jsonObject(with: data)
            // If specific data is expected, decode into a struct instead.
            
        } catch let error as ConvexError {
            throw error // Rethrow ConvexError directly
        } catch let error as DecodingError {
            AppLogger.error("updateGameProgress decoding error: \(error)")
            throw ConvexError.decodingError(error)
        } catch {
            AppLogger.error("updateGameProgress network or other error: \(error)")
            throw ConvexError.networkError(error)
        }
    }
    
    func getGameProgress(userId: String, gameId: String) async throws -> GameProgress? {
        guard let url = URL(string: "\(baseURL)/getGameProgress?userId=\(userId)&gameId=\(gameId)") else {
            // This case should ideally not happen if baseURL and params are correct.
            AppLogger.error("getGameProgress: Could not create URL.")
            throw URLError(.badURL) // Or a custom app error
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                AppLogger.warning("getGameProgress received invalid HTTP response: \(String(describing: response))")
                throw ConvexError.invalidResponse
            }
            
            // Parse the response into GameProgress
            struct Response: Codable {
                let currentLevel: Int
                let score: Int
                let status: String
            }
            
            // Use try, not try? to allow error propagation for decoding issues
            let jsonResponse = try JSONDecoder().decode(Response.self, from: data)
            return GameProgress(
                currentLevel: jsonResponse.currentLevel,
                score: jsonResponse.score,
                status: jsonResponse.status
            )
        } catch let error as ConvexError {
            throw error // Rethrow ConvexError directly
        } catch let error as DecodingError {
            AppLogger.error("getGameProgress decoding error: \(error)")
            throw ConvexError.decodingError(error)
        } catch {
            AppLogger.error("getGameProgress network or other error: \(error)")
            throw ConvexError.networkError(error)
        }
    }
} 