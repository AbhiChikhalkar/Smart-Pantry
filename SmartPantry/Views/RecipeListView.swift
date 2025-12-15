import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdDate, order: .reverse) private var savedRecipes: [Recipe]
    
    // Filter for available items only
    @Query(filter: #Predicate<Item> { item in
        item.statusRawValue == "available"
    }) private var availableItems: [Item]
    
    @State private var generatedRecipe: Recipe?
    @State private var recipeOptions: [RecipeOption]?
    @State private var isLoading = false
    @State private var showingGeneratedRecipe = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingOptionsSheet = false
    @State private var displayRecipes: [Recipe] = [] // For shuffled display
    @State private var lastShuffleTime = Date() // Force refresh
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Generator Button
                    Button(action: findRecipeOptions) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.title2)
                                .foregroundStyle(.white)
                            VStack(alignment: .leading) {
                                Text("Find me a Recipe")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                let expiringCount = availableItems.filter { isExpiringSoon($0.expiryDate) }.count
                                if expiringCount > 0 {
                                    Text("Prioritizing \(expiringCount) expiring items")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                        .bold()
                                } else {
                                    Text("Based on your \(availableItems.count) available items")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(16)
                    }
                    .disabled(isLoading || availableItems.isEmpty)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if savedRecipes.isEmpty {
                        ContentUnavailableView("No Saved Recipes", systemImage: "book.closed", description: Text("Generate recipes to save them here."))
                            .padding(.top, 40)
                    } else {
                        VStack(alignment: .leading) {
                            Text("Saved Recipes")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(displayRecipes) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe, isNew: false)) {
                                        RecipeCard(recipe: recipe)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(recipe)
                                            if let index = displayRecipes.firstIndex(of: recipe) {
                                                displayRecipes.remove(at: index)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Recipes")
            // Removed Main Shuffle Button as requested
            .onAppear {
                if displayRecipes.isEmpty || displayRecipes.count != savedRecipes.count {
                    displayRecipes = savedRecipes
                }
            }
            .onChange(of: savedRecipes) { oldValue, newValue in
                // Sync without losing implicit order if possible, but simplest is full reset
                displayRecipes = newValue
            }
            .navigationDestination(isPresented: $showingGeneratedRecipe) {
                if let recipe = generatedRecipe {
                    RecipeDetailView(recipe: recipe, isNew: true)
                }
            }
            .sheet(isPresented: $showingOptionsSheet) {
                NavigationStack {
                    List {
                        if let options = recipeOptions {
                            ForEach(options) { option in
                                Button(action: { selectOption(option) }) {
                                    VStack(alignment: .leading) {
                                        Text(option.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(option.description)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .navigationTitle("Choose a Meal")
                    .toolbar {
                         ToolbarItem(placement: .topBarTrailing) {
                             Button(action: findRecipeOptions) {
                                 Label("Shuffle", systemImage: "shuffle")
                             }
                             .disabled(isLoading)
                         }
                    }
                    .overlay {
                        if isLoading {
                            ProgressView("Cooking up details...")
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func shuffleRecipes() {
        withAnimation {
            displayRecipes.shuffle()
        }
    }
    
    private func isExpiringSoon(_ date: Date) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return days <= 3
    }
    
    private func findRecipeOptions() {
        guard !availableItems.isEmpty else { return }
        
        let expiringItems = availableItems.filter { isExpiringSoon($0.expiryDate) }
        let expiringNames = expiringItems.map { $0.name }
        
        print("Generating recipe with \(availableItems.count) items. Expiring: \(expiringNames)")
        
        let favorites = savedRecipes.filter { $0.isFavorite }.map { $0.title }
        
        isLoading = true
        let ingredientNames = availableItems.map { "\($0.quantity) \($0.name)" }
        
        Task {
            do {
                // Pass priority items AND favorites!
                let options = try await OpenRouterService.shared.generateRecipeOptions(
                    ingredients: ingredientNames,
                    priorityIngredients: expiringNames,
                    favoriteRecipes: favorites
                )
                
                await MainActor.run {
                    self.recipeOptions = options
                    self.isLoading = false
                    self.showingOptionsSheet = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to find ideas. Please try again."
                    self.isLoading = false
                    self.showingError = true
                }
            }
        }
    }
    
    private func selectOption(_ option: RecipeOption) {
        isLoading = true
        let ingredientNames = availableItems.map { "\($0.quantity) \($0.name)" }
        
        Task {
            do {
                let result = try await OpenRouterService.shared.generateFullRecipe(title: option.title, ingredients: ingredientNames)
                
                let newRecipe = Recipe(
                    title: result.title,
                    ingredients: result.ingredients,
                    steps: result.steps,
                    prepTime: result.prepTime,
                    difficulty: result.difficulty,
                    recipeDescription: result.description,
                    calories: result.calories,
                    protein: result.protein,
                    carbs: result.carbs,
                    fat: result.fat
                )
                
                await MainActor.run {
                    self.generatedRecipe = newRecipe
                    self.isLoading = false
                    self.showingOptionsSheet = false
                    // Delay slightly to allow sheet to close before pushing navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showingGeneratedRecipe = true
                        
                        // Save automatically or wait for user?
                        // User request didn't specify, currently the UI flow shows generative view first.
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate details. Please try again."
                    self.isLoading = false
                    self.showingError = true
                }
            }
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder Icon
            Image(systemName: "frying.pan.fill")
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 50, height: 50)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack {
                    Label("\(recipe.prepTime) m", systemImage: "clock")
                    Text("•")
                    Label(recipe.difficulty, systemImage: "chart.bar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if recipe.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
