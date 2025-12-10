import Foundation

struct OFFProductResponse: Codable {
    let product: OFFProduct?
    let status: Int
    let statusVerbose: String
    
    enum CodingKeys: String, CodingKey {
        case product
        case status
        case statusVerbose = "status_verbose"
    }
}

struct OFFProduct: Codable {
    let productName: String?
    let brands: String?
    let imageFrontUrl: String?
    let quantity: String?
    let categoriesTags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case imageFrontUrl = "image_front_url"
        case quantity
        case categoriesTags = "categories_tags"
    }
    
    // MARK: - Helpers
    
    // Internal granular category for precise expiry estimation
    enum ProductType {
        case meat, seafood, dairy, cheese, frozen, bakery, produce, beverage, pantry, unknown
        
        var category: Category {
            switch self {
            case .meat, .seafood, .dairy, .cheese, .frozen, .produce, .beverage:
                return .fridge // Most beverages (juice/milk) go in fridge, others can default there or logic refined
            case .bakery:
                return .pantry // Bread usually pantry, but depends. keeping pantry for now.
            case .pantry, .unknown:
                return .pantry
            }
        }
        
        var shieldLife: TimeInterval {
            // Seconds in a day = 86400
            let day: TimeInterval = 86400
            switch self {
            case .meat, .seafood: return 3 * day
            case .bakery: return 5 * day
            case .dairy: return 14 * day // 2 weeks
            case .produce: return 7 * day // 1 week
            case .cheese: return 21 * day // 3 weeks
            case .frozen: return 180 * day // 6 months
            case .beverage: return 30 * day // 1 month (juices etc)
            case .pantry: return 180 * day // 6 months
            case .unknown: return 180 * day
            }
        }
    }
    
    var determinedType: ProductType {
        // Check tags first
        if let tags = categoriesTags {
            let tagString = tags.joined(separator: " ").lowercased()
            
            if tagString.contains("frozen") || tagString.contains("ice-creams") { return .frozen }
            if tagString.contains("meats") || tagString.contains("poultry") || tagString.contains("beef") { return .meat }
            if tagString.contains("seafood") || tagString.contains("fishes") { return .seafood }
            if tagString.contains("cheeses") { return .cheese }
            if tagString.contains("dairies") || tagString.contains("milks") || tagString.contains("yogurts") { return .dairy }
            if tagString.contains("fruits") || tagString.contains("vegetables") || tagString.contains("salads") { return .produce }
            if tagString.contains("breads") || tagString.contains("bakery") { return .bakery }
            if tagString.contains("beverages") || tagString.contains("juices") { return .beverage }
            if tagString.contains("snacks") || tagString.contains("canned") || tagString.contains("pasta") { return .pantry }
        }
        
        // Fallback to Name
        if let name = productName?.lowercased() {
            if name.contains("ice cream") || name.contains("frozen") { return .frozen }
            if name.contains("chicken") || name.contains("beef") || name.contains("pork") || name.contains("steak") { return .meat }
            if name.contains("fish") || name.contains("salmon") || name.contains("tuna") || name.contains("shrimp") { return .seafood }
            if name.contains("cheese") || name.contains("cheddar") || name.contains("mozzarella") { return .cheese }
            if name.contains("milk") || name.contains("yogurt") || name.contains("cream") || name.contains("butter") { return .dairy }
            if name.contains("bread") || name.contains("bun") || name.contains("bagel") { return .bakery }
            if name.contains("juice") || name.contains("drink") || name.contains("soda") { return .beverage }
        }
        
        // Default
        return .pantry
    }
    
    var predictedCategory: Category {
        return determinedType.category
    }
    
    var estimatedExpiryDate: Date {
        let now = Date()
        return now.addingTimeInterval(determinedType.shieldLife)
    }
}

class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    
    private init() {}
    
    func fetchProduct(barcode: String) async throws -> OFFProduct? {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("SmartPantry/1.0 (indie.developer.project)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10 // 10 seconds timeout
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decodedResponse = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        
        if decodedResponse.status == 1 {
            return decodedResponse.product
        } else {
            return nil
        }
    }
}
