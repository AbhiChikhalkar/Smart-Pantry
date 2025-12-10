import Foundation

struct OpenRouterMessage: Codable {
    let role: String
    let content: String
}

struct OpenRouterRequest: Codable {
    let model: String
    let messages: [OpenRouterMessage]
}

struct OpenRouterResponse: Codable {
    let choices: [OpenRouterChoice]
}

struct OpenRouterChoice: Codable {
    let message: OpenRouterMessage
}

// Helper struct to parse the JSON inside the text response
struct GeneratedRecipe: Codable {
    let title: String
    let ingredients: [String]
    let steps: [String]
    let prepTime: Int
    let difficulty: String
}

// Helper struct for Recipe Options
struct RecipeOption: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String
    let description: String
    
    private enum CodingKeys: String, CodingKey {
        case title, description
    }
}

struct RecipeOptionsResponse: Codable {
    let options: [RecipeOption]
}

class OpenRouterService {
    static let shared = OpenRouterService()
    
    // API Key provided by user
    private let apiKey = "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"
    
    private init() {}
    
    // Step 1: Generate 3 Options
    func generateRecipeOptions(ingredients: [String], priorityIngredients: [String] = [], favoriteRecipes: [String] = []) async throws -> [RecipeOption] {
        let ingredientsList = ingredients.joined(separator: ", ")
        var prompt = "You are a helpful cooking assistant. Suggest 3 DISTINCT meal ideas using some or all of these ingredients: \(ingredientsList)."
        
        if !priorityIngredients.isEmpty {
            prompt += "\n\nCRITICAL: You MUST prioritize using these expiring ingredients: \(priorityIngredients.joined(separator: ", ")). Try to include them in the suggestions."
        }
        
        if !favoriteRecipes.isEmpty {
            prompt += "\n\nThe user loves these dishes: \(favoriteRecipes.joined(separator: ", ")). Try to suggest recipes with a similar style or flavor profile if possible."
        }
        
        prompt += """
        \nYou can assume basic pantry staples.
        
        Return ONLY valid JSON matching this structure, with no other text:
        {
            "options": [
                { "title": "Recipe Title 1", "description": "Short description of the dish." },
                { "title": "Recipe Title 2", "description": "Short description of the dish." },
                { "title": "Recipe Title 3", "description": "Short description of the dish." }
            ]
        }
        """
        
        let jsonString = try await sendRequest(prompt: prompt)
        let response = try JSONDecoder().decode(RecipeOptionsResponse.self, from: jsonString.data(using: .utf8)!)
        return response.options
    }
    
    // Step 2: Generate Full Recipe
    func generateFullRecipe(title: String, ingredients: [String]) async throws -> GeneratedRecipe {
        let ingredientsList = ingredients.joined(separator: ", ")
        let prompt = """
        Create a full, easy recipe for "\(title)" using these ingredients: \(ingredientsList).
        
        IMPORTANT:
        1. The recipe must be for **ONE PERSON** (single serving).
        2. List ingredients in this EXACT format: `[Quantity] [Unit] [Ingredient Name]` (e.g., "100 g Pasta", "1 pcs Egg", "200 ml Milk").
        3. Use metric units (g, ml, pcs) where possible.
        
        Return ONLY valid JSON matching this structure, with no other text:
        {
            "title": "\(title)",
            "ingredients": ["List of ingredients with quantities"],
            "steps": ["Step 1", "Step 2"],
            "prepTime": 20,
            "difficulty": "Easy"
        }
        """
        
        let jsonString = try await sendRequest(prompt: prompt)
        return try JSONDecoder().decode(GeneratedRecipe.self, from: jsonString.data(using: .utf8)!)
    }
    
    // Helper to send request
    private func sendRequest(prompt: String) async throws -> String {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("https://smartpantry.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("SmartPantry", forHTTPHeaderField: "X-Title")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OpenRouterRequest(
            model: "anthropic/claude-3-haiku",
            messages: [OpenRouterMessage(role: "user", content: prompt)]
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                print("OpenRouter API Error: \(errorText)")
            }
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let jsonText = apiResponse.choices.first?.message.content else {
            throw URLError(.cannotParseResponse)
        }
        
        // Clean up JSON
        return jsonText.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
    }
}
