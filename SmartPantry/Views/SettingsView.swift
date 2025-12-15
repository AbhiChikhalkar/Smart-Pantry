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
