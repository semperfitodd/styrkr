import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and branding
                VStack(spacing: 20) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("STYRKR")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .tracking(4)
                    
                    Text("Your Ultimate Strength Training Companion")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Error Message
                if let error = authManager.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Sign in buttons
                VStack(spacing: 16) {
                    // Google Sign In Button
                    Button(action: {
                        authManager.signInWithGoogle()
                    }) {
                        HStack {
                            GoogleLogo(size: 20)
                            Text("Continue with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    
                    // Apple Sign In Button
                    Button(action: {
                        authManager.signInWithApple()
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.title2)
                            Text("Continue with Apple")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                // Terms and privacy
                Text("By continuing, you agree to STYRKR's\nTerms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}

