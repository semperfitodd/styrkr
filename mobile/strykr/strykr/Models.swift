import Foundation

/**
 * User Profile v1 Contract
 * 
 * This matches the backend TypeScript definition exactly.
 * Profile is scoped per user (never includes userId/email/name from client).
 * 
 * Security: userId is derived from JWT on backend, never sent from client.
 */
struct Profile: Codable {
    // A) Training Schedule
    var trainingDaysPerWeek: Int
    var preferredStartDay: String
    var preferredUnits: String
    
    // B) Non-Lifting Days
    var nonLiftingDaysEnabled: Bool
    var nonLiftingDayMode: String
    var conditioningLevel: String
    
    // Metadata (managed by backend)
    var createdAt: String?
    var updatedAt: String?
    
    init(trainingDaysPerWeek: Int, preferredStartDay: String, preferredUnits: String, nonLiftingDaysEnabled: Bool, nonLiftingDayMode: String, conditioningLevel: String, createdAt: String? = nil, updatedAt: String? = nil) {
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.preferredStartDay = preferredStartDay
        self.preferredUnits = preferredUnits
        self.nonLiftingDaysEnabled = nonLiftingDaysEnabled
        self.nonLiftingDayMode = nonLiftingDayMode
        self.conditioningLevel = conditioningLevel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Profile {
    static var empty: Profile {
        Profile(
            trainingDaysPerWeek: 4,
            preferredStartDay: "mon",
            preferredUnits: "lb",
            nonLiftingDaysEnabled: true,
            nonLiftingDayMode: "pilates",
            conditioningLevel: "moderate"
        )
    }
}

