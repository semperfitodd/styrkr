import SwiftUI

struct ProfileQuestionnaireView: View {
    @Environment(\.dismiss) var dismiss
    @State private var profile = Profile.empty
    @State private var currentStep = 0
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let totalSteps = 2
    
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
            nonLiftingDaysStep
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
            
            Text("How many days per week will you train?")
                .foregroundColor(.gray)
            
            HStack(spacing: 10) {
                ForEach([3, 4, 5, 6], id: \.self) { days in
                    Button(action: { profile.trainingDaysPerWeek = days }) {
                        Text("\(days) days")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(profile.trainingDaysPerWeek == days ? 
                                LinearGradient(gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]), startPoint: .leading, endPoint: .trailing) : 
                                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(profile.trainingDaysPerWeek == days ? Color(hex: "667eea") : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }
            
            Text("Preferred Units")
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .padding(.top, 10)
            
            VStack(spacing: 15) {
                unitButton(unit: "lb", label: "Pounds (lb)")
                unitButton(unit: "kg", label: "Kilograms (kg)")
            }
            
            Text("Preferred Start Day")
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .padding(.top, 10)
            
            Picker("Start Day", selection: Binding(
                get: { profile.preferredStartDay },
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
            
            Toggle("Include non-lifting day programming", isOn: $profile.nonLiftingDaysEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "667eea")))
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            Text("We'll program your off-days with recovery work")
                .font(.caption)
                .foregroundColor(.gray)
            
            if profile.nonLiftingDaysEnabled {
                Text("What should non-lifting days focus on?")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                
                VStack(spacing: 15) {
                    modeButton(mode: "pilates", label: "Pilates", icon: "figure.flexibility")
                    modeButton(mode: "conditioning", label: "Conditioning", icon: "figure.run")
                    modeButton(mode: "gpp", label: "GPP (General Physical Preparedness)", icon: "figure.mixed.cardio")
                    modeButton(mode: "mobility", label: "Mobility", icon: "figure.walk")
                    modeButton(mode: "rest", label: "Rest", icon: "bed.double.fill")
                }
                
                Text("Conditioning Level")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                
                Picker("Level", selection: $profile.conditioningLevel) {
                    Text("Low").tag("low")
                    Text("Moderate").tag("moderate")
                    Text("High").tag("high")
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

