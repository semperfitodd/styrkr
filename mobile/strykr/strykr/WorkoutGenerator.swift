import Foundation

enum DayType: String, Codable {
    case main
    case gpp
    case mobility
    case pilates
    case rest
}

struct WorkoutOptions {
    let conditioningLevel: String
    let constraints: [String]
    let equipment: [String]
    let weekPhase: String
    let durationTarget: Int
    
    init(profile: Profile, weekPhase: String = "LEADER", durationTarget: Int = 30) {
        self.conditioningLevel = profile.conditioningLevel
        self.constraints = []
        self.equipment = ["bike", "rower", "jumprope", "kb", "db", "medball"]
        self.weekPhase = weekPhase
        self.durationTarget = durationTarget
    }
}

struct ConditioningPrescription {
    let type: String
    let durationMin: Int?
    let work: String?
    let rest: String?
    let rounds: Int?
    let targetRPE: Int
    let description: String
}

struct GPPCircuitSlot: Codable, Identifiable {
    let id = UUID()
    let slotId: String
    let label: String
    let exercises: [ExerciseOption]
    let targetReps: String
    
    enum CodingKeys: String, CodingKey {
        case slotId, label, exercises, targetReps
    }
}

struct ExerciseOption: Codable, Identifiable {
    let id: String
    let name: String
    let notes: String?
}

struct GPPCircuit: Codable {
    let rounds: Int
    let slots: [GPPCircuitSlot]
}

struct GPPWorkout: Codable {
    let sessionId: String
    let label: String
    let type: String
    let durationMin: Int
    let isInteractive: Bool
    let conditioning: ConditioningBlock
    let circuit: GPPCircuit
    let notes: [String]
}

struct ConditioningBlock: Codable {
    let modality: String
    let type: String
    let durationMin: Int?
    let work: String?
    let rest: String?
    let rounds: Int?
    let targetRPE: Int
    let description: String
}

struct SimpleWorkout: Codable {
    let sessionId: String
    let label: String
    let type: String
    let durationMin: Int?
    let exercises: [SimpleExercise]
    let notes: [String]
}

struct SimpleExercise: Codable, Identifiable {
    let id = UUID()
    let name: String
    let sets: Int?
    let reps: String?
    let duration: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case name, sets, reps, duration, notes
    }
}

class WorkoutGenerator {
    private let exerciseLibrary: ExerciseLibrary
    
    init(exerciseLibrary: ExerciseLibrary) {
        self.exerciseLibrary = exerciseLibrary
    }
    
    private func shouldDowngradeIntensity(_ weekPhase: String) -> Bool {
        return weekPhase == "DELOAD" || weekPhase == "TEST"
    }
    
    private func selectConditioning(constraints: [String], equipment: [String]) -> String {
        var available: [String] = []
        
        if !constraints.contains("no_running") {
            available.append("run")
        }
        
        if equipment.contains("bike") {
            available.append("bike")
        }
        
        if equipment.contains("rower") {
            available.append("rower")
        }
        
        if equipment.contains("jumprope") && !constraints.contains("knee_issue") {
            available.append("jump_rope")
        }
        
        return available.isEmpty ? "bike" : available.randomElement()!
    }
    
    private func getConditioningPrescription(conditioningLevel: String, weekPhase: String) -> ConditioningPrescription {
        if shouldDowngradeIntensity(weekPhase) {
            return ConditioningPrescription(
                type: "zone2",
                durationMin: 25,
                work: nil,
                rest: nil,
                rounds: nil,
                targetRPE: 5,
                description: "Zone 2 steady pace"
            )
        }
        
        switch conditioningLevel {
        case "low":
            return ConditioningPrescription(
                type: "zone2",
                durationMin: 30,
                work: nil,
                rest: nil,
                rounds: nil,
                targetRPE: 5,
                description: "Zone 2 steady pace"
            )
        case "high":
            return ConditioningPrescription(
                type: "intervals",
                durationMin: nil,
                work: "0:30",
                rest: "0:30",
                rounds: 8,
                targetRPE: 9,
                description: "8 rounds: 30s hard / 30s easy"
            )
        default:
            return ConditioningPrescription(
                type: "intervals",
                durationMin: nil,
                work: "0:20",
                rest: "0:40",
                rounds: 10,
                targetRPE: 8,
                description: "10 rounds: 20s hard / 40s easy"
            )
        }
    }
    
    func generateGPPWorkout(options: WorkoutOptions) -> GPPWorkout {
        let modality = selectConditioning(constraints: options.constraints, equipment: options.equipment)
        let prescription = getConditioningPrescription(conditioningLevel: options.conditioningLevel, weekPhase: options.weekPhase)
        
        let carries = exerciseLibrary.exercises.filter { $0.slotTags.contains("carry") }
        let coreExercises = exerciseLibrary.exercises.filter {
            $0.slotTags.contains("core_anti_rotation") ||
            $0.slotTags.contains("core_anti_extension")
        }
        let singleLegExercises = exerciseLibrary.exercises.filter {
            $0.slotTags.contains("single_leg") ||
            $0.slotTags.contains("single_leg_hinge")
        }
        
        let rounds = shouldDowngradeIntensity(options.weekPhase) ? 3 : (options.conditioningLevel == "high" ? 5 : 4)
        
        let conditioning = ConditioningBlock(
            modality: modality,
            type: prescription.type,
            durationMin: prescription.durationMin,
            work: prescription.work,
            rest: prescription.rest,
            rounds: prescription.rounds,
            targetRPE: prescription.targetRPE,
            description: prescription.description
        )
        
        let circuit = GPPCircuit(
            rounds: rounds,
            slots: [
                GPPCircuitSlot(
                    slotId: "carry",
                    label: "Carry",
                    exercises: carries.map { ExerciseOption(id: $0.id, name: $0.name, notes: $0.notes) },
                    targetReps: "40-60m"
                ),
                GPPCircuitSlot(
                    slotId: "single_leg",
                    label: "Single Leg Movement",
                    exercises: singleLegExercises.map { ExerciseOption(id: $0.id, name: $0.name, notes: $0.notes) },
                    targetReps: "8-12/side"
                ),
                GPPCircuitSlot(
                    slotId: "core",
                    label: "Core Movement",
                    exercises: coreExercises.map { ExerciseOption(id: $0.id, name: $0.name, notes: $0.notes) },
                    targetReps: "10-15"
                )
            ]
        )
        
        return GPPWorkout(
            sessionId: "GPP",
            label: "GPP / Krypteia",
            type: "gpp",
            durationMin: options.durationTarget,
            isInteractive: true,
            conditioning: conditioning,
            circuit: circuit,
            notes: [
                "Krypteia-style GPP work",
                "Select exercises for each slot",
                "Complete all rounds with minimal rest",
                "Total workout: \(options.durationTarget) minutes"
            ]
        )
    }
    
    func generateMobilityWorkout(options: WorkoutOptions) -> SimpleWorkout {
        let hipIRER = exerciseLibrary.exercises.filter { $0.slotTags.contains("mobility_hips_ir_er") }
        let hipFlexors = exerciseLibrary.exercises.filter { $0.slotTags.contains("mobility_hip_flexors") }
        let ankles = exerciseLibrary.exercises.filter { $0.slotTags.contains("mobility_ankles") }
        let tSpine = exerciseLibrary.exercises.filter { $0.slotTags.contains("mobility_t_spine") }
        let shoulders = exerciseLibrary.exercises.filter { $0.slotTags.contains("mobility_shoulders") }
        
        let selectedHip = (hipIRER + hipFlexors).randomElement()
        let selectedAnkle = ankles.randomElement()
        let selectedTSpine = tSpine.randomElement()
        let selectedShoulder = shoulders.randomElement()
        
        var exercises: [SimpleExercise] = []
        
        exercises.append(SimpleExercise(
            name: "90/90 Hip Assessment",
            sets: nil,
            reps: "Hold as long as possible each side",
            duration: nil,
            notes: "Record your time - track progress"
        ))
        
        exercises.append(SimpleExercise(
            name: selectedHip?.name ?? "90/90 Hip Stretch",
            sets: 2,
            reps: "60s each side + 10 transitions",
            duration: nil,
            notes: selectedHip?.notes ?? "Focus on hip internal/external rotation"
        ))
        
        var secondaryOptions: [SimpleExercise] = []
        
        if !options.constraints.contains("knee_issue") {
            secondaryOptions.append(SimpleExercise(
                name: selectedAnkle?.name ?? "Ankle Rocks",
                sets: 2,
                reps: "60s each side + 10 reps",
                duration: nil,
                notes: selectedAnkle?.notes ?? "Push knee forward over toes"
            ))
        }
        
        secondaryOptions.append(SimpleExercise(
            name: selectedTSpine?.name ?? "Thoracic Rotations",
            sets: 2,
            reps: "10-15 each side",
            duration: nil,
            notes: selectedTSpine?.notes ?? "Rotate from mid-back, not lower back"
        ))
        
        if !options.constraints.contains("shoulder_issue") {
            secondaryOptions.append(SimpleExercise(
                name: selectedShoulder?.name ?? "Wall Slides",
                sets: 2,
                reps: "10-15",
                duration: nil,
                notes: selectedShoulder?.notes ?? "Keep back flat against wall"
            ))
        }
        
        if let secondary = secondaryOptions.randomElement() {
            exercises.append(secondary)
        }
        
        return SimpleWorkout(
            sessionId: "MOBILITY",
            label: "Mobility",
            type: "mobility",
            durationMin: options.durationTarget,
            exercises: exercises,
            notes: [
                "Move slowly and controlled",
                "Focus on end ranges of motion",
                "Record assessment times to track progress",
                "Total workout: \(options.durationTarget) minutes"
            ]
        )
    }
    
    func generateActiveRecoveryWorkout(options: WorkoutOptions) -> SimpleWorkout {
        let modality = selectConditioning(constraints: options.constraints, equipment: options.equipment)
        let zone2Duration = shouldDowngradeIntensity(options.weekPhase) ? 20 : 25
        
        let hipMobility = exerciseLibrary.exercises.filter { $0.slotTags.contains("mobility_hips_ir_er") }
        let tSpine = exerciseLibrary.exercises.filter { $0.slotTags.contains("mobility_t_spine") }
        
        let selectedHip = hipMobility.randomElement()
        let selectedTSpine = tSpine.randomElement()
        
        let exercises = [
            SimpleExercise(
                name: "Zone 2 \(modality.capitalized)",
                sets: nil,
                reps: nil,
                duration: "\(zone2Duration) min",
                notes: "Easy conversational pace. RPE 4-6. Keep heart rate low"
            ),
            SimpleExercise(
                name: selectedHip?.name ?? "Hip Mobility",
                sets: nil,
                reps: nil,
                duration: "5 min",
                notes: selectedHip?.notes ?? "Focus on hip internal/external rotation"
            ),
            SimpleExercise(
                name: selectedTSpine?.name ?? "T-Spine Mobility",
                sets: nil,
                reps: nil,
                duration: "3 min",
                notes: selectedTSpine?.notes ?? "Gentle rotations"
            ),
            SimpleExercise(
                name: "Static Stretching",
                sets: nil,
                reps: nil,
                duration: "5-10 min",
                notes: "Major muscle groups. Hold each stretch 30-60s"
            )
        ]
        
        return SimpleWorkout(
            sessionId: "REST",
            label: "Active Recovery",
            type: "rest",
            durationMin: options.durationTarget,
            exercises: exercises,
            notes: [
                "Keep intensity very low",
                "Focus on recovery and blood flow",
                "No intervals, no heavy work",
                "Optional: sauna, ice bath, or massage"
            ]
        )
    }
    
    func generatePilatesWorkout() -> SimpleWorkout {
        return SimpleWorkout(
            sessionId: "PILATES",
            label: "Pilates",
            type: "pilates",
            durationMin: nil,
            exercises: [
                SimpleExercise(
                    name: "Pilates Session",
                    sets: nil,
                    reps: nil,
                    duration: nil,
                    notes: "Complete your Pilates routine"
                )
            ],
            notes: [
                "Complete your Pilates routine",
                "Focus on breath and core engagement",
                "Quality over quantity"
            ]
        )
    }
    
    func generateWorkout(type: DayType, profile: Profile, weekPhase: String = "LEADER") -> Any {
        let options = WorkoutOptions(profile: profile, weekPhase: weekPhase)
        
        switch type {
        case .gpp:
            return generateGPPWorkout(options: options)
        case .mobility:
            return generateMobilityWorkout(options: options)
        case .rest:
            return generateActiveRecoveryWorkout(options: options)
        case .pilates:
            return generatePilatesWorkout()
        case .main:
            fatalError("Main lifting days should not use this generator")
        }
    }
}

