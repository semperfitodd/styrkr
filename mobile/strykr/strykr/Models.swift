import Foundation

struct Profile: Codable {
    var userId: String?
    var email: String?
    var name: String?
    var trainingDaysPerWeek: Int
    var preferredUnits: String
    var includeNonLiftingDays: Bool
    var nonLiftingDayMode: String
    var constraints: [String]
    var conditioningLevel: String
    var preferredStartDay: String?
    var movementCapabilities: MovementCapabilities
    var createdAt: String?
    var updatedAt: String?
    
    struct MovementCapabilities: Codable {
        var pullups: Bool
        var ringDips: Bool
        var muscleUps: String
        
        init(pullups: Bool = false, ringDips: Bool = false, muscleUps: String = "none") {
            self.pullups = pullups
            self.ringDips = ringDips
            self.muscleUps = muscleUps
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.pullups = try container.decodeIfPresent(Bool.self, forKey: .pullups) ?? false
            self.ringDips = try container.decodeIfPresent(Bool.self, forKey: .ringDips) ?? false
            self.muscleUps = try container.decodeIfPresent(String.self, forKey: .muscleUps) ?? "none"
        }
    }
    
    init(userId: String? = nil, email: String? = nil, name: String? = nil, trainingDaysPerWeek: Int, preferredUnits: String, includeNonLiftingDays: Bool, nonLiftingDayMode: String, constraints: [String], conditioningLevel: String, preferredStartDay: String?, movementCapabilities: MovementCapabilities, createdAt: String? = nil, updatedAt: String? = nil) {
        self.userId = userId
        self.email = email
        self.name = name
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.preferredUnits = preferredUnits
        self.includeNonLiftingDays = includeNonLiftingDays
        self.nonLiftingDayMode = nonLiftingDayMode
        self.constraints = constraints
        self.conditioningLevel = conditioningLevel
        self.preferredStartDay = preferredStartDay
        self.movementCapabilities = movementCapabilities
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        
        // Handle trainingDaysPerWeek as either Int or String
        if let days = try? container.decode(Int.self, forKey: .trainingDaysPerWeek) {
            self.trainingDaysPerWeek = days
        } else if let daysString = try? container.decode(String.self, forKey: .trainingDaysPerWeek),
                  let days = Int(daysString) {
            self.trainingDaysPerWeek = days
        } else {
            self.trainingDaysPerWeek = 4 // Default fallback
        }
        
        self.preferredUnits = try container.decode(String.self, forKey: .preferredUnits)
        self.includeNonLiftingDays = try container.decode(Bool.self, forKey: .includeNonLiftingDays)
        self.nonLiftingDayMode = try container.decode(String.self, forKey: .nonLiftingDayMode)
        self.constraints = try container.decodeIfPresent([String].self, forKey: .constraints) ?? []
        self.conditioningLevel = try container.decodeIfPresent(String.self, forKey: .conditioningLevel) ?? "moderate"
        self.preferredStartDay = try container.decodeIfPresent(String.self, forKey: .preferredStartDay)
        self.movementCapabilities = try container.decodeIfPresent(MovementCapabilities.self, forKey: .movementCapabilities) ?? MovementCapabilities()
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

extension Profile {
    static var empty: Profile {
        Profile(
            trainingDaysPerWeek: 4,
            preferredUnits: "lb",
            includeNonLiftingDays: true,
            nonLiftingDayMode: "pilates",
            constraints: [],
            conditioningLevel: "moderate",
            preferredStartDay: "mon",
            movementCapabilities: MovementCapabilities(
                pullups: false,
                ringDips: false,
                muscleUps: "none"
            )
        )
    }
}

