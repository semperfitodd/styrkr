import SwiftUI

struct GPPCircuitSet: Identifiable {
    let id = UUID()
    var round: Int
    var slotIdx: Int
    var exerciseId: String
    var exerciseName: String
    var weight: Double
    var reps: Int
    var targetReps: String
}

struct GPPWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    private let apiClient = APIClient.shared
    
    let workout: GPPWorkout
    let date: Date
    let weekNumber: Int
    let onComplete: () -> Void
    
    @State private var selectedExercises: [Int: String] = [:]
    @State private var circuitData: [GPPCircuitSet] = []
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(workout.label)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(dateFormatter.string(from: date))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    conditioningSection
                    
                    notesSection
                    
                    exerciseSelectionSection
                    
                    if !selectedExercises.isEmpty && selectedExercises.count == workout.circuit.slots.count {
                        roundsLoggingSection
                    }
                    
                    completeButton
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var conditioningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conditioning - \(workout.conditioning.modality.capitalized)")
                .font(.headline)
                .foregroundColor(Color(hex: "60a5fa"))
            
            Text(workout.conditioning.description)
                .foregroundColor(.white)
            
            Text("Target RPE: \(workout.conditioning.targetRPE)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "60a5fa"))
        }
        .padding()
        .background(Color(hex: "1e3a8a").opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "60a5fa"), lineWidth: 2)
        )
        .padding(.horizontal)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(workout.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(Color(hex: "60a5fa"))
                    Text(note)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(hex: "1e3a8a").opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var exerciseSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Circuit - \(workout.circuit.rounds) Rounds")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                ForEach(Array(workout.circuit.slots.enumerated()), id: \.offset) { index, slot in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(slot.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Menu {
                            ForEach(slot.exercises) { exercise in
                                Button(exercise.name) {
                                    selectExercise(slotIndex: index, exerciseId: exercise.id, exerciseName: exercise.name, slot: slot)
                                }
                            }
                        } label: {
                            HStack {
                                if let exerciseId = selectedExercises[index],
                                   let exercise = slot.exercises.first(where: { $0.id == exerciseId }) {
                                    Text(exercise.name)
                                        .foregroundColor(.white)
                                } else {
                                    Text("Select \(slot.label)...")
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Text("Target: \(slot.targetReps)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
            }
            .padding()
            .background(Color(hex: "2d2d2d"))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var roundsLoggingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(1...workout.circuit.rounds, id: \.self) { round in
                VStack(alignment: .leading, spacing: 12) {
                    Text("Round \(round)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(Array(workout.circuit.slots.enumerated()), id: \.offset) { slotIdx, slot in
                        if let exerciseId = selectedExercises[slotIdx],
                           let exercise = slot.exercises.first(where: { $0.id == exerciseId }) {
                            
                            let setData = circuitData.first { $0.round == round && $0.slotIdx == slotIdx }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(exercise.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Weight")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .textCase(.uppercase)
                                        
                                        TextField("0", value: Binding(
                                            get: { setData?.weight ?? 0 },
                                            set: { newValue in
                                                updateSet(round: round, slotIdx: slotIdx, field: "weight", value: newValue)
                                            }
                                        ), format: .number)
                                        .keyboardType(.decimalPad)
                                        .padding(8)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                        .frame(width: 80)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Reps")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .textCase(.uppercase)
                                        
                                        TextField("0", value: Binding(
                                            get: { setData?.reps ?? 0 },
                                            set: { newValue in
                                                updateSet(round: round, slotIdx: slotIdx, field: "reps", value: Double(newValue))
                                            }
                                        ), format: .number)
                                        .keyboardType(.numberPad)
                                        .padding(8)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                        .frame(width: 80)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(hex: "2d2d2d"))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    private var completeButton: some View {
        Button(action: handleComplete) {
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("Complete Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color(hex: "60a5fa"))
        .cornerRadius(12)
        .padding(.horizontal)
        .disabled(isSubmitting || circuitData.isEmpty)
        .opacity((isSubmitting || circuitData.isEmpty) ? 0.6 : 1.0)
    }
    
    private func selectExercise(slotIndex: Int, exerciseId: String, exerciseName: String, slot: GPPCircuitSlot) {
        selectedExercises[slotIndex] = exerciseId
        
        circuitData.removeAll { $0.slotIdx == slotIndex }
        
        for round in 1...workout.circuit.rounds {
            circuitData.append(GPPCircuitSet(
                round: round,
                slotIdx: slotIndex,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                weight: 0,
                reps: 0,
                targetReps: slot.targetReps
            ))
        }
        
        circuitData.sort { first, second in
            if first.round != second.round {
                return first.round < second.round
            }
            return first.slotIdx < second.slotIdx
        }
    }
    
    private func updateSet(round: Int, slotIdx: Int, field: String, value: Double) {
        if let index = circuitData.firstIndex(where: { $0.round == round && $0.slotIdx == slotIdx }) {
            if field == "weight" {
                circuitData[index].weight = value
            } else if field == "reps" {
                circuitData[index].reps = Int(value)
            }
        }
    }
    
    private func handleComplete() {
        guard !circuitData.isEmpty else { return }
        
        isSubmitting = true
        
        let workoutLog: [String: Any] = [
            "workoutDate": ISO8601DateFormatter().string(from: date).split(separator: "T")[0],
            "programWeek": weekNumber,
            "sessionId": workout.sessionId,
            "gppCircuit": [
                "type": workout.label,
                "rounds": workout.circuit.rounds,
                "conditioning": [
                    "modality": workout.conditioning.modality,
                    "type": workout.conditioning.type,
                    "durationMin": workout.conditioning.durationMin as Any,
                    "work": workout.conditioning.work as Any,
                    "rest": workout.conditioning.rest as Any,
                    "rounds": workout.conditioning.rounds as Any,
                    "targetRPE": workout.conditioning.targetRPE,
                    "description": workout.conditioning.description
                ],
                "sets": circuitData.map { set in
                    [
                        "round": set.round,
                        "slotIdx": set.slotIdx,
                        "exerciseId": set.exerciseId,
                        "exerciseName": set.exerciseName,
                        "weight": set.weight,
                        "reps": set.reps,
                        "targetReps": set.targetReps
                    ]
                }
            ]
        ]
        
        Task {
            do {
                try await apiClient.logWorkout(workoutLog)
                await MainActor.run {
                    isSubmitting = false
                    onComplete()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

