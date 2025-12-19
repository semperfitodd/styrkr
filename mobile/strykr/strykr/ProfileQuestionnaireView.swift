import SwiftUI

struct ProfileQuestionnaireView: View {
    @Environment(\.dismiss) var dismiss
    @State private var profile = Profile.empty
    @State private var currentStep = 0
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var customConstraint = ""
    
    let totalSteps = 5
    
    let commonConstraints = [
        "no_lunges",
        "no_deep_knee_flexion",
        "no_overhead",
        "no_barbell_back_squat",
        "no_jumping",
        "no_running",
        "low_back_issues",
        "shoulder_issues",
        "knee_issues"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "667eea")))
                        .padding()
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            stepContent
                        }
                        .padding()
                    }
                    
                    HStack(spacing: 15) {
                        if currentStep > 0 {
                            Button(action: { currentStep -= 1 }) {
                                Text("Back")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: handleNext) {
                            Text(currentStep == totalSteps - 1 ? (isSaving ? "Saving..." : "Complete") : "Next")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(isSaving)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Setup Your Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    @ViewBuilder
    var stepContent: some View {
        switch currentStep {
        case 0:
            trainingScheduleStep
        case 1:
            unitsStep
        case 2:
            nonLiftingDaysStep
        case 3:
            constraintsStep
        case 4:
            movementCapabilitiesStep
        default:
            EmptyView()
        }
    }
    
    var trainingScheduleStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Training Schedule")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("How many days per week do you want to train?")
                .foregroundColor(.gray)
            
            Picker("Training Days", selection: $profile.trainingDaysPerWeek) {
                ForEach(3...7, id: \.self) { days in
                    Text("\(days) days").tag(days)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            
            Text("Preferred Start Day")
                .foregroundColor(.white)
                .fontWeight(.semibold)
            
            Picker("Start Day", selection: Binding(
                get: { profile.preferredStartDay ?? "mon" },
                set: { profile.preferredStartDay = $0 }
            )) {
                Text("Monday").tag("mon")
                Text("Tuesday").tag("tue")
                Text("Wednesday").tag("wed")
                Text("Thursday").tag("thu")
                Text("Friday").tag("fri")
                Text("Saturday").tag("sat")
                Text("Sunday").tag("sun")
            }
            .pickerStyle(.menu)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    var unitsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferred Units")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Choose your preferred weight units")
                .foregroundColor(.gray)
            
            VStack(spacing: 15) {
                unitButton(unit: "lb", label: "Pounds (lb)")
                unitButton(unit: "kg", label: "Kilograms (kg)")
            }
        }
    }
    
    func unitButton(unit: String, label: String) -> some View {
        Button(action: { profile.preferredUnits = unit }) {
            HStack {
                Text(label)
                    .foregroundColor(.white)
                Spacer()
                if profile.preferredUnits == unit {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "667eea"))
                }
            }
            .padding()
            .background(profile.preferredUnits == unit ? Color(hex: "667eea").opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(profile.preferredUnits == unit ? Color(hex: "667eea") : Color.clear, lineWidth: 2)
            )
        }
    }
    
    var nonLiftingDaysStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Non-Lifting Days")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Toggle("Include non-lifting days", isOn: $profile.includeNonLiftingDays)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "667eea")))
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            if profile.includeNonLiftingDays {
                Text("What would you like to do?")
                    .foregroundColor(.gray)
                
                VStack(spacing: 15) {
                    modeButton(mode: "pilates", label: "Pilates", icon: "figure.flexibility")
                    modeButton(mode: "conditioning", label: "Conditioning", icon: "figure.run")
                    modeButton(mode: "mixed", label: "Mixed", icon: "figure.mixed.cardio")
                }
                
                Text("Conditioning Level")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                
                Picker("Level", selection: $profile.conditioningLevel) {
                    Text("Light").tag("light")
                    Text("Moderate").tag("moderate")
                    Text("Intense").tag("intense")
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    func modeButton(mode: String, label: String, icon: String) -> some View {
        Button(action: { profile.nonLiftingDayMode = mode }) {
            HStack {
                Image(systemName: icon)
                Text(label)
                Spacer()
                if profile.nonLiftingDayMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "667eea"))
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(profile.nonLiftingDayMode == mode ? Color(hex: "667eea").opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(profile.nonLiftingDayMode == mode ? Color(hex: "667eea") : Color.clear, lineWidth: 2)
            )
        }
    }
    
    var constraintsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Physical Constraints")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select any limitations or injuries")
                .foregroundColor(.gray)
            
            VStack(spacing: 10) {
                ForEach(commonConstraints, id: \.self) { constraint in
                    constraintButton(constraint: constraint)
                }
            }
            
            HStack {
                TextField("Add custom constraint", text: $customConstraint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addCustomConstraint) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "667eea"))
                        .font(.title2)
                }
                .disabled(customConstraint.isEmpty)
            }
            
            if !profile.constraints.filter({ !commonConstraints.contains($0) }).isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Custom Constraints:")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    ForEach(profile.constraints.filter { !commonConstraints.contains($0) }, id: \.self) { constraint in
                        HStack {
                            Text(constraint)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { profile.constraints.removeAll { $0 == constraint } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    func constraintButton(constraint: String) -> some View {
        Button(action: { toggleConstraint(constraint) }) {
            HStack {
                Text(constraint.replacingOccurrences(of: "_", with: " ").capitalized)
                    .foregroundColor(.white)
                Spacer()
                if profile.constraints.contains(constraint) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "667eea"))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(profile.constraints.contains(constraint) ? Color(hex: "667eea").opacity(0.2) : Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    var movementCapabilitiesStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Movement Capabilities")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("What gymnastic movements can you do?")
                .foregroundColor(.gray)
            
            VStack(spacing: 15) {
                Toggle("Pull-ups", isOn: $profile.movementCapabilities.pullups)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "667eea")))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                
                Toggle("Ring Dips", isOn: $profile.movementCapabilities.ringDips)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "667eea")))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Muscle-ups")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    Picker("Muscle-ups", selection: $profile.movementCapabilities.muscleUps) {
                        Text("None").tag("none")
                        Text("Bar").tag("bar")
                        Text("Ring").tag("ring")
                        Text("Both").tag("both")
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
    
    func toggleConstraint(_ constraint: String) {
        if profile.constraints.contains(constraint) {
            profile.constraints.removeAll { $0 == constraint }
        } else {
            profile.constraints.append(constraint)
        }
    }
    
    func addCustomConstraint() {
        let trimmed = customConstraint.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !profile.constraints.contains(trimmed) {
            profile.constraints.append(trimmed)
            customConstraint = ""
        }
    }
    
    func handleNext() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        } else {
            Task {
                await saveProfile()
            }
        }
    }
    
    func saveProfile() async {
        isSaving = true
        errorMessage = nil
        
        do {
            _ = try await APIClient.shared.updateProfile(profile)
            await MainActor.run {
                dismiss()
            }
        } catch let error as APIError {
            await MainActor.run {
                errorMessage = error.errorDescription ?? "Unknown error"
                isSaving = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save profile: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

#Preview {
    ProfileQuestionnaireView()
}

