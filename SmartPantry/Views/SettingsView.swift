import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var notificationsEnabled = true
    
    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    VStack(alignment: .leading) {
                        Text("User")
                            .font(.headline)
                        Text("Signed in with Apple")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
                
                Button(action: {
                    authManager.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundStyle(.red)
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(.blue)
                    Text("iCloud Sync")
                    Spacer()
                    Text("On")
                        .foregroundStyle(.secondary)
                }
                
                Button(action: {
                    // Start Share Flow
                    let text = "Hey! I'm using SmartPantry to track my food. You should try it too!"
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                        rootVC.present(activityVC, animated: true)
                    }
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.purple)
                        Text("Share Inventory")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Family & Data")
            } footer: {
                Text("Invite friends to use the app. (Real-time collaborative sharing requires iCloud acceptance).")
            }
            
            Section("Preferences") {
                Toggle("Notifications", isOn: $notificationsEnabled)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("StockUpPantry Team")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .background(Color(UIColor.systemGroupedBackground))
    }
}
