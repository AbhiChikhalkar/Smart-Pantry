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
    @State private var isCooked = false
    @State private var selectedTab = 0 // 0 = Ingredients, 1 = Instructions
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                ZStack(alignment: .bottomLeading) {
                    if let imageURL = recipe.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            heroPlaceholder
                        }
                        .frame(height: 300)
                        .clipped()
                    } else {
                        heroPlaceholder
                    }
                    
                    // Gradient Overlay
                    LinearGradient(
                        colors: [.black.opacity(0.8), .transparent],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    .frame(height: 300)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text(recipe.recipeDescription.isEmpty ? "A delicious homemade meal." : recipe.recipeDescription)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    .padding()
                }
                
                VStack(spacing: 24) {
                    // Quick Stats & Nutrition
                    VStack(spacing: 16) {
                        // Prep Time & Difficulty
                        HStack(spacing: 24) {
                            Label("\(recipe.prepTime) min", systemImage: "clock")
                            Divider().frame(height: 20)
                            Label(recipe.difficulty, systemImage: "chart.bar")
                            Divider().frame(height: 20)
                            Label("1 Serving", systemImage: "person.2")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        // Nutrition Grid
                        if recipe.calories > 0 {
                            HStack(spacing: 0) {
                                NutritionItem(value: "\(recipe.calories)", unit: "kcal", label: "Calories")
                                NutritionItem(value: "\(recipe.protein)g", unit: "", label: "Protein")
                                NutritionItem(value: "\(recipe.carbs)g", unit: "", label: "Carbs")
                                NutritionItem(value: "\(recipe.fat)g", unit: "", label: "Fat")
                            }
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Segmented Control (Ingredients vs Instructions)
                    Picker("View", selection: $selectedTab) {
                        Text("Ingredients").tag(0)
                        Text("Instructions").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        if selectedTab == 0 {
                            // Ingredients List
                            ForEach(recipe.ingredients, id: \.self) { ingredient in
                                HStack(alignment: .top) {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.blue)
                                        .padding(.top, 4)
                                    Text(ingredient)
                                        .font(.body)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        } else {
                            // Instructions List
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 16) {
                                    Text("\(index + 1)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundStyle(.blue)
                                        .frame(width: 30)
                                    
                                    Text(step)
                                        .font(.body)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: cookRecipe) {
                            HStack {
                                Image(systemName: isCooked ? "checkmark.circle.fill" : "flame.fill")
                                Text(isCooked ? "Cooked!" : "Cook It Now")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isCooked ? Color.green : Color.blue)
                            .clipShape(Capsule())
                        }
                        .disabled(isCooked)
                        
                        if isNew && !isSaved {
                            Button(action: saveRecipe) {
                                Text("Save to Cookbook")
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isNew {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: toggleFavorite) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(.white) // Visible over hero image? No, toolbar is translucent.
                            // Needs handling for inline styling
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar) // Transparent nav bar
    }
    
    var heroPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 300)
            .overlay(
                Image(systemName: "frying.pan.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.gray)
            )
    }
    
    // MARK: - Actions
    
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
            
            // Simple string matching: check if ingredient contains item name
            for item in inventoryItems {
                if item.status == .available && ingredientLine.localizedCaseInsensitiveContains(item.name) {
                    matchedItem = item
                    break
                }
            }
            
            if let item = matchedItem {
                // Attempt to parse the quantity from the ingredient line (e.g. "200 ml Milk")
                // We pass the whole line to QuantityHelper, or split.
                // Assuming standard format "[qty] [unit] [name]" from AI, we splitting might be safer.
                let parts = ingredientLine.split(separator: " ")
                if parts.count >= 2 {
                    let qtyString = "\(parts[0]) \(parts[1])"
                    
                    if let newQuantity = QuantityHelper.shared.deduct(recipeQtyStr: qtyString, from: item.quantity) {
                        // Check if out of stock (starts with "0")
                        if newQuantity.hasPrefix("0") {
                            item.status = .consumed // Mark as consumed so it appears in suggestions
                            item.quantity = "0 \(parts[1])" // Placeholder
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

// MARK: - Subviews

struct NutritionItem: View {
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .bold()
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

extension Color {
    static let transparent = Color.black.opacity(0)
}
