import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showProfile = false
    @State private var showExerciseLibrary = false
    @State private var userProfile: Profile?
    @State private var showQuestionnaire = false
    @State private var hasProfile: Bool?
    @State private var isCheckingProfile = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Welcome section
                        VStack(spacing: 15) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.white)
                            
                            Text("Hello, \(authManager.user?.name ?? "User")! 👋")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(authManager.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            // Provider badge
                            HStack {
                                Image(systemName: authManager.user?.provider == "google" ? "g.circle.fill" : "apple.logo")
                                Text("Signed in with \(authManager.user?.provider.capitalized ?? "")")
                            }
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        // Features
                        VStack(spacing: 20) {
                            Button(action: { showExerciseLibrary = true }) {
                                FeatureCard(
                                    icon: "book.fill",
                                    title: "Exercise Library",
                                    description: "Browse 120+ exercises for 5/3/1 Krypteia + longevity",
                                    isClickable: true
                                )
                            }
                            
                            FeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Track Your Progress",
                                description: "Log workouts and monitor your strength gains over time"
                            )
                            
                            FeatureCard(
                                icon: "target",
                                title: "Set Goals",
                                description: "Define and achieve your fitness objectives"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Sign out button
                        Button(action: {
                            authManager.signOut()
                        }) {
                            Text("Sign Out")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("Built with dedication by Todd")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("© \(Calendar.current.component(.year, from: Date())) STYRKR. All rights reserved.")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(hex: "1a1a1a"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showQuestionnaire) {
                ProfileQuestionnaireView()
            }
            .sheet(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView(userProfile: userProfile)
            }
            .task {
                await checkProfile()
            }
        }
    }
    
    func checkProfile() async {
        isCheckingProfile = true
        
        do {
            let profile = try await APIClient.shared.getProfile()
            await MainActor.run {
                self.userProfile = profile
                hasProfile = true
                isCheckingProfile = false
            }
        } catch APIError.notFound {
            await MainActor.run {
                hasProfile = false
                isCheckingProfile = false
                showQuestionnaire = true
            }
        } catch {
            await MainActor.run {
                hasProfile = nil
                isCheckingProfile = false
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    var isClickable: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(
            isClickable ?
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea").opacity(0.2), Color(hex: "764ba2").opacity(0.2)]),
                startPoint: .leading,
                endPoint: .trailing
            ) :
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isClickable ? Color(hex: "667eea").opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
}

