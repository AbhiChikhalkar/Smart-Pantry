//
//  ContentView.swift
//  SmartPantry
//
//  Created by Abhishek Chikhalkar on 03/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
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

#Preview {
    ContentView()
}
