import Foundation
import Combine

class ExerciseLibraryService: ObservableObject {
    static let shared = ExerciseLibraryService()
    
    @Published var library: ExerciseLibrary?
    @Published var isLoading = false
    @Published var error: String?
    
    private let libraryURL = Secrets.exerciseLibraryURL
    private let cacheKey = "cached_exercise_library"
    private let cacheTimestampKey = "library_cache_timestamp"
    private let cacheDuration: TimeInterval = 5 * 60 // 5 minutes
    
    private init() {}
    
    /// Fetch the exercise library from CloudFront
    /// Uses cached version if available and not expired
    func fetchLibrary(forceRefresh: Bool = false) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        // Check cache first
        if !forceRefresh, let cachedLibrary = loadFromCache() {
            await MainActor.run {
                self.library = cachedLibrary
                self.isLoading = false
            }
            return
        }
        
        // Fetch from network
        do {
            guard let url = URL(string: libraryURL) else {
                throw ExerciseLibraryError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // Add cache-busting if force refresh
            if forceRefresh {
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ExerciseLibraryError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw ExerciseLibraryError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let library = try decoder.decode(ExerciseLibrary.self, from: data)
            
            // Validate library structure
            guard !library.exercises.isEmpty else {
                throw ExerciseLibraryError.emptyLibrary
            }
            
            // Cache the result
            saveToCache(library)
            
            await MainActor.run {
                self.library = library
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Cache Management
    
    private func loadFromCache() -> ExerciseLibrary? {
        // Check if cache is expired
        if let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
            let elapsed = Date().timeIntervalSince(timestamp)
            if elapsed > cacheDuration {
                // Cache expired
                return nil
            }
        } else {
            // No timestamp, cache is invalid
            return nil
        }
        
        // Load cached data
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let library = try decoder.decode(ExerciseLibrary.self, from: data)
            return library
        } catch {
            print("❌ Failed to decode cached library: \(error)")
            return nil
        }
    }
    
    private func saveToCache(_ library: ExerciseLibrary) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(library)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
        } catch {
            print("❌ Failed to cache library: \(error)")
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }
    
    // MARK: - Helper Methods
    
    func getExercisesForSlot(_ slotTag: String, userConstraints: [String] = []) -> [Exercise] {
        guard let library = library else { return [] }
        
        return library.exercises
            .filterBySlotTags([slotTag])
            .filterSafeForConstraints(userConstraints)
    }
    
    func getMainLifts() -> [Exercise] {
        guard let library = library else { return [] }
        return library.exercises.filterByCategory(.main)
    }
    
    func getAccessories() -> [Exercise] {
        guard let library = library else { return [] }
        return library.exercises.filterByCategory(.accessory)
    }
    
    func getConditioning() -> [Exercise] {
        guard let library = library else { return [] }
        return library.exercises.filterByCategory(.conditioning)
    }
    
    func getMobility() -> [Exercise] {
        guard let library = library else { return [] }
        return library.exercises.filterByCategory(.mobility)
    }
}

// MARK: - Errors
enum ExerciseLibraryError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case emptyLibrary
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid library URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .emptyLibrary:
            return "Library contains no exercises"
        case .decodingError(let message):
            return "Failed to decode library: \(message)"
        }
    }
}


