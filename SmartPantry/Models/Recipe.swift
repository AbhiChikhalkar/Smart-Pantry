import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var title: String
    var ingredients: [String]
    var steps: [String]
    var prepTime: Int // in minutes
    var difficulty: String
    var isFavorite: Bool
    var createdDate: Date
    
    init(title: String, ingredients: [String], steps: [String], prepTime: Int, difficulty: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.title = title
        self.ingredients = ingredients
        self.steps = steps
        self.prepTime = prepTime
        self.difficulty = difficulty
        self.isFavorite = isFavorite
        self.createdDate = Date()
    }
}
