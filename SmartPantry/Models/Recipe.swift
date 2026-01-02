import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID = UUID()
    var title: String = ""
    var ingredients: [String] = []
    var steps: [String] = []
    var prepTime: Int = 0 // in minutes
    var difficulty: String = "Easy"
    var isFavorite: Bool = false
    var recipeDescription: String = ""
    var imageURL: URL?
    var calories: Int = 0
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    var createdDate: Date = Date()
    
    init(title: String, ingredients: [String], steps: [String], prepTime: Int, difficulty: String, isFavorite: Bool = false, recipeDescription: String = "", imageURL: URL? = nil, calories: Int = 0, protein: Int = 0, carbs: Int = 0, fat: Int = 0) {
        self.id = UUID()
        self.title = title
        self.ingredients = ingredients
        self.steps = steps
        self.prepTime = prepTime
        self.difficulty = difficulty
        self.isFavorite = isFavorite
        self.recipeDescription = recipeDescription
        self.imageURL = imageURL
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.createdDate = Date()
    }
}
