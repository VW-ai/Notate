import Foundation
import Combine

@MainActor
class AIService: ObservableObject {
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private var apiKey: String?

    @Published var isConfigured: Bool = false
    @Published var lastError: String?

    init() {
        loadAPIKey()
    }

    // MARK: - Configuration

    func setAPIKey(_ key: String) {
        self.apiKey = key
        saveAPIKey(key)
        isConfigured = !key.isEmpty
        lastError = nil
    }

    func testConnection() async -> Bool {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            lastError = "API key not configured"
            return false
        }

        do {
            let testPrompt = PromptManager.connectionTestPrompt()
            let response = try await makeAPICall(prompt: testPrompt, maxTokens: 10)
            lastError = nil
            return response.lowercased().contains("connected")
        } catch {
            lastError = "Connection failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Research Generation

    func generateTodoResearch(_ content: String, userContext: UserContext? = nil) async throws -> ResearchResults {
        let prompt = PromptManager.todoResearchPrompt(content: content, userContext: userContext)

        let startTime = Date()
        let response = try await makeAPICall(prompt: prompt, maxTokens: 500)
        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

        // Log prompt usage for analytics
        PromptManager.logPromptUsage("todo_research", responseTime: TimeInterval(processingTime))

        return ResearchResults(
            content: response,
            generatedAt: Date(),
            researchCost: 0.003, // Approximate cost for Haiku
            processingTimeMs: processingTime
        )
    }

    func generatePieceResearch(_ content: String, userContext: UserContext? = nil) async throws -> ResearchResults {
        let prompt = PromptManager.pieceResearchPrompt(content: content, userContext: userContext)

        let startTime = Date()
        let response = try await makeAPICall(prompt: prompt, maxTokens: 500)
        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

        // Log prompt usage for analytics
        PromptManager.logPromptUsage("piece_research", responseTime: TimeInterval(processingTime))

        return ResearchResults(
            content: response,
            generatedAt: Date(),
            researchCost: 0.003,
            processingTimeMs: processingTime
        )
    }

    // MARK: - Private API Methods

    private func makeAPICall(prompt: String, maxTokens: Int = 500) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.noAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let requestBody: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Configure URLSession with longer timeout for better reliability
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        let session = URLSession(configuration: config)

        let (data, response): (Data, URLResponse)
        do {
            print("🌐 Making API request to: \(url.absoluteString)")
            (data, response) = try await session.data(for: request)
            print("📡 API request completed successfully")
        } catch {
            print("❌ Network error occurred: \(error)")
            throw AIServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError(httpResponse.statusCode, errorMessage)
        }

        let responseDict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let content = responseDict["content"] as! [[String: Any]]
        let text = content[0]["text"] as! String

        return text
    }

    // MARK: - Quick Methods for Content Extraction

    func quickExtraction(_ prompt: String) async throws -> String {
        return try await makeAPICall(prompt: prompt, maxTokens: 200) // Smaller response for extraction
    }

    func quickClassification(_ prompt: String) async throws -> String {
        return try await makeAPICall(prompt: prompt, maxTokens: 100) // Even smaller for classification
    }

    // MARK: - API Key Storage

    private func loadAPIKey() {
        if let key = KeychainHelper.load(key: "claude_api_key") {
            self.apiKey = key
            self.isConfigured = !key.isEmpty
        }
    }

    private func saveAPIKey(_ key: String) {
        KeychainHelper.save(key: "claude_api_key", data: key)
    }
}

// MARK: - Error Types

enum AIServiceError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Claude API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .networkError(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cannotFindHost:
                    return "Cannot reach Anthropic servers. Check your internet connection."
                case .timedOut:
                    return "Request timed out. Please try again."
                case .notConnectedToInternet:
                    return "No internet connection available."
                default:
                    return "Network error: \(urlError.localizedDescription)"
                }
            }
            return "Network error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        }
    }
}

// Note: ResearchResults is defined in AIMetadata.swift

// MARK: - Keychain Helper

private class KeychainHelper {
    static func save(key: String, data: String) {
        let data = Data(data.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }

        return nil
    }
}