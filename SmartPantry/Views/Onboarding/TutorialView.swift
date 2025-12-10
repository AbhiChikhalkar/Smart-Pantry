import SwiftUI

struct TutorialView: View {
    @Binding var isCompleted: Bool
    
    var body: some View {
        TabView {
            TutorialPage(image: "barcode.viewfinder", title: "Scan & Track", description: "Scan barcodes to instantly add items to your Fridge or Pantry.")
            TutorialPage(image: "exclamationmark.triangle.fill", title: "Monitor Expiry", description: "Get notified before your food goes bad. No more waste!")
            TutorialPage(image: "wand.and.stars", title: "Smart Recipes", description: "Generate recipes based on what you have and what's expiring.")
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.green)
                
                Text("All Set!")
                    .font(.title)
                    .bold()
                
                Button(action: {
                    withAnimation {
                        isCompleted = true
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct TutorialPage: View {
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color.accentColor)
            
            Text(title)
                .font(.title)
                .bold()
            
            Text(description)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}
