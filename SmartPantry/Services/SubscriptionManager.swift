import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var isSubscribed: Bool = false
    @Published var products: [Product] = []
    
    @Published var initializationError: String?

    private let productIds = ["com.smartpantry.premium.monthly"]
    private var updates: Task<Void, Never>?
    
    init() {
        print("SubscriptionManager: Initializing...")
        updates = Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await updateSubscriptionStatus()
                }
            }
        }
        
        Task {
            await updateSubscriptionStatus()
            await loadProducts()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    func loadProducts() async {
        print("SubscriptionManager: Loading products with IDs: \(productIds)")
        do {
            let products = try await Product.products(for: productIds)
            print("SubscriptionManager: Loaded products: \(products)")
            if products.isEmpty {
                print("SubscriptionManager: Warning - No products returned. Check StoreKit Configuration.")
                initializationError = "No products found. Enable StoreKit Config."
            }
            self.products = products
        } catch {
            print("SubscriptionManager: Failed to load products: \(error)")
            initializationError = error.localizedDescription
        }
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("Purchase successful and verified")
                    await transaction.finish()
                    await updateSubscriptionStatus()
                case .unverified:
                    print("Transaction unverified")
                }
            case .userCancelled:
                print("User cancelled")
            case .pending:
                print("Purchase pending")
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    func updateSubscriptionStatus() async {
        print("Checking subscription status...")
        var hasActiveSubscription = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("Found verified transaction: \(transaction.productID), expires: \(String(describing: transaction.expirationDate))")
                if transaction.expirationDate == nil || transaction.expirationDate! > Date() {
                    hasActiveSubscription = true
                    print("Active subscription confirmed!")
                } else {
                    print("Subscription expired.")
                }
            } else {
                print("Found unverified transaction.")
            }
        }
        self.isSubscribed = hasActiveSubscription
        print("Final isSubscribed status: \(self.isSubscribed)")
    }
}
