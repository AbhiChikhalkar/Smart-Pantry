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
            List {
                Section {
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
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading || availableItems.isEmpty)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                if savedRecipes.isEmpty {
                    ContentUnavailableView("No Saved Recipes", systemImage: "book.closed", description: Text("Generate recipes to save them here."))
                } else {
                    Section("Saved Recipes") {
                        ForEach(displayRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe, isNew: false)) {
                                VStack(alignment: .leading) {
                                    Text(recipe.title)
                                        .font(.headline)
                                    HStack {
                                        Label("\(recipe.prepTime) min", systemImage: "clock")
                                        Spacer()
                                        if recipe.isFavorite {
                                            Image(systemName: "heart.fill")
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteRecipes)
                    }
                }
            }
            .navigationTitle("Recipes")
            // Removed Main Shuffle Button as requested
            .onAppear {
                if displayRecipes.isEmpty || displayRecipes.count != savedRecipes.count {
                    displayRecipes = savedRecipes
                }
            }
            .onChange(of: savedRecipes) { oldValue, newValue in
                // Keep synced if not explicitly shuffled recently, or just blindly sync?
                // User might have deleted something, so we must sync.
                // But we want to preserve shuffle if possible?
                // Simplest: Reset on change to ensure consistency
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
                    difficulty: result.difficulty
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
    
    private func deleteRecipes(offsets: IndexSet) {
        withAnimation {
            // Need to map offsets from displayRecipes back to savedRecipes if we want to delete?
            // BUT savedRecipes is a Query, we can only delete the Model objects.
            // Since displayRecipes contains the actual Recipe objects, we can delete them.
            
            for index in offsets {
                let recipeToDelete = displayRecipes[index]
                modelContext.delete(recipeToDelete)
            }
            
            // Remove from display as well
            displayRecipes.remove(atOffsets: offsets)
        }
    }
}
