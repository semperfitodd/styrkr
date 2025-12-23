import SwiftUI

struct ProgramView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var profile: Profile?
    @State private var strengthData: StrengthData?
    @State private var program: GeneratedProgram?
    @State private var programTemplate: ProgramTemplate?
    @State private var exercises: [Exercise] = []
    @State private var completedWorkouts: Set<String> = []
    
    @State private var showingMaxInput = false
    @State private var squatMax: String = ""
    @State private var benchMax: String = ""
    @State private var deadliftMax: String = ""
    @State private var ohpMax: String = ""
    
    @State private var selectedSession: ProgramSession?
    @State private var selectedDate: Date?
    @State private var showingWorkoutDetail = false
    @State private var showingGPPWorkout = false
    @State private var showingSimpleWorkout = false
    
    @State private var editableCircuit: EditableCircuit?
    @State private var gppWorkout: GPPWorkout?
    @State private var simpleWorkout: SimpleWorkout?
    @State private var workoutGenerator: WorkoutGenerator?
    @State private var exerciseLibrary: ExerciseLibrary?
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var daySwaps: [String: [String: Any]] = [:]
    @State private var showingResetAlert = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading...")
                        .foregroundColor(.white)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.white)
                        Text(errorMessage)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadData() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                } else if showingMaxInput {
                    maxInputView
                } else if let program = program {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("12-Week Training Program")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.top)
                            
                            ProgramCalendarView(
                                program: program,
                                completedWorkouts: completedWorkouts,
                                onDaySelected: handleDaySelected,
                                daySwaps: $daySwaps,
                                onSwapUpdate: handleSwapUpdate
                            )
                            .padding()
                            
                            if !daySwaps.isEmpty {
                                Button(action: { showingResetAlert = true }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Reset Schedule")
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(10)
                                }
                                .padding(.bottom)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                if strengthData != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Update Maxes") {
                            showingMaxInput = true
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingWorkoutDetail) {
                if let session = selectedSession, let date = selectedDate {
                    NavigationView {
                        WorkoutDetailView(
                            session: session,
                            date: date,
                            editableCircuit: $editableCircuit,
                            onComplete: handleCompleteWorkout
                        )
                    }
                    .navigationViewStyle(.stack)
                }
            }
            .sheet(isPresented: $showingGPPWorkout) {
                if let workout = gppWorkout, let date = selectedDate, let program = program {
                    NavigationView {
                        GPPWorkoutView(
                            workout: workout,
                            date: date,
                            weekNumber: weekNumberForDate(date, program: program),
                            onComplete: handleCompleteWorkout
                        )
                    }
                    .navigationViewStyle(.stack)
                }
            }
            .sheet(isPresented: $showingSimpleWorkout) {
                if let workout = simpleWorkout, let date = selectedDate, let program = program {
                    NavigationView {
                        SimpleWorkoutView(
                            workout: workout,
                            date: date,
                            weekNumber: weekNumberForDate(date, program: program),
                            onComplete: handleCompleteWorkout
                        )
                    }
                    .navigationViewStyle(.stack)
                }
            }
        }
        .task {
            await loadData()
        }
        .alert("Reset Schedule", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task { await resetSchedule() }
            }
        } message: {
            Text("This will reset all day swaps and restore the original schedule.")
        }
    }
    
    private var maxInputView: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Enter Your 1-Rep Maxes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                VStack(spacing: 20) {
                    MaxInputCard(title: "Squat", value: $squatMax, unit: "lb")
                    MaxInputCard(title: "Bench Press", value: $benchMax, unit: "lb")
                    MaxInputCard(title: "Deadlift", value: $deadliftMax, unit: "lb")
                    MaxInputCard(title: "Overhead Press", value: $ohpMax, unit: "lb")
                }
                .padding(.horizontal)
                
                Button(action: saveStrengthData) {
                    Text("Generate Program")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "667eea"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom, 40)
        }
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            profile = try await APIClient.shared.getProfile()
            
            if let url = Bundle.main.url(forResource: "exercises.latest", withExtension: "json") {
                let data = try Data(contentsOf: url)
                let library = try JSONDecoder().decode(ExerciseLibrary.self, from: data)
                exercises = library.exercises
                exerciseLibrary = library
                workoutGenerator = WorkoutGenerator(exerciseLibrary: library)
            }
            
            if let url = Bundle.main.url(forResource: "plan.template", withExtension: "json") {
                let data = try Data(contentsOf: url)
                programTemplate = try JSONDecoder().decode(ProgramTemplate.self, from: data)
            }
            
            do {
                strengthData = try await APIClient.shared.getStrength()
                
                if let strength = strengthData, let profile = profile, let template = programTemplate {
                    program = ProgramGenerator.generateProgram(
                        template: template,
                        strengthData: strength,
                        profile: profile,
                        exercises: exercises
                    )
                    
                    await loadWorkoutHistory()
                    await loadScheduleCustomizations()
                }
                
                await MainActor.run {
                    showingMaxInput = false
                    isLoading = false
                }
            } catch APIError.notFound {
                await MainActor.run {
                    showingMaxInput = true
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func loadWorkoutHistory() async {
        guard let program = program else { return }
        
        let startDate = dateFormatter.string(from: program.startDate)
        let endDate = dateFormatter.string(from: program.weeks.last?.sessions.last?.date ?? Date())
        
        do {
            let response = try await APIClient.shared.getWorkouts(startDate: startDate, endDate: endDate)
            await MainActor.run {
                completedWorkouts = Set(response.workouts.map { $0.workoutDate })
            }
        } catch {
            return
        }
    }
    
    private func saveStrengthData() {
        guard let squat = Double(squatMax),
              let bench = Double(benchMax),
              let deadlift = Double(deadliftMax),
              let ohp = Double(ohpMax) else {
            return
        }
        
        let oneRepMaxes = OneRepMaxes(squat: squat, bench: bench, deadlift: deadlift, ohp: ohp)
        let tmPolicy = TMPolicy(percent: 0.9, rounding: "5lb")
        let trainingMaxes = TrainingMaxes(
            squat: squat * 0.9,
            bench: bench * 0.9,
            deadlift: deadlift * 0.9,
            ohp: ohp * 0.9
        )
        
        let newStrengthData = StrengthData(
            oneRepMaxes: oneRepMaxes,
            tmPolicy: tmPolicy,
            trainingMaxes: trainingMaxes,
            history: nil
        )
        
        Task {
            do {
                strengthData = try await APIClient.shared.updateStrength(newStrengthData)
                await loadData()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save strength data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleDaySelected(date: Date, session: ProgramSession?) {
        selectedDate = date
        selectedSession = session
        
        guard let profile = profile, let program = program else { return }
        
        if let session = session {
            editableCircuit = EditableCircuit(from: session.circuit)
            showingWorkoutDetail = true
        } else {
            let dayOfWeek = Calendar.current.component(.weekday, from: date) - 1
            let weekNumber = weekNumberForDate(date, program: program)
            let weekPhase = getWeekPhase(weekNumber: weekNumber)
            
            if let nonLiftingType = getNonLiftingDayType(dayOfWeek: dayOfWeek, profile: profile) {
                generateNonLiftingWorkout(type: nonLiftingType, profile: profile, weekPhase: weekPhase)
            }
        }
    }
    
    private func getNonLiftingDayType(dayOfWeek: Int, profile: Profile) -> DayType? {
        let trainingDays = profile.trainingDaysPerWeek
        let preferredMode = profile.nonLiftingDayMode
        
        let mainDays: Set<Int> = [1, 2, 4, 5]
        
        if mainDays.contains(dayOfWeek) {
            return nil
        }
        
        if trainingDays >= 5 && dayOfWeek == 3 {
            return DayType(rawValue: preferredMode) ?? .gpp
        }
        
        if trainingDays >= 6 && dayOfWeek == 6 {
            return DayType(rawValue: preferredMode) ?? .gpp
        }
        
        if trainingDays >= 7 && dayOfWeek == 0 {
            return DayType(rawValue: preferredMode) ?? .gpp
        }
        
        return nil
    }
    
    private func generateNonLiftingWorkout(type: DayType, profile: Profile, weekPhase: String) {
        guard let generator = workoutGenerator else { return }
        
        switch type {
        case .gpp:
            gppWorkout = generator.generateGPPWorkout(options: WorkoutOptions(profile: profile, weekPhase: weekPhase))
            showingGPPWorkout = true
        case .mobility:
            simpleWorkout = generator.generateMobilityWorkout(options: WorkoutOptions(profile: profile, weekPhase: weekPhase))
            showingSimpleWorkout = true
        case .rest:
            simpleWorkout = generator.generateActiveRecoveryWorkout(options: WorkoutOptions(profile: profile, weekPhase: weekPhase))
            showingSimpleWorkout = true
        case .pilates:
            simpleWorkout = generator.generatePilatesWorkout()
            showingSimpleWorkout = true
        case .main:
            break
        }
    }
    
    private func weekNumberForDate(_ date: Date, program: GeneratedProgram) -> Int {
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: program.startDate, to: date).day ?? 0
        return (daysDiff / 7) + 1
    }
    
    private func getWeekPhase(weekNumber: Int) -> String {
        let weekInCycle = ((weekNumber - 1) % 12) + 1
        
        if weekInCycle <= 3 {
            return "LEADER"
        } else if weekInCycle == 4 {
            return "DELOAD"
        } else if weekInCycle <= 6 {
            return "ANCHOR"
        } else if weekInCycle == 7 {
            return "TEST"
        } else if weekInCycle == 8 {
            return "RESET"
        } else if weekInCycle <= 11 {
            return "LEADER"
        } else {
            return "DELOAD"
        }
    }
    
    private func handleCompleteWorkout() {
        guard let session = selectedSession,
              let date = selectedDate,
              let circuit = editableCircuit else {
            return
        }
        
        let mainLift = MainLift(
            liftId: session.mainLift.liftId,
            sets: session.mainLift.sets.map { set in
                WorkoutSet(weight: set.weight, reps: set.targetReps, pctTM: set.pctTM, targetReps: set.targetReps)
            }
        )
        
        let circuitData = Circuit(
            rounds: circuit.rounds,
            sets: circuit.exercises.map { exercise in
                CircuitSet(
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    sets: exercise.sets.map { set in
                        WorkoutSet(weight: set.weight, reps: set.reps, pctTM: nil, targetReps: nil)
                    }
                )
            }
        )
        
        let workout = WorkoutData(
            workoutDate: dateFormatter.string(from: date),
            programWeek: program?.weeks.first(where: { week in
                week.sessions.contains(where: { $0.sessionId == session.sessionId })
            })?.weekNumber ?? 1,
            sessionId: session.sessionId,
            mainLift: mainLift,
            circuit: circuitData
        )
        
        Task {
            do {
                _ = try await APIClient.shared.logWorkout(workout)
                await loadWorkoutHistory()
                await MainActor.run {
                    showingWorkoutDetail = false
                }
            } catch {
                return
            }
        }
    }
    
    private func loadScheduleCustomizations() async {
        do {
            let customizations = try await APIClient.shared.getScheduleCustomizations()
            await MainActor.run {
                if let swaps = customizations["daySwaps"] as? [String: [String: Any]] {
                    daySwaps = swaps
                }
            }
        } catch {
            return
        }
    }
    
    private func handleSwapUpdate(_ newSwaps: [String: [String: Any]]) {
        Task {
            do {
                try await APIClient.shared.updateScheduleCustomizations(["daySwaps": newSwaps])
            } catch {
                print("Error saving schedule customizations: \(error)")
            }
        }
    }
    
    private func resetSchedule() async {
        do {
            try await APIClient.shared.updateScheduleCustomizations(["daySwaps": [:]])
            await MainActor.run {
                daySwaps = [:]
            }
        } catch {
            print("Error resetting schedule: \(error)")
        }
    }
}

struct MaxInputCard: View {
    let title: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                TextField("Enter max", text: $value)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Text(unit)
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
            }
        }
        .padding()
        .background(Color(hex: "2d2d2d"))
        .cornerRadius(12)
    }
}

struct EditableCircuit {
    var rounds: Int
    var exercises: [EditableCircuitExercise]
    
    init(from circuit: CircuitDetails) {
        self.rounds = circuit.rounds
        self.exercises = circuit.exercises.map { exercise in
            EditableCircuitExercise(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                sets: exercise.sets.map { set in
                    EditableSet(weight: set.weight, reps: set.targetReps)
                }
            )
        }
    }
}

struct EditableCircuitExercise {
    let exerciseId: String
    let exerciseName: String
    var sets: [EditableSet]
}

struct EditableSet {
    var weight: Double
    var reps: Int
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color(hex: "667eea"))
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

