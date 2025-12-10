import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true
    
    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen(isActive: $showSplash)
            } else if !hasSeenOnboarding {
                TutorialView(isCompleted: $hasSeenOnboarding)
            } else if !authManager.isAuthenticated {
                LoginView()
                    .environmentObject(authManager)
            } else if !subscriptionManager.isSubscribed {
                PaywallView()
                    .environmentObject(subscriptionManager)
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                InventoryListView(category: .fridge)
                    .navigationTitle("Fridge")
            }
            .tabItem {
                Label("Fridge", systemImage: "refrigerator")
            }
            
            NavigationStack {
                InventoryListView(category: .pantry)
                    .navigationTitle("Pantry")
            }
            .tabItem {
                Label("Pantry", systemImage: "cabinet")
            }
            
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife")
                }
            
            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }
        }
    }
}
