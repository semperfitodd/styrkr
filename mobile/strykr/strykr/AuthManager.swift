import Foundation
import SwiftUI
import Combine
import AuthenticationServices

class AuthManager: NSObject, ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authSession: ASWebAuthenticationSession?
    
    struct User: Codable {
        let name: String
        let email: String
        let provider: String
    }
    
    override init() {
        super.init()
    }
    
    @MainActor
    func signInWithGoogle() {
        signInWithProvider("Google")
    }
    
    @MainActor
    func signInWithApple() {
        signInWithProvider("SignInWithApple")
    }
    
    @MainActor
    private func signInWithProvider(_ provider: String) {
        let cognitoDomain = Secrets.cognitoDomain
        let clientId = Secrets.cognitoClientId
        let redirectUri = Secrets.redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? Secrets.redirectUri
        
        let authURL = "https://\(cognitoDomain)/oauth2/authorize?identity_provider=\(provider)&redirect_uri=\(redirectUri)&response_type=code&client_id=\(clientId)&scope=email+openid+profile"
        
        guard let url = URL(string: authURL) else {
            self.errorMessage = "Invalid auth URL"
            return
        }
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: "styrkr") { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let callbackURL = callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to get auth code"
                }
                return
            }
            
            Task {
                await self.exchangeCodeForTokens(code: code, provider: provider)
            }
        }
        
        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }
    
    private func exchangeCodeForTokens(code: String, provider: String) async {
        let cognitoDomain = Secrets.cognitoDomain
        let clientId = Secrets.cognitoClientId
        let redirectUri = Secrets.redirectUri
        
        let tokenURL = "https://\(cognitoDomain)/oauth2/token"
        
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=authorization_code&client_id=\(clientId)&code=\(code)&redirect_uri=\(redirectUri)"
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            if let userInfo = decodeJWT(tokenResponse.id_token) {
                await MainActor.run {
                    self.user = User(
                        name: userInfo["name"] as? String ?? userInfo["email"] as? String ?? "User",
                        email: userInfo["email"] as? String ?? "",
                        provider: provider
                    )
                    self.isAuthenticated = true
                    
                    UserDefaults.standard.set(tokenResponse.access_token, forKey: "access_token")
                    UserDefaults.standard.set(tokenResponse.id_token, forKey: "id_token")
                    UserDefaults.standard.set(tokenResponse.refresh_token, forKey: "refresh_token")
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Token exchange failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func decodeJWT(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        var base64String = segments[1]
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String = base64String.padding(toLength: base64String.count + 4 - remainder, withPad: "=", startingAt: 0)
        }
        
        guard let data = Data(base64Encoded: base64String),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    @MainActor
    func signOut() {
        self.isAuthenticated = false
        self.user = nil
        
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "id_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        
        let cognitoDomain = Secrets.cognitoDomain
        let clientId = Secrets.cognitoClientId
        let logoutUri = Secrets.logoutUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? Secrets.logoutUri
        
        let logoutURL = "https://\(cognitoDomain)/logout?client_id=\(clientId)&logout_uri=\(logoutUri)"
        
        if let url = URL(string: logoutURL) {
            authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: "styrkr") { _, _ in }
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = true
            authSession?.start()
        }
    }
    
    struct TokenResponse: Codable {
        let access_token: String
        let id_token: String
        let refresh_token: String?
        let token_type: String
        let expires_in: Int
    }
}

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
