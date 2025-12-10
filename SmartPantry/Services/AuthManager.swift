import Foundation
import AuthenticationServices
import SwiftUI
import Combine

class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    private let userIdsKey = "userId"
    
    override init() {
        super.init()
        let savedId = UserDefaults.standard.string(forKey: userIdsKey) ?? ""
        self.isAuthenticated = !savedId.isEmpty
    }
    
    func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                // Persist User ID
                UserDefaults.standard.set(userId, forKey: userIdsKey)
                self.isAuthenticated = true
                print("Successfully signed in with user: \(userId)")
            }
        case .failure(let error):
            print("Sign in failed: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIdsKey)
        isAuthenticated = false
    }
}
