import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var profile: Profile?
    @State private var editedProfile: Profile?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var isEditing = false
    @State private var errorMessage: String?
    
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
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Button("Close") { dismiss() }
                            .foregroundColor(Color(hex: "667eea"))
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 30) {
                            if isEditing {
                                editContent
                            } else {
                                viewContent
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        HStack {
                            Button("Cancel") {
                                isEditing = false
                                editedProfile = profile
                            }
                            .foregroundColor(.gray)
                            
                            Button(isSaving ? "Saving..." : "Save") {
                                Task { await saveProfile() }
                            }
                            .foregroundColor(Color(hex: "11998e"))
                            .disabled(isSaving)
                        }
                    } else {
                        Button(action: {
                            isEditing = true
                            editedProfile = profile
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .foregroundColor(Color(hex: "667eea"))
                        }
                    }
                }
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    @ViewBuilder
    var viewContent: some View {
        if let profile = profile {
            VStack(spacing: 25) {
                profileSection(title: "Training Schedule") {
                    infoRow(label: "Training Days/Week", value: "\(profile.trainingDaysPerWeek) days")
                    infoRow(label: "Preferred Units", value: profile.preferredUnits.uppercased())
                    infoRow(label: "Start Day", value: profile.preferredStartDay.capitalized)
                }
                
                profileSection(title: "Non-Lifting Days") {
                    infoRow(label: "Include Non-Lifting Days", value: profile.nonLiftingDaysEnabled ? "Yes" : "No")
                    if profile.nonLiftingDaysEnabled {
                        infoRow(label: "Mode", value: profile.nonLiftingDayMode.capitalized)
                        infoRow(label: "Conditioning Level", value: profile.conditioningLevel.capitalized)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var editContent: some View {
        if let profile = Binding($editedProfile) {
            VStack(spacing: 25) {
                profileSection(title: "Training Schedule") {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Training Days/Week")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Picker("Days", selection: profile.trainingDaysPerWeek) {
                            ForEach(3...6, id: \.self) { days in
                                Text("\(days) days").tag(days)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Preferred Units")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Picker("Units", selection: profile.preferredUnits) {
                            Text("LB").tag("lb")
                            Text("KG").tag("kg")
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Preferred Start Day")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Picker("Start Day", selection: Binding(
                            get: { profile.wrappedValue.preferredStartDay },
                            set: { profile.wrappedValue.preferredStartDay = $0 }
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
                
                profileSection(title: "Non-Lifting Days") {
                    VStack(alignment: .leading, spacing: 15) {
                        Toggle("Include Non-Lifting Days", isOn: profile.nonLiftingDaysEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "667eea")))
                            .foregroundColor(.white)
                        
                        if profile.wrappedValue.nonLiftingDaysEnabled {
                            Text("Mode")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Picker("Mode", selection: profile.nonLiftingDayMode) {
                                Text("Pilates").tag("pilates")
                                Text("Conditioning").tag("conditioning")
                                Text("GPP").tag("gpp")
                                Text("Mobility").tag("mobility")
                                Text("Rest").tag("rest")
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            
                            Text("Conditioning Level")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Picker("Level", selection: profile.conditioningLevel) {
                                Text("Low").tag("low")
                                Text("Moderate").tag("moderate")
                                Text("High").tag("high")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
            }
        }
    }
    
    func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
    
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedProfile = try await APIClient.shared.getProfile()
            await MainActor.run {
                self.profile = loadedProfile
                self.editedProfile = loadedProfile
                self.isLoading = false
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription ?? "Unknown error"
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func saveProfile() async {
        guard let profileToSave = editedProfile else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let savedProfile = try await APIClient.shared.updateProfile(profileToSave)
            await MainActor.run {
                self.profile = savedProfile
                self.editedProfile = savedProfile
                self.isEditing = false
                self.isSaving = false
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription ?? "Unknown error"
                self.isSaving = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                self.isSaving = false
            }
        }
    }
}

#Preview {
    ProfileView()
}

