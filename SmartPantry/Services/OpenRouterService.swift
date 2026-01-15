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
    let description: String
    let ingredients: [String]
    let steps: [String]
    let prepTime: Int
    let difficulty: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
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
    private let apiKey = ""
    
    private init() {}
    
    // Step 1: Generate 3 Options
    func generateRecipeOptions(ingredients: [String], priorityIngredients: [String] = [], favoriteRecipes: [String] = []) async throws -> [RecipeOption] {
        let ingredientsList = ingredients.joined(separator: ", ")
        var prompt = "You are a helpful cooking assistant. Suggest 3 DISTINCT meal ideas using some or all of these ingredients: \(ingredientsList). You can assume basic pantry staples and they shuold be realistic."
        
        if !priorityIngredients.isEmpty {
            prompt += "\n\nCRITICAL: You MUST prioritize using these expiring ingredients: \(priorityIngredients.joined(separator: ", ")). Try to include them in the suggestions."
        }
        
        if !favoriteRecipes.isEmpty {
            prompt += "\n\nThe user loves these dishes: \(favoriteRecipes.joined(separator: ", ")). Try to suggest recipes with a similar style or flavor profile if possible."
        }
        
        prompt += """
        
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
        Create a full, detailed recipe for "\(title)" using these ingredients: \(ingredientsList).
        
        IMPORTANT:
        1. The recipe must be for **ONE PERSON** (single serving).
        2. List ingredients in this EXACT format: `[Quantity] [Unit] [Ingredient Name]` (e.g., "100 g Pasta", "1 pcs Egg", "200 ml Milk").
        3. Use metric units (g, ml, pcs) where possible.
        4. Include a short appetizing description.
        5. Estimate nutrition facts for one serving.
        
        Return ONLY valid JSON matching this structure, with no other text:
        {
            "title": "\(title)",
            "description": "A delicious and simple dish...",
            "ingredients": ["List of ingredients with quantities"],
            "steps": ["Step 1", "Step 2"],
            "prepTime": 20,
            "difficulty": "Easy",
            "calories": 500,
            "protein": 20,
            "carbs": 40,
            "fat": 15
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
