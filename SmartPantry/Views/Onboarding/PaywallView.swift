import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "crown.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.yellow)
            
            Text("Upgrade to Premium")
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "barcode.viewfinder", text: "Unlimited Scans")
                FeatureRow(icon: "wand.and.stars", text: "AI Recipe Generation")
                FeatureRow(icon: "bell.badge", text: "Expiry Notifications")
            }
            .padding()
            
            Spacer()
            
            if let product = subscriptionManager.products.first {
                Text("1 Month Free Trial")
                    .font(.headline)
                    .foregroundStyle(.green)
                
                Text("Then \(product.displayPrice) / month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button(action: {
                    Task {
                        await subscriptionManager.purchase(product)
                    }
                }) {
                    Text("Start Free Trial")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Button("Restore Purchases") {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
                .font(.caption)
                .padding(.top)
            } else if let error = subscriptionManager.initializationError {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Retry Loading") {
                    Task {
                        await subscriptionManager.loadProducts()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                ProgressView()
                Text("Loading Subscription Options...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Auto-renews. Cancel anytime.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            // Developer Bypass (Visible for testing)
            Button("Simulate Purchase (Developer Bypass)") {
                Task {
                    // Force state update
                    subscriptionManager.isSubscribed = true
                }
            }
            .font(.caption)
            .foregroundStyle(.gray)
            .padding(.bottom, 5)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}
