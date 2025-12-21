import Foundation

// MARK: - Exercise Library
struct ExerciseLibrary: Codable {
    let schemaVersion: Int
    let library: String
    let program: String
    let version: Int
    let publishedAt: String
    let etag: String
    let slotTaxonomy: SlotTaxonomy
    let slotDefinitions: [SlotDefinition]
    let exercises: [Exercise]
}

// MARK: - Slot Taxonomy
struct SlotTaxonomy: Codable {
    let main: [String]
    let supplemental: [String]
    let accessory: [String]
    let conditioning: [String]
    let mobility: [String]
}

// MARK: - Slot Definition
struct SlotDefinition: Codable {
    let slotTag: String
    let label: String
    let requiredPatterns: [String]
}

// MARK: - Exercise
struct Exercise: Codable, Identifiable {
    let exerciseId: String
    let name: String
    let category: ExerciseCategory
    let movementPatterns: [String]
    let slotTags: [String]
    let equipment: [String]
    let constraintsBlocked: [String]
    let fatigueScore: Int
    let notes: String
    
    var id: String { exerciseId }
}

// MARK: - Exercise Category
enum ExerciseCategory: String, Codable, CaseIterable {
    case main
    case supplemental
    case accessory
    case conditioning
    case mobility
    
    var displayName: String {
        switch self {
        case .main: return "Main Lifts"
        case .supplemental: return "Supplemental"
        case .accessory: return "Accessories"
        case .conditioning: return "Conditioning"
        case .mobility: return "Mobility"
        }
    }
    
    var icon: String {
        switch self {
        case .main: return "💪"
        case .supplemental: return "🏋️"
        case .accessory: return "🎯"
        case .conditioning: return "🏃"
        case .mobility: return "🧘"
        }
    }
    
    var color: String {
        switch self {
        case .main: return "667eea"
        case .supplemental: return "764ba2"
        case .accessory: return "11998e"
        case .conditioning: return "f093fb"
        case .mobility: return "4facfe"
        }
    }
}

// MARK: - Exercise Filtering Extensions
extension Array where Element == Exercise {
    func filterByCategory(_ category: ExerciseCategory) -> [Exercise] {
        return self.filter { $0.category == category }
    }
    
    func filterBySlotTags(_ tags: [String]) -> [Exercise] {
        return self.filter { exercise in
            exercise.slotTags.contains(where: { tags.contains($0) })
        }
    }
    
    func filterByEquipment(_ equipment: [String]) -> [Exercise] {
        return self.filter { exercise in
            exercise.equipment.contains(where: { equipment.contains($0) })
        }
    }
    
    func filterSafeForConstraints(_ userConstraints: [String]) -> [Exercise] {
        guard !userConstraints.isEmpty else { return self }
        
        return self.filter { exercise in
            // Exercise is safe if none of its blocked constraints match user constraints
            !exercise.constraintsBlocked.contains(where: { userConstraints.contains($0) })
        }
    }
    
    func search(_ query: String) -> [Exercise] {
        guard !query.isEmpty else { return self }
        
        let lowercaseQuery = query.lowercased()
        return self.filter { exercise in
            exercise.name.lowercased().contains(lowercaseQuery) ||
            exercise.notes.lowercased().contains(lowercaseQuery)
        }
    }
    
    func groupedByCategory() -> [ExerciseCategory: [Exercise]] {
        return Dictionary(grouping: self, by: { $0.category })
    }
}

// MARK: - Fatigue Score Helpers
extension Exercise {
    var fatigueLevel: String {
        switch fatigueScore {
        case 4...5: return "High"
        case 3: return "Moderate"
        default: return "Low"
        }
    }
    
    var fatigueColor: String {
        switch fatigueScore {
        case 4...5: return "ff6b6b"
        case 3: return "ffa500"
        default: return "4caf50"
        }
    }
}


