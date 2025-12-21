import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = Secrets.apiBaseURL
    
    private init() {}
    
    private func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "id_token")
    }
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let token = getAuthToken() else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("❌ Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Response JSON: \(jsonString)")
                }
                throw APIError.serverError("Failed to decode response: \(error.localizedDescription)")
            }
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error.message)
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(jsonString)")
            }
            throw APIError.serverError("Unknown error (status: \(httpResponse.statusCode))")
        }
    }
    
    func getProfile() async throws -> Profile {
        return try await makeRequest(endpoint: "/profile", method: "GET")
    }
    
    func updateProfile(_ profile: Profile) async throws -> Profile {
        return try await makeRequest(endpoint: "/profile", method: "PUT", body: profile)
    }
    
    func getStrength() async throws -> StrengthData {
        return try await makeRequest(endpoint: "/strength", method: "GET")
    }
    
    func updateStrength(_ strengthData: StrengthData) async throws -> StrengthData {
        return try await makeRequest(endpoint: "/strength", method: "PUT", body: strengthData)
    }
    
    func getWorkouts(startDate: String? = nil, endDate: String? = nil) async throws -> WorkoutHistoryResponse {
        var endpoint = "/workout"
        var queryParams: [String] = []
        
        if let start = startDate {
            queryParams.append("startDate=\(start)")
        }
        if let end = endDate {
            queryParams.append("endDate=\(end)")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return try await makeRequest(endpoint: endpoint, method: "GET")
    }
    
    func logWorkout(_ workout: WorkoutData) async throws -> WorkoutData {
        return try await makeRequest(endpoint: "/workout", method: "POST", body: workout)
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Unauthorized - please sign in again"
        case .notFound:
            return "Resource not found"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        }
    }
}

struct ErrorResponse: Codable {
    let error: ErrorDetail
    
    struct ErrorDetail: Codable {
        let code: String
        let message: String
    }
}

