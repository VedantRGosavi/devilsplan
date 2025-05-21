import XCTest
@testable import DevilsPlan // Assuming your app module is named DevilsPlan

// Custom URLProtocol for mocking network responses
class MockURLProtocol: URLProtocol {
    // Static properties to hold request handler and response data
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all requests
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Required method, just return the original request
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("MockURLProtocol.requestHandler is not set.")
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Required method, nothing to do here for this mock
    }
}

class ConvexClientTests: XCTestCase {

    var client: ConvexClient!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Configure URLSession to use our MockURLProtocol
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)
        
        // Since ConvexClient uses URLSession.shared directly, we need a way to
        // make it use our configured session. This is the tricky part.
        // One common approach for non-injectable URLSession.shared is to swizzle its usage,
        // or to use a library that facilitates this.
        // For now, we'll assume that if we can't directly inject, we might need
        // to adjust ConvexClient or use a more advanced mocking technique.
        // Let's proceed assuming we can test by controlling the shared session's behavior
        // via URLProtocol, which intercepts requests made by URLSession.shared.

        client = ConvexClient.shared // Using the shared instance as in the app
    }

    override func tearDownWithError() throws {
        MockURLProtocol.requestHandler = nil
        client = nil
        super.tearDown()
    }

    // MARK: - Test Cases for updateGameProgress

    func testUpdateGameProgress_Success() async throws {
        let expectedUserID = "testUser123"
        let expectedGameID = "gameXYZ"
        let expectedStatus = "completed"
        let expectedLevel = 5
        let expectedScore = 1000
        let expectedDate = Date()

        let expectedURL = URL(string: "\(client.baseURL)/updateGameProgress")!
        
        // Mock successful response
        let mockResponseData = try JSONSerialization.data(withJSONObject: ["status": "success", "message": "Progress updated"], options: [])
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, expectedURL)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            
            // Verify body
            guard let httpBody = request.httpBody else {
                XCTFail("HTTP body is nil")
                throw URLError(.badServerResponse) // Should not happen
            }
            
            let jsonBody = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            XCTAssertEqual(jsonBody?["userId"] as? String, expectedUserID)
            XCTAssertEqual(jsonBody?["gameId"] as? String, expectedGameID)
            XCTAssertEqual(jsonBody?["status"] as? String, expectedStatus)
            XCTAssertEqual(jsonBody?["currentLevel"] as? Int, expectedLevel)
            XCTAssertEqual(jsonBody?["score"] as? Int, expectedScore)
            XCTAssertEqual(jsonBody?["completedAt"] as? Double, expectedDate.timeIntervalSince1970)
            
            let response = HTTPURLResponse(url: expectedURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockResponseData)
        }
        
        // Perform the call
        try await client.updateGameProgress(
            userId: expectedUserID,
            gameId: expectedGameID,
            status: expectedStatus,
            currentLevel: expectedLevel,
            score: expectedScore,
            completedAt: expectedDate
        )
        // If no error is thrown, the test passes for success.
    }

    func testUpdateGameProgress_NetworkError() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        do {
            try await client.updateGameProgress(userId: "test", gameId: "test", status: "test", currentLevel: 1, score: 1)
            XCTFail("Expected ConvexError.networkError to be thrown")
        } catch ConvexError.networkError(let error) {
            // Expected error
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error type thrown: \(error)")
        }
    }
    
    func testUpdateGameProgress_InvalidHTTPResponse() async throws {
        let expectedURL = URL(string: "\(client.baseURL)/updateGameProgress")!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: expectedURL, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        do {
            try await client.updateGameProgress(userId: "test", gameId: "test", status: "test", currentLevel: 1, score: 1)
            XCTFail("Expected ConvexError.invalidResponse to be thrown")
        } catch ConvexError.invalidResponse {
            // Expected error
        } catch {
            XCTFail("Unexpected error type thrown: \(error)")
        }
    }

    func testUpdateGameProgress_DecodingError() async throws {
        // This tests if the client correctly handles a 200 OK response but with malformed JSON
        // The ConvexClient's updateGameProgress currently expects some JSON back but doesn't decode it into a specific struct.
        // It uses `_ = try JSONSerialization.jsonObject(with: data)`. If this fails, it should throw a decoding error.
        let expectedURL = URL(string: "\(client.baseURL)/updateGameProgress")!
        let malformedJSONData = Data("this is not json".utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: expectedURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, malformedJSONData)
        }

        do {
            try await client.updateGameProgress(userId: "test", gameId: "test", status: "test", currentLevel: 1, score: 1)
            XCTFail("Expected ConvexError.decodingError to be thrown")
        } catch ConvexError.decodingError {
            // Expected error
        } catch {
            XCTFail("Unexpected error type thrown: \(error)")
        }
    }

    // MARK: - Test Cases for getGameProgress
    
    func testGetGameProgress_Success() async throws {
        let expectedUserID = "testUserGet"
        let expectedGameID = "gameGetXYZ"
        let expectedURL = URL(string: "\(client.baseURL)/getGameProgress?userId=\(expectedUserID)&gameId=\(expectedGameID)")!
        
        let mockProgressData = GameProgress(currentLevel: 3, score: 300, status: "in_progress")
        // This needs to be encoded as the `Response` struct within getGameProgress
        struct ServerResponse: Codable {
            let currentLevel: Int
            let score: Int
            let status: String
        }
        let serverResponse = ServerResponse(currentLevel: mockProgressData.currentLevel, score: mockProgressData.score, status: mockProgressData.status)
        let responseJSONData = try JSONEncoder().encode(serverResponse)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, expectedURL)
            XCTAssertEqual(request.httpMethod, "GET")
            
            let response = HTTPURLResponse(url: expectedURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSONData)
        }
        
        let progress = try await client.getGameProgress(userId: expectedUserID, gameId: expectedGameID)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.currentLevel, mockProgressData.currentLevel)
        XCTAssertEqual(progress?.score, mockProgressData.score)
        XCTAssertEqual(progress?.status, mockProgressData.status)
    }

    func testGetGameProgress_NetworkError() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        do {
            _ = try await client.getGameProgress(userId: "test", gameId: "test")
            XCTFail("Expected ConvexError.networkError to be thrown")
        } catch ConvexError.networkError(let error) {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error type thrown: \(error)")
        }
    }

    func testGetGameProgress_InvalidHTTPResponse() async throws {
        let expectedURL = URL(string: "\(client.baseURL)/getGameProgress?userId=test&gameId=test")!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: expectedURL, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        do {
            _ = try await client.getGameProgress(userId: "test", gameId: "test")
            XCTFail("Expected ConvexError.invalidResponse to be thrown")
        } catch ConvexError.invalidResponse {
            // Expected error
        } catch {
            XCTFail("Unexpected error type thrown: \(error)")
        }
    }

    func testGetGameProgress_DecodingError() async throws {
        let expectedURL = URL(string: "\(client.baseURL)/getGameProgress?userId=test&gameId=test")!
        let malformedJSONData = Data("{\"invalid_json\":".utf8) // Malformed JSON

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: expectedURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, malformedJSONData)
        }

        do {
            _ = try await client.getGameProgress(userId: "test", gameId: "test")
            XCTFail("Expected ConvexError.decodingError to be thrown")
        } catch ConvexError.decodingError {
            // Expected error
        } catch {
            XCTFail("Unexpected error type thrown: \(error)")
        }
    }
}
