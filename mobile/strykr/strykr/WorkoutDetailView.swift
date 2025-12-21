import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let session: ProgramSession
    let date: Date
    @Binding var editableCircuit: EditableCircuit?
    let onComplete: () -> Void
    
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
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.sessionName)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(dateFormatter.string(from: date))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Main Lift
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Main Lift: \(session.mainLift.liftName)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(Array(session.mainLift.sets.enumerated()), id: \.offset) { index, set in
                                HStack {
                                    Text("Set \(index + 1)")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(Int(set.weight)) lb × \(set.targetReps) reps")
                                        .foregroundColor(.white)
                                    Text("(\(Int(set.pctTM * 100))% TM)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(hex: "2d2d2d"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Circuit
                        if let circuit = editableCircuit {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Circuit (\(circuit.rounds) rounds)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ForEach(Array(circuit.exercises.enumerated()), id: \.offset) { exerciseIndex, exercise in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(exercise.exerciseName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        
                                        ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                                            HStack(spacing: 15) {
                                                Text("Set \(setIndex + 1)")
                                                    .foregroundColor(.gray)
                                                    .frame(width: 50, alignment: .leading)
                                                
                                                HStack {
                                                    TextField("Weight", value: Binding(
                                                        get: { set.weight },
                                                        set: { newValue in
                                                            editableCircuit?.exercises[exerciseIndex].sets[setIndex].weight = newValue
                                                        }
                                                    ), format: .number)
                                                    .keyboardType(.decimalPad)
                                                    .padding(8)
                                                    .background(Color.white.opacity(0.1))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(6)
                                                    
                                                    Text("lb")
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Text("×")
                                                    .foregroundColor(.gray)
                                                
                                                HStack {
                                                    TextField("Reps", value: Binding(
                                                        get: { set.reps },
                                                        set: { newValue in
                                                            editableCircuit?.exercises[exerciseIndex].sets[setIndex].reps = newValue
                                                        }
                                                    ), format: .number)
                                                    .keyboardType(.numberPad)
                                                    .padding(8)
                                                    .background(Color.white.opacity(0.1))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(6)
                                                    
                                                    Text("reps")
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .font(.subheadline)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color(hex: "2d2d2d"))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Complete button
                        Button(action: {
                            onComplete()
                        }) {
                            Text("Complete Workout")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }
}

