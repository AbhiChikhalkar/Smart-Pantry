import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: String = "1 pcs"
    var categoryRawValue: String = Category.fridge.rawValue
    var expiryDate: Date = Date()
    var addedDate: Date = Date()
    var barcode: String?
    var imageURL: URL?
    var brand: String?
    var statusRawValue: String = ItemStatus.available.rawValue
    
    // Relationship to parent Pantry
    var pantry: Pantry?
    
    var category: Category {
        get { Category(rawValue: categoryRawValue) ?? .fridge }
        set { categoryRawValue = newValue.rawValue }
    }
    
    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRawValue) ?? .available }
        set { statusRawValue = newValue.rawValue }
    }
    
    init(name: String, quantity: String, category: Category, expiryDate: Date, barcode: String? = nil, imageURL: URL? = nil, brand: String? = nil, status: ItemStatus = .available) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.categoryRawValue = category.rawValue
        self.expiryDate = expiryDate
        self.addedDate = Date()
        self.barcode = barcode
        self.imageURL = imageURL
        self.brand = brand
        self.statusRawValue = status.rawValue
    }
}

enum Category: String, CaseIterable, Codable {
    case fridge = "Fridge"
    case pantry = "Pantry"
}

enum ItemStatus: String, CaseIterable, Codable {
    case available
    case consumed
    case discarded
    case shoppingList
}
