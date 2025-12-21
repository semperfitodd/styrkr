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
    private let cacheDuration: TimeInterval = 5 * 60
    
    private init() {}
    
    private func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
    
    func fetchLibrary(forceRefresh: Bool = false) async {
        log("🔄 Starting library fetch...")
        log("   URL: \(libraryURL)")
        log("   Force refresh: \(forceRefresh)")
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        if !forceRefresh, let cachedLibrary = loadFromCache() {
            log("✅ Using cached library (\(cachedLibrary.exercises.count) exercises)")
            await MainActor.run {
                self.library = cachedLibrary
                self.isLoading = false
            }
            return
        }
        
        log("🌐 Fetching from network...")
        
        do {
            guard let url = URL(string: libraryURL) else {
                log("❌ Invalid URL: \(libraryURL)")
                throw ExerciseLibraryError.invalidURL
            }
            
            log("✅ URL is valid, making request...")
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            if forceRefresh {
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            log("📥 Received response, data size: \(data.count) bytes")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                log("❌ Invalid HTTP response")
                throw ExerciseLibraryError.invalidResponse
            }
            
            log("📊 HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                log("❌ HTTP Error: \(httpResponse.statusCode)")
                log("   URL: \(libraryURL)")
                if let responseString = String(data: data, encoding: .utf8) {
                    log("   Response: \(responseString.prefix(200))")
                }
                throw ExerciseLibraryError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            
            if let jsonString = String(data: data, encoding: .utf8) {
                log("📦 Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
            }
            
            log("🔍 Attempting to decode JSON...")
            
            let library: ExerciseLibrary
            do {
                library = try decoder.decode(ExerciseLibrary.self, from: data)
                log("✅ Successfully decoded library!")
            } catch let decodingError as DecodingError {
                log("❌ Decoding Error Details:")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    log("  - Missing key: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                case .typeMismatch(let type, let context):
                    log("  - Type mismatch for type: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    log("  - Debug description: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    log("  - Value not found for type: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                case .dataCorrupted(let context):
                    log("  - Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    log("  - Debug description: \(context.debugDescription)")
                @unknown default:
                    log("  - Unknown decoding error: \(decodingError)")
                }
                throw ExerciseLibraryError.decodingError(decodingError.localizedDescription)
            }
            
            log("📚 Library loaded:")
            log("   - Schema version: \(library.schemaVersion)")
            log("   - Program: \(library.program)")
            log("   - Version: \(library.version)")
            log("   - Exercises: \(library.exercises.count)")
            log("   - Slot definitions: \(library.slotDefinitions.count)")
            
            guard !library.exercises.isEmpty else {
                log("❌ Library has no exercises!")
                throw ExerciseLibraryError.emptyLibrary
            }
            
            saveToCache(library)
            log("💾 Library cached successfully")
            
            await MainActor.run {
                self.library = library
                self.isLoading = false
            }
            
            log("✅ Library fetch complete!")
            
        } catch {
            log("❌ Final error: \(error)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func loadFromCache() -> ExerciseLibrary? {
        log("🔍 Checking cache...")
        
        if let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
            let elapsed = Date().timeIntervalSince(timestamp)
            log("   Cache age: \(Int(elapsed)) seconds (max: \(Int(cacheDuration)))")
            if elapsed > cacheDuration {
                log("   ⏰ Cache expired")
                return nil
            }
        } else {
            log("   ❌ No cache timestamp found")
            return nil
        }
        
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            log("   ❌ No cached data found")
            return nil
        }
        
        log("   📦 Found cached data (\(data.count) bytes)")
        
        do {
            let decoder = JSONDecoder()
            let library = try decoder.decode(ExerciseLibrary.self, from: data)
            log("   ✅ Successfully decoded cached library")
            return library
        } catch {
            log("   ❌ Failed to decode cached library: \(error)")
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
            log("❌ Failed to cache library: \(error)")
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }
    
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
    
    func getSupplemental() -> [Exercise] {
        guard let library = library else { return [] }
        return library.exercises.filterByCategory(.supplemental)
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


