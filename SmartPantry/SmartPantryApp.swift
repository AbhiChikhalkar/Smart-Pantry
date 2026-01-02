//
//  SmartPantryApp.swift
//  SmartPantry
//
//  Created by Abhishek Chikhalkar on 03/12/25.
//

import SwiftUI
import SwiftData

@main
struct SmartPantryApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Pantry.self, // Register Pantry
            Item.self,
            Recipe.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                    ensureDefaultPantry()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Migration helper: Ensure one Pantry exists and assign orphan items to it
    @MainActor
    private func ensureDefaultPantry() {
        let context = sharedModelContainer.mainContext
        
        do {
            // Check if a pantry exists
            let descriptor = FetchDescriptor<Pantry>()
            let pantries = try context.fetch(descriptor)
            
            let mainPantry: Pantry
            
            if let existing = pantries.first {
                mainPantry = existing
            } else {
                // Create default
                print("Creating default Pantry...")
                let newPantry = Pantry()
                context.insert(newPantry)
                mainPantry = newPantry
                try? context.save()
            }
            
            // Check for orphan items (items with no pantry)
            // Note: In SwiftData, fetching with predicate for nil relationship can be tricky, 
            // so we'll fetch all and check locally for safety or use a simple predicate.
            let itemDescriptor = FetchDescriptor<Item>(predicate: #Predicate<Item> { $0.pantry == nil })
            let orphans = try context.fetch(itemDescriptor)
            
            if !orphans.isEmpty {
                print("Migrating \(orphans.count) orphan items to main Pantry...")
                for item in orphans {
                    item.pantry = mainPantry
                }
                try? context.save()
            }
            
        } catch {
            print("Migration error: \(error)")
        }
    }
}
