import Foundation

struct StrengthData: Codable {
    var oneRepMaxes: OneRepMaxes
    var tmPolicy: TMPolicy
    var trainingMaxes: TrainingMaxes
    var history: [StrengthHistoryEntry]?
    var createdAt: String?
    var updatedAt: String?
}

struct OneRepMaxes: Codable {
    var squat: Double
    var bench: Double
    var deadlift: Double
    var ohp: Double
    
    enum CodingKeys: String, CodingKey {
        case squat, bench, deadlift, ohp
    }
    
    init(squat: Double, bench: Double, deadlift: Double, ohp: Double) {
        self.squat = squat
        self.bench = bench
        self.deadlift = deadlift
        self.ohp = ohp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle both String and Double
        if let squatString = try? container.decode(String.self, forKey: .squat) {
            squat = Double(squatString) ?? 0
        } else {
            squat = try container.decode(Double.self, forKey: .squat)
        }
        
        if let benchString = try? container.decode(String.self, forKey: .bench) {
            bench = Double(benchString) ?? 0
        } else {
            bench = try container.decode(Double.self, forKey: .bench)
        }
        
        if let deadliftString = try? container.decode(String.self, forKey: .deadlift) {
            deadlift = Double(deadliftString) ?? 0
        } else {
            deadlift = try container.decode(Double.self, forKey: .deadlift)
        }
        
        if let ohpString = try? container.decode(String.self, forKey: .ohp) {
            ohp = Double(ohpString) ?? 0
        } else {
            ohp = try container.decode(Double.self, forKey: .ohp)
        }
    }
}

struct TMPolicy: Codable {
    var percent: Double
    var rounding: String
    
    enum CodingKeys: String, CodingKey {
        case percent, rounding
    }
    
    init(percent: Double, rounding: String) {
        self.percent = percent
        self.rounding = rounding
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle both String and Double for percent
        if let percentString = try? container.decode(String.self, forKey: .percent) {
            percent = Double(percentString) ?? 0.9
        } else {
            percent = try container.decode(Double.self, forKey: .percent)
        }
        
        rounding = try container.decode(String.self, forKey: .rounding)
    }
}

struct TrainingMaxes: Codable {
    var squat: Double
    var bench: Double
    var deadlift: Double
    var ohp: Double
    
    enum CodingKeys: String, CodingKey {
        case squat, bench, deadlift, ohp
    }
    
    init(squat: Double, bench: Double, deadlift: Double, ohp: Double) {
        self.squat = squat
        self.bench = bench
        self.deadlift = deadlift
        self.ohp = ohp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle both String and Double
        if let squatString = try? container.decode(String.self, forKey: .squat) {
            squat = Double(squatString) ?? 0
        } else {
            squat = try container.decode(Double.self, forKey: .squat)
        }
        
        if let benchString = try? container.decode(String.self, forKey: .bench) {
            bench = Double(benchString) ?? 0
        } else {
            bench = try container.decode(Double.self, forKey: .bench)
        }
        
        if let deadliftString = try? container.decode(String.self, forKey: .deadlift) {
            deadlift = Double(deadliftString) ?? 0
        } else {
            deadlift = try container.decode(Double.self, forKey: .deadlift)
        }
        
        if let ohpString = try? container.decode(String.self, forKey: .ohp) {
            ohp = Double(ohpString) ?? 0
        } else {
            ohp = try container.decode(Double.self, forKey: .ohp)
        }
    }
}

struct StrengthHistoryEntry: Codable {
    var date: String
    var oneRepMaxes: OneRepMaxes
    var trainingMaxes: TrainingMaxes
}

struct WorkoutData: Codable {
    var userEmail: String?
    var workoutDate: String
    var programWeek: Int
    var sessionId: String
    var mainLift: MainLift
    var circuit: Circuit?
    var supplemental: String?
    var assistance: String?
    var conditioning: String?
    var mobility: String?
    var notes: String?
    var duration: Int?
    var createdAt: String?
}

struct MainLift: Codable {
    var liftId: String
    var sets: [WorkoutSet]
}

struct Circuit: Codable {
    var rounds: Int
    var sets: [CircuitSet]
}

struct CircuitSet: Codable {
    var exerciseId: String
    var exerciseName: String
    var sets: [WorkoutSet]
}

struct WorkoutSet: Codable {
    var weight: Double
    var reps: Int
    var pctTM: Double?
    var targetReps: Int?
}

struct WorkoutHistoryResponse: Codable {
    var workouts: [WorkoutData]
    var count: Int
}

