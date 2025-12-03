import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var inventoryItems: [Item]
    
    let recipe: Recipe
    let isNew: Bool
    
    @State private var isSaved = false
    @State private var showingCookAlert = false
    @State private var cookMessage = ""
    @State private var isCooked = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(recipe.title)
                    .font(.largeTitle)
                    .bold()
                
                HStack {
                    Label("\(recipe.prepTime) min", systemImage: "clock")
                    Spacer()
                    Label(recipe.difficulty, systemImage: "chart.bar")
                    Spacer()
                    Label("1 Person", systemImage: "person.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical)
                
                Divider()
                
                Text("Ingredients")
                    .font(.title2)
                    .bold()
                
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    Text("• \(ingredient)")
                }
                
                Divider()
                
                Text("Steps")
                    .font(.title2)
                    .bold()
                
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .bold()
                            .foregroundStyle(.secondary)
                        Text(step)
                    }
                }
                
                Spacer(minLength: 30)
                
                Button(action: cookRecipe) {
                    HStack {
                        Image(systemName: isCooked ? "checkmark.circle.fill" : "flame.fill")
                        Text(isCooked ? "Cooked!" : "Cooked It!")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCooked ? Color.green : Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isCooked)
                
                if isNew && !isSaved {
                    Button(action: saveRecipe) {
                        Text("Save Recipe")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isNew {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: toggleFavorite) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
    
    private func saveRecipe() {
        modelContext.insert(recipe)
        isSaved = true
    }
    
    private func toggleFavorite() {
        recipe.isFavorite.toggle()
    }
    
    private func cookRecipe() {
        var deductedCount = 0
        
        for ingredientLine in recipe.ingredients {
            var matchedItem: Item?
            
            for item in inventoryItems {
                if item.status == .available && ingredientLine.localizedCaseInsensitiveContains(item.name) {
                    matchedItem = item
                    break
                }
            }
            
            if let item = matchedItem {
                let parts = ingredientLine.split(separator: " ")
                if parts.count >= 2 {
                    let qtyString = "\(parts[0]) \(parts[1])"
                    
                    if let newQuantity = QuantityHelper.shared.deduct(recipeQtyStr: qtyString, from: item.quantity) {
                        // Check if out of stock (starts with "0")
                        if newQuantity.hasPrefix("0") {
                            item.quantity = "1 pcs" // Default for shopping list
                            item.status = .shoppingList
                            NotificationManager.shared.scheduleLowStockNotification(for: item)
                        } else {
                            item.quantity = newQuantity
                        }
                        deductedCount += 1
                    }
                }
            }
        }
        
        withAnimation {
            isCooked = true
        }
    }
}
