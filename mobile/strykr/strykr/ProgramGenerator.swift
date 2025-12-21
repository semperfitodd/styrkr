import Foundation

struct ProgramTemplate: Codable {
    let programName: String
    let macrocycle: Macrocycle
    let setSchemes: [String: SetScheme]
    let sessionTemplates: [String: SessionTemplate]
}

struct Macrocycle: Codable {
    let cycleLengthWeeks: Int
    let phases: [Phase]
}

struct Phase: Codable {
    let phaseId: String
    let label: String
    let weeks: [Int]
    let mainLiftScheme: String?
    let mainLiftSchemeByWeekInCycle: [String: String]?
    let rules: PhaseRules
}

struct PhaseRules: Codable {
    let supplementalUsesFSL: Bool?
    let supplementalEnabled: Bool?
    let circuitRounds: Int?
}

struct SetScheme: Codable {
    let label: String
    let workSets: [WorkSet]
}

struct WorkSet: Codable {
    let pctTM: Double
    let reps: Int
}

struct SessionTemplate: Codable {
    let sessionId: String
    let label: String
    let mainLiftId: String
    let supplemental: [SupplementalTemplate]
    let assistanceSlots: [AssistanceSlot]
    let circuit: CircuitTemplate
}

struct SupplementalTemplate: Codable {
    let type: String
    let label: String
    let sets: Int
    let repsRange: [Int]
}

struct AssistanceSlot: Codable {
    let slotId: String
    let minReps: Int
    let maxReps: Int
}

struct CircuitTemplate: Codable {
    let enabled: Bool
    let rounds: Int
    let style: String
}


struct GeneratedProgram {
    let weeks: [ProgramWeek]
    let startDate: Date
}

struct ProgramWeek {
    let weekNumber: Int
    let sessions: [ProgramSession]
}

struct ProgramSession {
    let sessionId: String
    let sessionName: String
    let date: Date
    let mainLift: MainLiftDetails
    let circuit: CircuitDetails
}

struct MainLiftDetails {
    let liftId: String
    let liftName: String
    let sets: [SetDetails]
}

struct CircuitDetails {
    let rounds: Int
    let exercises: [CircuitExercise]
}

struct CircuitExercise {
    let exerciseId: String
    let exerciseName: String
    let sets: [SetDetails]
}

struct SetDetails {
    let weight: Double
    let targetReps: Int
    let pctTM: Double
}

class ProgramGenerator {
    static func generateProgram(
        template: ProgramTemplate,
        strengthData: StrengthData,
        profile: Profile,
        exercises: [Exercise]
    ) -> GeneratedProgram {
        let startDate = calculateStartDate(preferredStartDay: profile.preferredStartDay)
        var weeks: [ProgramWeek] = []
        
        for weekNum in 1...template.macrocycle.cycleLengthWeeks {
            guard let phase = template.macrocycle.phases.first(where: { $0.weeks.contains(weekNum) }) else {
                continue
            }
            
            // Determine main lift scheme for this week
            let mainSchemeName: String
            if let schemeByWeek = phase.mainLiftSchemeByWeekInCycle {
                let weekInPhase = weekNum - (phase.weeks.first ?? 1) + 1
                mainSchemeName = schemeByWeek["\(weekInPhase)"] ?? phase.mainLiftScheme ?? "fives_pro_week_1"
            } else {
                mainSchemeName = phase.mainLiftScheme ?? "fives_pro_week_1"
            }
            
            guard let mainScheme = template.setSchemes[mainSchemeName] else {
                continue
            }
            
            var sessions: [ProgramSession] = []
            let sessionKeys = ["SQUAT_DAY", "BENCH_DAY", "DEADLIFT_DAY", "OHP_DAY"]
            
            for (dayOffset, sessionKey) in sessionKeys.enumerated() {
                guard let sessionTemplate = template.sessionTemplates[sessionKey] else {
                    continue
                }
                
                let sessionDate = startDate.addingTimeInterval(Double((weekNum - 1) * 7 + dayOffset) * 86400)
                
                let mainLift = generateMainLift(
                    liftId: sessionTemplate.mainLiftId,
                    scheme: mainScheme,
                    strengthData: strengthData
                )
                
                let circuit = generateCircuit(
                    sessionTemplate: sessionTemplate,
                    mainLiftId: sessionTemplate.mainLiftId,
                    mainScheme: mainScheme,
                    strengthData: strengthData,
                    exercises: exercises,
                    phaseRules: phase.rules
                )
                
                sessions.append(ProgramSession(
                    sessionId: sessionTemplate.sessionId,
                    sessionName: sessionTemplate.label,
                    date: sessionDate,
                    mainLift: mainLift,
                    circuit: circuit
                ))
            }
            
            weeks.append(ProgramWeek(weekNumber: weekNum, sessions: sessions))
        }
        
        return GeneratedProgram(weeks: weeks, startDate: startDate)
    }
    
    private static func calculateStartDate(preferredStartDay: String) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        
        let targetWeekday: Int = {
            switch preferredStartDay.lowercased() {
            case "sun": return 1
            case "mon": return 2
            case "tue": return 3
            case "wed": return 4
            case "thu": return 5
            case "fri": return 6
            case "sat": return 7
            default: return 2
            }
        }()
        
        var daysToAdd = targetWeekday - todayWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: today)!
    }
    
    private static func generateMainLift(
        liftId: String,
        scheme: SetScheme,
        strengthData: StrengthData
    ) -> MainLiftDetails {
        let tm = getTrainingMax(liftId: liftId, strengthData: strengthData)
        let liftName = liftId.capitalized
        
        let sets = scheme.workSets.map { workSet in
            let weight = round(tm * workSet.pctTM / 5) * 5
            return SetDetails(weight: weight, targetReps: workSet.reps, pctTM: workSet.pctTM)
        }
        
        return MainLiftDetails(liftId: liftId, liftName: liftName, sets: sets)
    }
    
    private static func generateCircuit(
        sessionTemplate: SessionTemplate,
        mainLiftId: String,
        mainScheme: SetScheme,
        strengthData: StrengthData,
        exercises: [Exercise],
        phaseRules: PhaseRules
    ) -> CircuitDetails {
        var circuitExercises: [CircuitExercise] = []
        let rounds = phaseRules.circuitRounds ?? sessionTemplate.circuit.rounds
        
        // Add FSL (main lift)
        if let fslSupplemental = sessionTemplate.supplemental.first(where: { $0.type == "fsl_main_lift" }) {
            let tm = getTrainingMax(liftId: mainLiftId, strengthData: strengthData)
            let firstSetPct = mainScheme.workSets.first?.pctTM ?? 0.65
            let weight = round(tm * firstSetPct / 5) * 5
            
            let sets = (0..<fslSupplemental.sets).map { _ in
                SetDetails(weight: weight, targetReps: fslSupplemental.repsRange[0], pctTM: firstSetPct)
            }
            
            circuitExercises.append(CircuitExercise(
                exerciseId: mainLiftId,
                exerciseName: mainLiftId.capitalized,
                sets: sets
            ))
        }
        
        // Add assistance exercises
        for slot in sessionTemplate.assistanceSlots {
            if let exercise = selectRandomExercise(forTag: slot.slotId, from: exercises) {
                let sets = (0..<5).map { _ in
                    SetDetails(weight: 0, targetReps: slot.minReps, pctTM: 0)
                }
                
                circuitExercises.append(CircuitExercise(
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                    sets: sets
                ))
            }
        }
        
        return CircuitDetails(rounds: rounds, exercises: circuitExercises)
    }
    
    private static func getTrainingMax(liftId: String, strengthData: StrengthData) -> Double {
        switch liftId {
        case "squat": return strengthData.trainingMaxes.squat
        case "bench": return strengthData.trainingMaxes.bench
        case "deadlift": return strengthData.trainingMaxes.deadlift
        case "ohp": return strengthData.trainingMaxes.ohp
        default: return 0
        }
    }
    
    private static func selectRandomExercise(forTag tag: String, from exercises: [Exercise]) -> Exercise? {
        let matching = exercises.filter { $0.slotTags.contains(tag) }
        return matching.randomElement()
    }
}

