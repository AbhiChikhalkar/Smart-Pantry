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
                                Text("Based on your \(availableItems.count) available items")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
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
                        ForEach(savedRecipes) { recipe in
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
    
    private func findRecipeOptions() {
        guard !availableItems.isEmpty else { return }
        
        print("Generating recipe with \(availableItems.count) items:")
        for item in availableItems {
            print("- \(item.name) (\(item.statusRawValue))")
        }
        
        isLoading = true
        let ingredientNames = availableItems.map { "\($0.quantity) \($0.name)" }
        
        Task {
            do {
                let options = try await OpenRouterService.shared.generateRecipeOptions(ingredients: ingredientNames)
                
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
            for index in offsets {
                modelContext.delete(savedRecipes[index])
            }
        }
    }
}
