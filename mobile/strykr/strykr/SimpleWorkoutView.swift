import SwiftUI

struct SimpleWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    private let apiClient = APIClient.shared
    
    let workout: SimpleWorkout
    let date: Date
    let weekNumber: Int
    let onComplete: () -> Void
    
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
                    
                    if !workout.notes.isEmpty {
                        notesSection
                    }
                    
                    exercisesSection
                    
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
    
    private var exercisesSection: some View {
        VStack(spacing: 16) {
            ForEach(workout.exercises) { exercise in
                VStack(alignment: .leading, spacing: 12) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let sets = exercise.sets, let reps = exercise.reps {
                        Text("\(sets) sets × \(reps)")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let duration = exercise.duration {
                        Text(duration)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let notes = exercise.notes {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "2d2d2d"))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
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
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.6 : 1.0)
    }
    
    private func handleComplete() {
        isSubmitting = true
        
        let workoutLog: [String: Any] = [
            "workoutDate": ISO8601DateFormatter().string(from: date).split(separator: "T")[0],
            "programWeek": weekNumber,
            "sessionId": workout.sessionId,
            "nonLiftingDay": [
                "type": workout.label,
                "exercises": workout.exercises.map { exercise in
                    var dict: [String: Any] = ["name": exercise.name]
                    if let sets = exercise.sets { dict["sets"] = sets }
                    if let reps = exercise.reps { dict["reps"] = reps }
                    if let duration = exercise.duration { dict["duration"] = duration }
                    if let notes = exercise.notes { dict["notes"] = notes }
                    return dict
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

