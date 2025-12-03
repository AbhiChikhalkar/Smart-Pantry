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
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case imageFrontUrl = "image_front_url"
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
