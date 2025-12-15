import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true
    
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen(isActive: $showSplash)
            } else if !authManager.isAuthenticated {
                LoginView()
                    .environmentObject(authManager)
            } else if !hasSeenOnboarding {
                TutorialView(isCompleted:  $hasSeenOnboarding)
            } else {
                MainTabView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Overview", systemImage: "square.grid.2x2")
                }
                .tag(0)

            NavigationStack {
                InventoryListView(category: .fridge)
                    .navigationTitle("Fridge")
            }
            .tabItem {
                Label("Fridge", systemImage: "refrigerator")
            }
            .tag(1)
            
            NavigationStack {
                InventoryListView(category: .pantry)
                    .navigationTitle("Pantry")
            }
            .tabItem {
                Label("Pantry", systemImage: "cabinet")
            }
            .tag(2)
            
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife")
                }
                .tag(3)
            
            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }
                .tag(4)
        }
    }
}
