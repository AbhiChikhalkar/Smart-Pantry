import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color.accentColor)
            
            Text("Welcome to SmartPantry")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Sign in to sync your pantry and access premium features.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    authManager.handleSignIn(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding()
        }
        .padding()
    }
}
